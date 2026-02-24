# Connect Blueprint — Action Types リファレンス

## 共通ルール

### Transitions 構造

すべての Action は `Transitions` オブジェクトを持つ（`DisconnectParticipant` は空 `{}` でOK）。

| フィールド | 役割 |
|-----------|------|
| `NextAction` | デフォルト遷移先（タイムアウト時・正常完了時） |
| `Conditions` | 条件分岐（DTMF値、属性比較、ループ状態など） |
| `Errors` | エラー発生時の遷移先 |

### Conditions が必要な ActionType

以下の ActionType は `Conditions` を設定しないと分岐が機能しない：

| ActionType | 必須 Conditions | 備考 |
|-----------|----------------|------|
| `GetParticipantInput` (StoreInput=False) | DTMF値ごとの `Equals` | IVRメニューモード |
| `Compare` | 最低1つの `Equals` 条件 | 属性値の比較分岐 |
| `CheckHoursOfOperation` | `True` + `False` の両方 | 営業時間内外の分岐 |
| `Loop` | `ContinueLooping` + `DoneLooping` の両方 | ループ継続・終了の分岐 |

上記以外の ActionType は `Conditions` 非対応。設定しても無視されるか、予期しない動作の原因となる。

### Errors 共通ルール

- `DisconnectParticipant`、`UpdateFlowLoggingBehavior`、`UpdateContactRecordingBehavior` 以外は `Errors` 必須
- `NoMatchingError` はキャッチオールとして常に含める

### パラメータ値の型

すべてのパラメータ値は **文字列型** で指定する（数値・真偽値も文字列）：
- 数値: `"8"`, `"3"`, `"5"`
- 真偽値: `"True"`, `"False"`
- 列挙値: `"Enabled"`, `"Disabled"`, `"Standard"`, `"Neural"`

---

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

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

---

## GetParticipantInput

DTMF入力を取得する（IVRメニュー）。

**IVRメニューモード（StoreInput=False または未指定）:**

```json
{
  "Identifier": "uuid",
  "Type": "GetParticipantInput",
  "Parameters": {
    "Text": "1を押してください",
    "DTMFConfiguration": {
      "InputTerminationSequence": "#",
      "InterdigitTimeLimitSeconds": "5",
      "DisableCancelKey": "False"
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

**自由入力モード（StoreInput=True）:**

```json
{
  "Identifier": "uuid",
  "Type": "GetParticipantInput",
  "Parameters": {
    "Text": "お客様番号を4桁で入力し、最後にシャープを押してください。",
    "StoreInput": "True",
    "InputTimeLimitSeconds": "10",
    "InputValidation": {
      "CustomValidation": {
        "MaximumLength": "4"
      }
    }
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ],
    "Conditions": []
  }
}
```

**Parameters:**
- `Text` — プロンプトテキスト
- `DTMFConfiguration.InputTerminationSequence` — 入力完了キー（通常 `"#"`）
- `DTMFConfiguration.InterdigitTimeLimitSeconds` — 桁間タイムアウト（秒）
- `DTMFConfiguration.DisableCancelKey` — キャンセルキー（*）無効化（`"True"` / `"False"`）
- `InputTimeLimitSeconds` — 全体タイムアウト（**Parameters直下に配置**、DTMFConfiguration内には置かない）
- `StoreInput` — 入力値を `$.StoredCustomerInput` に保存（`"True"` / `"False"`）
- `InputValidation` — StoreInput=True 時に必須。入力値のバリデーション設定

**InputValidation 構造:**
```json
"InputValidation": {
  "CustomValidation": {
    "MaximumLength": "4"
  }
}
```

**StoreInput による動作の違い:**
- `StoreInput: "True"` → Conditions使用不可（空配列 `[]`）。`InputValidation` 必須。入力値は `$.StoredCustomerInput` に格納される。Errors は `NoMatchingError` のみ
- `StoreInput: "False"` or 未指定 → Conditions使用可（通常のIVRメニューモード）。`DTMFConfiguration` で入力設定

**Conditions:**
- `Operator`: `Equals`
- `Operands`: DTMF値の配列（例: `["1"]`）

**Transitions（StoreInput=False または未指定時）:**
- `NextAction`: o（タイムアウト時のデフォルト遷移先）
- `Conditions`: o (`Equals`)
- `Errors`: o (`NoMatchingCondition`, `InputTimeLimitExceeded`, `NoMatchingError`)

**Transitions（StoreInput=True 時）:**
- `NextAction`: o
- `Conditions`: - （空配列 `[]`）
- `Errors`: o (`NoMatchingError`)

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

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

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

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`QueueAtCapacity`, `NoMatchingError`)

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

**Transitions:**
- `NextAction`: -
- `Conditions`: -
- `Errors`: -

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

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

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

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

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

**Transitions:**
- `NextAction`: o（デフォルト遷移先）
- `Conditions`: o (`Equals`)
- `Errors`: o (`NoMatchingCondition`)

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

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

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

**Parameters:**
- `HoursOfOperationId` (string, optional) — 指定しない場合はキューに設定された営業時間を使用

**Transitions:**
- `NextAction`: o（デフォルト遷移先）
- `Conditions`: o (`Equals`: `"True"` / `"False"`)
- `Errors`: o (`NoMatchingError`)

---

## Loop

ループ処理を行う。指定回数までContinueLooping、超過するとDoneLooping条件に遷移する。

```json
{
  "Identifier": "uuid",
  "Type": "Loop",
  "Parameters": {
    "LoopCount": "3"
  },
  "Transitions": {
    "NextAction": "done-uuid",
    "Conditions": [
      {
        "NextAction": "continue-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["ContinueLooping"]
        }
      },
      {
        "NextAction": "done-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["DoneLooping"]
        }
      }
    ]
  }
}
```

**Parameters:**
- `LoopCount` (string) — ループ回数（例: `"3"`）

**Transitions:**
- `NextAction`: o（デフォルト遷移先）
- `Conditions`: o **必須**（`ContinueLooping` + `DoneLooping` の両方が必要）
- `Errors`: -

---

## UpdateContactRecordingBehavior

通話録音の開始/停止を制御する。

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactRecordingBehavior",
  "Parameters": {
    "RecordingBehavior": {
      "RecordedParticipants": ["Agent", "Customer"]
    }
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [],
    "Conditions": []
  }
}
```

**Parameters:**
- `RecordingBehavior.RecordedParticipants` — 録音対象（`["Agent"]`, `["Customer"]`, `["Agent", "Customer"]`）
- 録音停止は `"RecordedParticipants": []` を指定
- `AnalyticsBehavior` (optional) — Contact Lens リアルタイム分析設定
  - `Enabled`: `"True"` / `"False"`
  - `AnalyticsLanguage`: 分析言語（`"ja-JP"`, `"en-US"` 等）
  - `AnalyticsRedactionBehavior`: 機密情報マスキング（`"Enabled"` / `"Disabled"`）
  - `AnalyticsRedactionResults`: マスキング後の出力（`"RedactedAndOriginal"` 等）
- `IVRRecordingBehavior` (optional) — IVR録音設定
  - `RecordedParticipants`: IVR録音対象
- `ScreenRecordedParticipants` (optional) — 画面録画対象

**Contact Lens 分析付きの例:**

```json
{
  "Type": "UpdateContactRecordingBehavior",
  "Parameters": {
    "RecordingBehavior": {
      "RecordedParticipants": ["Agent", "Customer"]
    },
    "AnalyticsBehavior": {
      "Enabled": "True",
      "AnalyticsLanguage": "ja-JP",
      "AnalyticsRedactionBehavior": "Disabled",
      "AnalyticsRedactionResults": "RedactedAndOriginal"
    }
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [],
    "Conditions": []
  }
}
```

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: -

---

## UpdateContactRecordingAndAnalyticsBehavior

録音とアナリティクスを統合制御する（`UpdateContactRecordingBehavior` の後継）。
録音設定とContact Lens分析設定を1つのアクションで同時に制御する場合に使用する。

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactRecordingAndAnalyticsBehavior",
  "Parameters": {
    "RecordingBehavior": {
      "RecordedParticipants": ["Agent", "Customer"]
    },
    "AnalyticsBehavior": {
      "Enabled": "True",
      "AnalyticsLanguage": "ja-JP",
      "AnalyticsRedactionBehavior": "Disabled",
      "AnalyticsRedactionResults": "RedactedAndOriginal"
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
- `RecordingBehavior.RecordedParticipants` — 録音対象（`UpdateContactRecordingBehavior` と同じ）
- `AnalyticsBehavior` — Contact Lens 分析設定（`UpdateContactRecordingBehavior` の `AnalyticsBehavior` と同じ）

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

---

## UpdateContactTextToSpeechVoice

テキスト読み上げの音声を設定する。

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactTextToSpeechVoice",
  "Parameters": {
    "TextToSpeechVoice": "Mizuki",
    "TextToSpeechEngine": "Standard",
    "TextToSpeechStyle": "None"
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
- `TextToSpeechVoice` — Amazon Polly の音声名（日本語: `Mizuki`, `Takumi`、英語: `Joanna`, `Matthew` 等）
- `TextToSpeechEngine` — 音声エンジン（`"Standard"` / `"Neural"`）
- `TextToSpeechStyle` — 音声スタイル（`"None"` 等）

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`NoMatchingError`)

---

## UpdateFlowLoggingBehavior

コンタクトフローのログ出力を有効/無効にする。

```json
{
  "Identifier": "uuid",
  "Type": "UpdateFlowLoggingBehavior",
  "Parameters": {
    "FlowLoggingBehavior": "Enabled"
  },
  "Transitions": {
    "NextAction": "next-uuid"
  }
}
```

**Parameters:**
- `FlowLoggingBehavior` — `"Enabled"` or `"Disabled"`

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: -

---

## TransferToPhoneNumber

外部電話番号に転送する。

```json
{
  "Identifier": "uuid",
  "Type": "TransferToPhoneNumber",
  "Parameters": {
    "PhoneNumber": "+81312345678",
    "ContactFlowId": "optional-whisper-flow-arn"
  },
  "Transitions": {
    "NextAction": "after-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "CallFailed" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

**Parameters:**
- `PhoneNumber` — E.164形式の電話番号
- `ContactFlowId` (optional) — ウィスパーフローのARN

**Transitions:**
- `NextAction`: o
- `Conditions`: -
- `Errors`: o (`CallFailed`, `NoMatchingError`)
