# Connect Blueprint — レイアウトルール

## 座標系

- X軸: 左→右（フローの進行方向）
- Y軸: 上→下（分岐の展開方向）

## 定数

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `X_BASE` | 200 | 開始X座標 |
| `X_STEP` | 320 | ノード間の水平距離 |
| `Y_BASE` | 300 | 開始Y座標 |
| `Y_STEP` | 280 | 分岐間の垂直距離 |

## レイアウトアルゴリズム

1. **DFS** でバックエッジ（ループ）を検出し、DAGに変換
2. **BFS** で各ノードの深さ（depth）を計算 → X座標に使用
3. 親ノードからの遷移タイプでY座標を決定：
   - `NextAction`（デフォルト遷移）: 親と同じY
   - `Conditions[i]`: 親Y + (i+1) × Y_STEP（下方向）
   - `Errors[j]`: 親Y + (条件数 + j + 1) × Y_STEP（さらに下）

## 座標の配置先

```json
{
  "Metadata": {
    "ActionMetadata": {
      "<Identifier>": {
        "position": { "x": 520, "y": 300 }
      }
    }
  }
}
```

⚠️ Action オブジェクト直下に `Metadata` を入れると Connect API がエラーを返す。
必ずトップレベルの `Metadata.ActionMetadata` に配置すること。

## scripts/layout.py の使い方

```bash
python3 scripts/layout.py flow.json
```

- 入力ファイルを読み込み、座標を計算して上書き保存する
- Action直下の `Metadata` フィールドがあれば自動削除する
