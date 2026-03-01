# Settings — 設定系ブロック

> Source: AWS 公式ドキュメント (https://docs.aws.amazon.com/connect/latest/adminguide/)
> Generated: 2026-03-01

---

## Set logging behavior / `UpdateFlowLoggingBehavior`

- Docs: `set-logging-behavior.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `FlowLoggingBehavior` | String (`"Enabled"` \| `"Disabled"`) | ○ | フローログの有効/無効を設定。動的値は不可（静的設定のみ） |

フローログは CloudWatch Logs グループに保存される。有効にするとコンタクトセグメントの残り全体に適用され、チェーン内の新しいセグメントにも自動的に継承される。

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: なし（エラーブランチなし）

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateFlowLoggingBehavior",
  "Parameters": {
    "FlowLoggingBehavior": "Enabled"
  },
  "Transitions": {
    "NextAction": "next-action-id"
  }
}
```

### 利用可能フロータイプ

すべてのフロータイプで利用可能。

---

## Set recording and analytics behavior / `UpdateContactRecordingBehavior`

- Docs: `set-recording-behavior.html`
- Channels: Voice ○ / Chat ○ / Task × / Email ×

> **注意**: このブロックは `Set recording, analytics and processing behavior` に置き換えられているが、後方互換のため引き続きサポートされる。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `RecordingBehavior.RecordedParticipants` | Array[String] | ○ | 録音対象。`["Agent"]`, `["Customer"]`, `["Agent","Customer"]`, `[]`（無効化）。静的設定のみ |
| `RecordingBehavior.ScreenRecordedParticipants` | Array[String] | × | 画面録画対象。`["Agent"]` のみ可。静的設定のみ |
| `RecordingBehavior.IVRRecordingBehavior` | String | ○ | IVR 録音の有効/無効。`"Enabled"` \| `"Disabled"`。静的設定のみ |
| `AnalyticsBehavior.Enabled` | Boolean | × | Contact Lens 分析の有効/無効。Agent + Customer の両方録音時のみ設定可。静的設定のみ |
| `AnalyticsBehavior.AnalyticsLanguage` | String | × | 言語コード（例: `"en-US"`）。静的設定のみ |
| `AnalyticsBehavior.AnalyticsRedactionBehavior` | String | × | リダクションの有効/無効。`"Enabled"` \| `"Disabled"`。デフォルト `"Disabled"`。静的設定のみ |
| `AnalyticsBehavior.AnalyticsRedactionResults` | String | × | `"RedactedAndOriginal"` \| `"RedactedOnly"`。動的設定可 |
| `AnalyticsBehavior.AnalyticsRedactionMaskMode` | String | × | `"EntityType"` \| `"PII"`。デフォルト `"PII"`。静的設定のみ |
| `AnalyticsBehavior.AnalyticsRedactionEntities` | Array[String] | × | リダクション対象エンティティ（`SSN`, `CREDIT_DEBIT_NUMBER`, `EMAIL` 等 25 種以上）。静的設定のみ |
| `AnalyticsBehavior.ChannelConfiguration` | Object | × | チャネル別設定。Voice: `{"AnalyticsModes":["RealTime","PostContact"]}`、Chat: `{"AnalyticsModes":["ContactLens"]}` |
| `AnalyticsBehavior.SentimentConfiguration.Enabled` | Boolean | × | センチメント分析の有効/無効。静的設定のみ |
| `AnalyticsBehavior.SummaryConfiguration.SummaryModes` | Array[String] | × | `["PostContact"]` — 生成 AI による事後要約 |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: なし

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactRecordingBehavior",
  "Parameters": {
    "RecordingBehavior": {
      "RecordedParticipants": ["Agent", "Customer"],
      "ScreenRecordedParticipants": ["Agent"],
      "IVRRecordingBehavior": "Enabled"
    },
    "AnalyticsBehavior": {
      "Enabled": "True",
      "AnalyticsLanguage": "en-US",
      "AnalyticsRedactionBehavior": "Enabled",
      "AnalyticsRedactionResults": "RedactedAndOriginal",
      "AnalyticsRedactionMaskMode": "EntityType",
      "AnalyticsRedactionEntities": ["SSN", "CREDIT_DEBIT_NUMBER", "EMAIL"],
      "ChannelConfiguration": {
        "Voice": {
          "AnalyticsModes": ["RealTime", "PostContact"]
        }
      },
      "SentimentConfiguration": {
        "Enabled": "True"
      }
    }
  },
  "Transitions": {
    "NextAction": "next-action-id"
  }
}
```

### 利用可能フロータイプ

Inbound flow ○ / Customer queue flow ○ / Outbound whisper flow ○ / Transfer to agent flow ○ / Transfer to queue flow ○ / Customer hold flow × / Customer whisper flow × / Agent hold flow × / Agent whisper flow ×

---

## Set recording, analytics and processing behavior / `UpdateContactRecordingAndAnalyticsBehavior`

- Docs: `set-recording-analytics-processing-behavior.html`
- Channels: Voice ○ / Chat ○ / Task △（画面録画のみ） / Email ×

> **注意**: `Set recording and analytics behavior` の後継ブロック。メッセージプロセッサ機能が追加されている。

### Parameters

#### VoiceBehavior（音声チャネル）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `VoiceBehavior.VoiceRecordingBehavior.RecordedParticipants` | Array[String] | × | `["Agent"]`, `["Customer"]`, `["Agent","Customer"]`, `[]`（無効）。静的設定のみ |
| `VoiceBehavior.VoiceRecordingBehavior.IVRRecordingBehavior` | String | × | `"Enabled"` \| `"Disabled"`。静的設定のみ |
| `VoiceBehavior.VoiceAnalyticsBehavior.Enabled` | Boolean | × | 音声分析有効/無効。Agent+Customer 両方録音時のみ。静的設定のみ |
| `VoiceBehavior.VoiceAnalyticsBehavior.AnalyticsLanguage` | String | × | 言語コード（例: `"en-US"`）。静的設定のみ |
| `VoiceBehavior.VoiceAnalyticsBehavior.AnalyticsModes` | Array[String] | × | `["RealTime"]`, `["PostContact"]`, `["AutomatedInteraction"]` |
| `VoiceBehavior.VoiceAnalyticsBehavior.ConversationalAnalyticsRedactionConfiguration` | Object | × | リダクション設定（下表参照） |
| `VoiceBehavior.VoiceAnalyticsBehavior.SentimentConfiguration.Enabled` | Boolean | × | センチメント分析。静的設定のみ |
| `VoiceBehavior.VoiceAnalyticsBehavior.SummaryConfiguration.SummaryModes` | Array[String] | × | `["PostContact"]`。静的設定のみ |

#### ChatBehavior（チャットチャネル）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ChatBehavior.ChatAnalyticsBehavior.Enabled` | Boolean | × | チャット分析有効/無効。静的設定のみ |
| `ChatBehavior.ChatAnalyticsBehavior.AnalyticsLanguage` | String | × | 言語コード。動的設定可 |
| `ChatBehavior.ChatAnalyticsBehavior.AnalyticsModes` | Array[String] | × | `["ContactLens"]` のみ |
| `ChatBehavior.ChatAnalyticsBehavior.ConversationalAnalyticsRedactionConfiguration` | Object | × | リダクション設定 |
| `ChatBehavior.ChatAnalyticsBehavior.InFlightChatRedactionConfiguration` | Object | × | インフライトリダクション（チャット専用） |
| `ChatBehavior.ChatAnalyticsBehavior.SentimentConfiguration.Enabled` | Boolean | × | センチメント分析 |
| `ChatBehavior.ChatAnalyticsBehavior.SummaryConfiguration.SummaryModes` | Array[String] | × | 事後要約 |

#### ScreenRecordingBehavior（画面録画）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ScreenRecordingBehavior.ScreenRecordedParticipants` | Array[String] | × | `["Agent"]` のみ可。空配列で無効化。静的設定のみ |

#### ConversationalAnalyticsRedactionConfiguration（共通サブオブジェクト）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `Enabled` | Boolean | × | 静的設定のみ |
| `RedactionResults` | String | × | `"RedactedAndOriginal"` \| `"RedactedOnly"`。動的設定可 |
| `RedactionMaskMode` | String | × | `"EntityType"` \| `"PII"`。静的設定のみ |
| `RedactionEntities` | Array[String] | × | 対象エンティティ（`SSN`, `CREDIT_DEBIT_NUMBER`, `EMAIL`, `PHONE`, `NAME` 等 35 種以上）。静的設定のみ |

#### InFlightChatRedactionConfiguration（チャット専用サブオブジェクト）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `Enabled` | Boolean | × | 静的設定のみ |
| `RedactionMaskMode` | String | × | `"EntityType"` \| `"PII"`。静的設定のみ |
| `RedactionEntities` | Array[String] | × | 静的設定のみ |
| `DeliverUnprocessedMessages` | Boolean | × | 処理失敗時に未処理メッセージを配信するか。静的設定のみ |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**:
  - `NoMatchingError` — キャッチオール（必須）
  - `ChannelMismatch` — コンタクト開始チャネルとアクション定義チャネルが不一致（必須）
  - `InFlightRedactionConfigurationFailed` — インフライトリダクション開始/停止失敗（ChatBehavior 定義時必須）

### JSON例（抜粋）

**Voice 録音 + 分析:**
```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactRecordingAndAnalyticsBehavior",
  "Parameters": {
    "VoiceBehavior": {
      "VoiceRecordingBehavior": {
        "RecordedParticipants": ["Agent", "Customer"],
        "IVRRecordingBehavior": "Enabled"
      },
      "VoiceAnalyticsBehavior": {
        "Enabled": true,
        "AnalyticsLanguage": "en-US",
        "AnalyticsModes": ["PostContact"],
        "SentimentConfiguration": { "Enabled": true },
        "SummaryConfiguration": { "SummaryModes": ["PostContact"] },
        "ConversationalAnalyticsRedactionConfiguration": {
          "Enabled": true,
          "RedactionResults": "RedactedAndOriginal",
          "RedactionMaskMode": "EntityType",
          "RedactionEntities": ["SSN", "CREDIT_DEBIT_NUMBER"]
        }
      }
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" },
      { "NextAction": "error-id", "ErrorType": "ChannelMismatch" }
    ]
  }
}
```

**Chat 分析 + インフライトリダクション:**
```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactRecordingAndAnalyticsBehavior",
  "Parameters": {
    "ChatBehavior": {
      "ChatAnalyticsBehavior": {
        "Enabled": true,
        "AnalyticsLanguage": "en-US",
        "AnalyticsModes": ["ContactLens"],
        "SentimentConfiguration": { "Enabled": true },
        "InFlightChatRedactionConfiguration": {
          "Enabled": true,
          "RedactionMaskMode": "PII",
          "RedactionEntities": ["SSN", "PHONE", "EMAIL"],
          "DeliverUnprocessedMessages": false
        }
      }
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" },
      { "NextAction": "error-id", "ErrorType": "ChannelMismatch" },
      { "NextAction": "error-id", "ErrorType": "InFlightRedactionConfigurationFailed" }
    ]
  }
}
```

### 利用可能フロータイプ

Inbound flow ○ / Customer queue flow ○ / Outbound whisper flow ○ / Transfer to agent flow ○ / Transfer to queue flow ○

---

## Set voice / `UpdateContactTextToSpeechVoice`

- Docs: `set-voice.html`
- Channels: Voice ○ / Chat ×（Success へ遷移するが効果なし） / Task ×（同上） / Email ×（同上）

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `TextToSpeechVoice` | String | ○ | Amazon Polly の音声名（例: `"Joanna"`, `"Matthew"`, `"Lupe"`, `"Mizuki"`, `"Takumi"`）。静的/動的いずれも可。無効値を設定すると TTS が機能しなくなる |
| `TextToSpeechEngine` | String | ○ | エンジン種別: `"standard"`, `"neural"`, `"generative"`。静的/動的いずれも可。未指定時は `"standard"` |
| `TextToSpeechStyle` | String | × | スピーキングスタイル: `"None"`, `"Conversational"`, `"Newscaster"`。Neural エンジンの特定音声のみ対応。静的/動的いずれも可 |

**動的設定の制約:**
- Language を動的にする場合は Voice も動的にする必要がある
- Voice が動的かつスタイルをオーバーライドする場合、Engine と Style も動的にする必要がある

**Neural エンジン対応スタイル（主要）:**
- Matthew (en-US): Conversational, Newscaster
- Joanna (en-US): Conversational, Newscaster
- Lupe (es-US): Conversational, Newscaster
- Amy (en-GB): Conversational, Newscaster

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError` — 音声/エンジンの組み合わせが無効な場合、選択した音声が選択したエンジンに対応していない場合

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactTextToSpeechVoice",
  "Parameters": {
    "TextToSpeechVoice": "Joanna",
    "TextToSpeechEngine": "neural",
    "TextToSpeechStyle": "Conversational"
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

### 利用可能フロータイプ

すべてのフロータイプで利用可能。デフォルト音声は `"Joanna"`。

---

## Set callback number / `UpdateContactCallbackNumber`

- Docs: `set-callback-number.html`
- Channels: Voice ○ / Chat ×（Invalid number へ遷移） / Task ×（同上） / Email ×（同上）

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `CallbackNumber` | JSONPath 参照 (String) | ○ | コールバック番号。JSONPath 参照のみ（静的値は不可）。E.164 形式。例: `$.CustomerCallbackNumber`, `$.Attributes.CallbackNum` |

未設定の場合、デフォルトで顧客参加者の発信者 ID が使用される。

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**:
  - `InvalidCallbackNumber` — 指定番号が有効な E.164 電話番号でない
  - `CallbackNumberNotDialable` — 指定番号がインスタンスからダイヤル不可（プレフィクス制限等）

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactCallbackNumber",
  "Parameters": {
    "CallbackNumber": "$.CustomerCallbackNumber"
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "invalid-id", "ErrorType": "InvalidCallbackNumber" },
      { "NextAction": "not-dialable-id", "ErrorType": "CallbackNumberNotDialable" }
    ]
  }
}
```

### 利用可能フロータイプ

Inbound flow ○ / Customer queue flow ○ / Transfer to agent flow ○ / Transfer to queue flow ○ / Whisper flow × / Hold flow ×

---

## Set disconnect flow / `UpdateContactEventHooks`

- Docs: `set-disconnect-flow.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

> **内部実装**: `UpdateContactEventHooks` アクションの `EventHooks` に `CustomerRemaining` キーを使用して実現される。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `EventHooks.CustomerRemaining` | String (Flow ARN/ID) | ○ | 切断イベント発生後に実行するフローの ARN または ID。静的設定のみ |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError` — キャッチオール

### 切断イベントの発生条件

- チャットまたはタスクが切断された場合
- フローアクションの結果としてタスクが切断された場合
- タスクが期限切れになった場合（デフォルト 7 日、最大 90 日に設定可能）

### 主な用途

- ポストコンタクトサーベイの実行
- チャットの顧客無操作シナリオの処理
- タスク期限切れ時の再キュー/完了処理

> **注意**: 顧客切断後にエージェントへ音声プロンプトを再生したりフローを実行することはできない。顧客切断後、フローは終了しエージェントは ACW に入る。

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "CustomerRemaining": "arn:aws:connect:us-west-2:123456789012:instance/instance-id/flow/flow-id"
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

### 利用可能フロータイプ

すべてのフロータイプで利用可能。

---

## Set event flow / `UpdateContactEventHooks`

- Docs: `set-event-flow.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

> **内部実装**: `UpdateContactEventHooks` アクションを使用し、イベントタイプに応じた `EventHooks` キーを指定する。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `EventHooks.<EventType>` | String (Flow ARN/ID) | ○ | 指定イベント発生時に実行するフローの ARN または ID。静的設定のみ。1 アクションにつき 1 エントリのみ |

**利用可能な EventType:**

| EventType | 説明 |
|-----------|------|
| `DefaultAgentUI` | エージェント UI のデフォルトフロー（ステップバイステップガイド） |
| `DisconnectAgentUI` | エージェント UI 切断時フロー |
| `PauseContact` | コンタクト一時停止時のフロー |
| `ResumeContact` | コンタクト再開時のフロー |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError` — キャッチオール

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "DefaultAgentUI": "arn:aws:connect:us-west-2:123456789012:instance/instance-id/flow/flow-id"
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "PauseContact": "arn:aws:connect:us-west-2:123456789012:instance/instance-id/flow/flow-id"
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

### 利用可能フロータイプ

すべてのフロータイプで利用可能。

---

## Set hold flow / `UpdateContactEventHooks`

- Docs: `set-hold-flow.html`
- Channels: Voice ○ / Chat ×（Error へ遷移） / Task ×（Error へ遷移） / Email ×（Error へ遷移）

> **内部実装**: `UpdateContactEventHooks` アクションの `EventHooks` に `CustomerHold` または `AgentHold` キーを使用して実現される。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `EventHooks.CustomerHold` | String (Flow ARN/ID) | ○※ | 顧客保留時に実行するフロー。静的設定のみ |
| `EventHooks.AgentHold` | String (Flow ARN/ID) | ○※ | エージェント保留時に実行するフロー。静的設定のみ |

※ `CustomerHold` と `AgentHold` のいずれか一つを 1 アクションにつき指定。属性を使った動的なフロー指定も可能。

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError` — キャッチオール。非対応チャネル（Chat/Task/Email）で使用された場合もエラーブランチへ遷移

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "CustomerHold": "arn:aws:connect:us-west-2:123456789012:instance/instance-id/flow/flow-id"
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

### 利用可能フロータイプ

Inbound flow ○ / Customer queue flow ○ / Outbound whisper flow ○ / Transfer to agent flow ○ / Transfer to queue flow ○

---

## Set whisper flow / `UpdateContactEventHooks`

- Docs: `set-whisper-flow.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

> **内部実装**: `UpdateContactEventHooks` アクションの `EventHooks` に `AgentWhisper` または `CustomerWhisper` キーを使用して実現される。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `EventHooks.AgentWhisper` | String (Flow ARN/ID) | ○※ | エージェントウィスパーとして実行するフロー。静的設定のみ |
| `EventHooks.CustomerWhisper` | String (Flow ARN/ID) | ○※ | 顧客ウィスパーとして実行するフロー。静的設定のみ |

※ `AgentWhisper` と `CustomerWhisper` のいずれか一つを 1 アクションにつき指定。ウィスパーを無効化するオプションも UI で提供されている。

**制約:**
- ウィスパーの最大持続時間: 2 分（超過するとコンタクト/エージェントが切断される）
- ウィスパーは片方向のみ（エージェント側 OR 顧客側）
- チャットのデフォルトウィスパーは明示的に `Set whisper flow` ブロックで設定が必要（Voice にはデフォルトあり）

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError` — キャッチオール。ウィスパーフロー内に非対応ブロック（Start/Stop media streaming、チャットでの Set voice 等）がある場合もエラー

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "CustomerWhisper": "arn:aws:connect:us-west-2:123456789012:instance/instance-id/flow/flow-id"
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "AgentWhisper": "arn:aws:connect:us-west-2:123456789012:instance/instance-id/flow/flow-id"
    }
  },
  "Transitions": {
    "NextAction": "next-action-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

### 利用可能フロータイプ

Inbound flow ○ / Customer queue flow ○ / Transfer to agent flow ○ / Transfer to queue flow ○

---

## UpdateContactEventHooks — EventType 一覧（まとめ）

`Set disconnect flow`, `Set event flow`, `Set hold flow`, `Set whisper flow` の 4 ブロックはすべて同一の `UpdateContactEventHooks` ActionType を使用し、`EventHooks` のキーでイベント種別を指定する。

| EventType キー | 対応 UI ブロック | 説明 |
|---------------|-----------------|------|
| `AgentHold` | Set hold flow | エージェント保留時 |
| `AgentWhisper` | Set whisper flow | エージェントウィスパー |
| `CustomerHold` | Set hold flow | 顧客保留時 |
| `CustomerQueue` | (Set customer queue flow) | 顧客キュー待ち |
| `CustomerRemaining` | Set disconnect flow | 切断時 |
| `CustomerWhisper` | Set whisper flow | 顧客ウィスパー |
| `DefaultAgentUI` | Set event flow | エージェント UI デフォルト |
| `DisconnectAgentUI` | Set event flow | エージェント UI 切断 |
| `PauseContact` | Set event flow | コンタクト一時停止 |
| `ResumeContact` | Set event flow | コンタクト再開 |
