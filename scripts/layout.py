#!/usr/bin/env python3
"""
layout.py — Amazon Connect フローJSONにposition座標を付与する。

Usage:
    python3 layout.py <flow.json>

flow.json を読み込み、各ActionにBFSベースのレイアウト座標を計算して
Metadata.ActionMetadata.<id>.position に書き込む（上書き保存）。
"""

import json, sys
from collections import deque


def get_edges(action):
    """遷移先を (nid, edge_type, edge_idx) で返す"""
    t = action.get('Transitions', {})
    edges = []
    if t.get('NextAction'):
        edges.append((t['NextAction'], 'next', 0))
    for i, c in enumerate(t.get('Conditions', [])):
        if c.get('NextAction'):
            edges.append((c['NextAction'], 'condition', i))
    for j, e in enumerate(t.get('Errors', [])):
        if e.get('NextAction'):
            edges.append((e['NextAction'], 'error', j))
    seen = set()
    result = []
    for nid, etype, eidx in edges:
        if nid not in seen:
            seen.add(nid)
            result.append((nid, etype, eidx))
    return result


def get_all_next(action, id_to_action):
    return [nid for nid, _, _ in get_edges(action) if nid in id_to_action]


def resolve_overlaps(positions):
    """
    ブロックの重なりを解消する。
    同じx座標に複数ノードがある場合、y方向に十分な間隔を確保する。
    異なるx座標間でも重なりが発生する場合はy方向にずらす。
    """
    BLOCK_WIDTH = 210
    BLOCK_HEIGHT = 160
    MARGIN_X = 20
    MARGIN_Y = 20
    MIN_X_SPACING = BLOCK_WIDTH + MARGIN_X   # 230
    MIN_Y_SPACING = BLOCK_HEIGHT + MARGIN_Y  # 180

    changed = True
    max_iter = 200
    iteration = 0

    while changed and iteration < max_iter:
        changed = False
        iteration += 1

        node_ids = list(positions.keys())
        for i in range(len(node_ids)):
            for j in range(i + 1, len(node_ids)):
                id1, id2 = node_ids[i], node_ids[j]
                pos1, pos2 = positions[id1], positions[id2]

                dx = abs(pos1['x'] - pos2['x'])
                dy = abs(pos1['y'] - pos2['y'])

                # 重なり判定
                if dx < MIN_X_SPACING and dy < MIN_Y_SPACING:
                    # 重なっている → y方向にずらす（y が大きい方をさらに下へ）
                    if pos2['y'] >= pos1['y']:
                        needed = MIN_Y_SPACING - dy
                        positions[id2]['y'] += needed
                    else:
                        needed = MIN_Y_SPACING - dy
                        positions[id1]['y'] += needed
                    changed = True

    return positions


def layout(flow):
    actions = flow['Actions']
    id_to_action = {a['Identifier']: a for a in actions}
    entry_id = flow.get('StartAction')

    # DFS でバックエッジ検出
    sys.setrecursionlimit(1000)
    visited, in_stack, back_edges = set(), set(), set()

    def dfs(node):
        visited.add(node); in_stack.add(node)
        for nid in get_all_next(id_to_action.get(node, {}), id_to_action):
            if nid not in visited:
                dfs(nid)
            elif nid in in_stack:
                back_edges.add((node, nid))
        in_stack.discard(node)

    dfs(entry_id)

    def get_edges_dag(action):
        aid = action['Identifier']
        return [(nid, et, ei) for nid, et, ei in get_edges(action)
                if (aid, nid) not in back_edges and nid in id_to_action]

    # BFS で最大深さ計算
    depth = {entry_id: 0}
    queue = deque([(entry_id, 0)])
    while queue:
        node, d = queue.popleft()
        for nid, _, _ in get_edges_dag(id_to_action.get(node, {})):
            if depth.get(nid, -1) < d + 1:
                depth[nid] = d + 1
                queue.append((nid, d + 1))

    for a in actions:
        if a['Identifier'] not in depth:
            depth[a['Identifier']] = 0

    # 親情報を記録
    parent_info = {}
    for a in actions:
        num_cond = len([c for c in a.get('Transitions', {}).get('Conditions', []) if c.get('NextAction')])
        for nid, etype, eidx in get_edges_dag(a):
            if nid not in parent_info:
                parent_info[nid] = (a['Identifier'], etype, eidx, num_cond)

    # Y座標計算
    X_BASE, X_STEP = 200, 320
    Y_BASE, Y_STEP = 300, 200

    node_y = {entry_id: Y_BASE}
    sorted_actions = sorted(actions, key=lambda a: depth.get(a['Identifier'], 0))

    for a in sorted_actions:
        aid = a['Identifier']
        if aid == entry_id:
            continue
        if aid not in parent_info:
            node_y[aid] = Y_BASE
            continue

        parent_id, etype, eidx, num_cond = parent_info[aid]
        parent_y = node_y.get(parent_id, Y_BASE)

        if etype == 'next':
            node_y[aid] = parent_y
        elif etype == 'condition':
            node_y[aid] = parent_y + (eidx + 1) * Y_STEP
        elif etype == 'error':
            node_y[aid] = parent_y + (num_cond + eidx + 1) * Y_STEP

    # 座標確定
    positions = {}
    for a in actions:
        aid = a['Identifier']
        positions[aid] = {
            'x': X_BASE + depth.get(aid, 0) * X_STEP,
            'y': node_y.get(aid, Y_BASE)
        }

    # 重なり解消
    positions = resolve_overlaps(positions)

    if 'Metadata' not in flow:
        flow['Metadata'] = {}
    if 'ActionMetadata' not in flow['Metadata']:
        flow['Metadata']['ActionMetadata'] = {}

    for a in actions:
        aid = a['Identifier']
        if aid not in flow['Metadata']['ActionMetadata']:
            flow['Metadata']['ActionMetadata'][aid] = {}
        flow['Metadata']['ActionMetadata'][aid]['position'] = positions[aid]
        if 'Metadata' in a:
            del a['Metadata']

    return flow


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 layout.py <flow.json>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    with open(path) as f:
        flow = json.load(f)

    flow = layout(flow)

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(flow, f, ensure_ascii=False, indent=2)

    print(f"✅ {len(flow['Actions'])} actions に座標を付与しました → {path}")
