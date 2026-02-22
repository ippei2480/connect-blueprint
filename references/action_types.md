# Connect Blueprint — Action Types リファレンス

## MessageParticipant

テキストまたはSSMLを再生する。

```json
{
  "Identifier": "uuid",
  "Type": "MessageParticipant",
  "Parameters": {
    "Text": "お電話ありがとうございます"
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

**Parameters:**
- `Text` (string) — 再生するテキスト。SSML可（`<speak>...</speak>`）
- `SSML` (string) — SSMLを直接指定する場合

---

## GetParticipantInput

DTMF入力を取得する（IVRメニュー）。

```json
{
  "Identifier": "uuid",
  "Type": "GetParticipantInput",
  "Parameters": {
    "Text": "1を押してください",
    "DTMFConfiguration": {
      "InputTimeLimitSeconds": "8",
      "FinishOnKey": "#",
      "InactivityTimeLimitSeconds": "5"
    },
    "InputTimeLimitSeconds": "8"
  },
  "Transitions": {
    "NextAction": "timeout-uuid",
    "Conditions": [
      {
        "NextAction": "pressed1-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["1"]
        }
      }
    ],
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingCondition" },
      { "NextAction": "error-uuid", "ErrorType": "InputTimeLimitExceeded" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

**Parameters:**
- `Text` — プロンプトテキスト
- `DTMFConfiguration.InputTimeLimitSeconds` — 入力待ちタイムアウト（秒）
- `DTMFConfiguration.FinishOnKey` — 入力完了キー（通常 `#`）
- `InputTimeLimitSeconds` — 全体タイムアウト

**Conditions:**
- `Operator`: `Equals`
- `Operands`: DTMF値の配列（例: `["1"]`）

---

## UpdateContactTargetQueue

転送先キューを設定する。

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactTargetQueue",
  "Parameters": {
    "QueueId": "arn:aws:connect:region:account:instance/xxx/queue/yyy"
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

**Parameters:**
- `QueueId` — キューのARN

---

## TransferContactToQueue

設定済みキューへ転送を実行する。

```json
{
  "Identifier": "uuid",
  "Type": "TransferContactToQueue",
  "Parameters": {},
  "Transitions": {
    "NextAction": "after-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "QueueAtCapacity" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## DisconnectParticipant

通話を切断する。

```json
{
  "Identifier": "uuid",
  "Type": "DisconnectParticipant",
  "Parameters": {},
  "Transitions": {}
}
```

---

## InvokeLambdaFunction

Lambda関数を呼び出す。

```json
{
  "Identifier": "uuid",
  "Type": "InvokeLambdaFunction",
  "Parameters": {
    "LambdaFunctionARN": "arn:aws:lambda:region:account:function:name",
    "InvocationTimeLimitSeconds": "8",
    "LambdaInvocationAttributes": {
      "key": "value"
    }
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

**Parameters:**
- `LambdaFunctionARN` — Lambda関数のARN
- `InvocationTimeLimitSeconds` — タイムアウト（秒）
- `LambdaInvocationAttributes` — Lambda に渡すキーバリュー

---

## UpdateContactAttributes

コンタクト属性を設定する。

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactAttributes",
  "Parameters": {
    "Attributes": {
      "key": "value"
    }
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## Compare

属性値を比較して分岐する。

```json
{
  "Identifier": "uuid",
  "Type": "Compare",
  "Parameters": {
    "ComparisonValue": "$.Attributes.key"
  },
  "Transitions": {
    "NextAction": "default-uuid",
    "Conditions": [
      {
        "NextAction": "match-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["expected_value"]
        }
      }
    ],
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingCondition" }
    ]
  }
}
```

---

## InvokeFlowModule

フローモジュールを呼び出す。

```json
{
  "Identifier": "uuid",
  "Type": "InvokeFlowModule",
  "Parameters": {
    "FlowModuleId": "arn:aws:connect:region:account:instance/xxx/flow-module/yyy"
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## CheckHoursOfOperation

営業時間をチェックして分岐する。

```json
{
  "Identifier": "uuid",
  "Type": "CheckHoursOfOperation",
  "Parameters": {},
  "Transitions": {
    "NextAction": "default-uuid",
    "Conditions": [
      {
        "NextAction": "in-hours-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["True"]
        }
      },
      {
        "NextAction": "out-hours-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["False"]
        }
      }
    ],
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```
