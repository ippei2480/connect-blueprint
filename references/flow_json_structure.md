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

## ActionType別 Transitions 仕様

各ActionTypeで使用できる Transitions のフィールド:

| ActionType | NextAction | Conditions | Errors |
|-----------|:---:|:---:|:---:|
| MessageParticipant | o | - | o (NoMatchingError) |
| GetParticipantInput (StoreInput=False) | o | o (Equals) | o (InputTimeLimitExceeded, NoMatchingCondition, NoMatchingError) |
| GetParticipantInput (StoreInput=True) | o | - | o (NoMatchingError) |
| UpdateContactTargetQueue | o | - | o (NoMatchingError) |
| TransferContactToQueue | o | - | o (QueueAtCapacity, NoMatchingError) |
| DisconnectParticipant | - | - | - |
| InvokeLambdaFunction | o | - | o (NoMatchingError) |
| UpdateContactAttributes | o | - | o (NoMatchingError) |
| Compare | o | o (Equals) | o (NoMatchingCondition) |
| InvokeFlowModule | o | - | o (NoMatchingError) |
| CheckHoursOfOperation | o | o (Equals: True/False) | o (NoMatchingError) |
| Loop | o | o (ContinueLooping/DoneLooping) **必須** | - |
| UpdateContactRecordingBehavior | o | - | - |
| UpdateContactRecordingAndAnalyticsBehavior | o | - | o (NoMatchingError) |
| UpdateContactTextToSpeechVoice | o | - | o (NoMatchingError) |
| UpdateFlowLoggingBehavior | o | - | - |
| TransferToPhoneNumber | o | - | o (CallFailed, NoMatchingError) |

- `o` = 使用可 / `-` = 使用不可・不要

### Conditions 必須ルール

| ActionType | 必須 Conditions | 備考 |
|-----------|----------------|------|
| `Loop` | `ContinueLooping` + `DoneLooping` の両方 | 片方でも欠けるとループ制御が機能しない |
| `CheckHoursOfOperation` | `True` + `False` の両方 | 営業時間内外の両分岐が必要 |
| `Compare` | 最低1つの `Equals` 条件 | 条件なしでは分岐が機能しない |

### Conditions 使用不可ケース

- `GetParticipantInput` + `StoreInput: "True"` — 入力値は `$.StoredCustomerInput` に格納されるため、Conditions による分岐は行わない。Conditions が設定されている場合は排他制約違反。

### Errors 必須ルール

- `DisconnectParticipant`、`UpdateFlowLoggingBehavior`、`UpdateContactRecordingBehavior` 以外のすべての ActionType で `Errors` 配列が必須
- 最低限 `NoMatchingError` をキャッチオールとして含める

## バリデーションルール

1. `StartAction` で指定されたIDが `Actions` 配列内に存在すること
2. すべての `Identifier` が UUID v4 形式であること
3. すべての遷移先IDが `Actions` 配列内に存在すること
4. `DisconnectParticipant` 以外のActionには有効な `Transitions` が必要
5. `Version` は `"2019-10-30"` 固定
6. `Loop` に `ContinueLooping` と `DoneLooping` の両方の Conditions が存在すること
7. `CheckHoursOfOperation` に `True` と `False` の両方の Conditions が存在すること
8. `Compare` に最低1つの Conditions が存在すること
9. `GetParticipantInput` + `StoreInput: "True"` に Conditions が設定されていないこと
10. Conditions 非対応の ActionType に Conditions が設定されていないこと
