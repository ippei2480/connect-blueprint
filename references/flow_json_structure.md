# Connect Blueprint — フローJSON構造仕様

## トップレベル構造

```json
{
  "Version": "2019-10-30",
  "StartAction": "entry-action-uuid",
  "Actions": [ ... ],
  "Metadata": {
    "ActionMetadata": { ... }
  }
}
```

### フィールド

| フィールド | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `Version` | string | ✅ | 固定値 `"2019-10-30"` |
| `StartAction` | string | ✅ | エントリーポイントとなるActionのIdentifier（UUID v4） |
| `Actions` | array | ✅ | Actionオブジェクトの配列 |
| `Metadata` | object | ✅ | ActionMetadataを含むメタデータ |

## Action オブジェクト

```json
{
  "Identifier": "550e8400-e29b-41d4-a716-446655440000",
  "Type": "MessageParticipant",
  "Parameters": { ... },
  "Transitions": {
    "NextAction": "next-uuid",
    "Conditions": [ ... ],
    "Errors": [ ... ]
  }
}
```

### フィールド

| フィールド | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `Identifier` | string | ✅ | UUID v4 形式の一意識別子 |
| `Type` | string | ✅ | ActionType（`references/action_types.md` 参照） |
| `Parameters` | object | ✅ | ActionType固有のパラメータ |
| `Transitions` | object | ✅ | 遷移先の定義（`DisconnectParticipant` は `{}` でOK） |

## Transitions

```json
{
  "NextAction": "uuid",
  "Conditions": [
    {
      "NextAction": "uuid",
      "Condition": {
        "Operator": "Equals",
        "Operands": ["1"]
      }
    }
  ],
  "Errors": [
    {
      "NextAction": "uuid",
      "ErrorType": "NoMatchingError"
    }
  ]
}
```

- `NextAction` — デフォルト遷移先（タイムアウト時など）
- `Conditions` — 条件分岐（DTMF値、属性比較など）
- `Errors` — エラー遷移（`NoMatchingError`, `NoMatchingCondition`, `QueueAtCapacity` 等）

## Metadata

```json
{
  "Metadata": {
    "ActionMetadata": {
      "action-uuid": {
        "position": { "x": 200, "y": 300 }
      }
    }
  }
}
```

⚠️ **重要**: `position` は必ず `Metadata.ActionMetadata.<id>.position` に配置する。
Action オブジェクト直下の `Metadata` は Connect API が拒否する。

## バリデーションルール

1. `StartAction` で指定されたIDが `Actions` 配列内に存在すること
2. すべての `Identifier` が UUID v4 形式であること
3. すべての遷移先IDが `Actions` 配列内に存在すること
4. `DisconnectParticipant` 以外のActionには有効な `Transitions` が必要
5. `Version` は `"2019-10-30"` 固定
