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
| `CheckMetricData` | メトリクス条件 | キュー状態・スタッフ判定 |
| `CheckOutboundCallStatus` | `CallConnected` 等 | 発信結果の分岐 |
| `DistributeByPercentage` | パーセンテージ条件 | 割合分岐 |

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

## ActionType × AWS Docs パス対応テーブル

各ActionTypeの詳細パラメータ仕様は `references/params/` のローカルキャッシュを参照する。
キャッシュにない情報が必要な場合のみ AWS MCP (`aws___read_documentation`) をフォールバックとして使用する。

### Interact — 顧客対話・入出力系 (`references/params/interact.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| Play prompt | `MessageParticipant` | `play.html` |
| Get customer input | `GetParticipantInput` / `ConnectParticipantWithLexBot` | `get-customer-input.html` |
| Store customer input | `StoreUserInput` | `store-customer-input.html` |
| Loop prompts | `LoopPrompts` | `loop-prompts.html` |
| Send message | `SendMessage` | `send-message.html` |
| Wait | `Wait` | `wait.html` |
| Show view | `ShowView` | `show-view-block.html` |
| Get stored content | `LoadContactContent` | `get-stored-content.html` |
| Data Table | `EvaluateDataTable` / `ListDataTable` / `WriteDataTable` | `data-table-block.html` |

### Routing — ルーティング・キュー系 (`references/params/routing.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| Set working queue | `UpdateContactTargetQueue` | `set-working-queue.html` |
| Check queue status | `CheckMetricData` | `check-queue-status.html` |
| Check staffing | `CheckMetricData` | `check-staffing.html` |
| Get metrics | `GetMetricData` | `get-queue-metrics.html` |
| Check hours of operation | `CheckHoursOfOperation` | `check-hours-of-operation.html` |
| Set routing criteria | `UpdateRoutingCriteria` | `set-routing-criteria.html` |
| Change routing priority / age | `UpdateContactRoutingBehavior` | `change-routing-priority.html` |
| Set customer queue flow | `UpdateContactEventHooks` | `set-customer-queue-flow.html` |
| Distribute by percentage | `DistributeByPercentage` | `distribute-by-percentage.html` |

### Transfer — 転送・発信系 (`references/params/transfer.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| Transfer to queue | `TransferContactToQueue` | `transfer-to-queue.html` |
| Transfer to phone number | `TransferToPhoneNumber` | `transfer-to-phone-number.html` |
| Transfer to flow | `TransferToFlow` | `transfer-to-flow.html` |
| Transfer to agent (beta) | `TransferContactToAgent` | `transfer-to-agent-block.html` |
| Call phone number | `CompleteOutboundCall` | `call-phone-number.html` |
| Check call progress | `CheckOutboundCallStatus` | `check-call-progress.html` |

### Data — データ・属性・タスク系 (`references/params/data.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| Set contact attributes | `UpdateContactAttributes` | `set-contact-attributes.html` |
| Check contact attributes | `Compare` | `check-contact-attributes.html` |
| Contact tags | `TagContact` / `UnTagContact` | `contact-tags-block.html` |
| Customer profiles | `GetCustomerProfile` 他5種 | `customer-profiles-block.html` |
| Cases | `CreateCase` / `GetCase` / `UpdateCase` | `cases-block.html` |
| Create task | `CreateTask` | `create-task-block.html` |
| Create persistent contact association | `CreatePersistentContactAssociation` | `create-persistent-contact-association-block.html` |

### Settings — 設定系 (`references/params/settings.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| Set logging behavior | `UpdateFlowLoggingBehavior` | `set-logging-behavior.html` |
| Set recording and analytics behavior | `UpdateContactRecordingBehavior` | `set-recording-behavior.html` |
| Set recording, analytics and processing behavior | `UpdateContactRecordingAndAnalyticsBehavior` | `set-recording-analytics-processing-behavior.html` |
| Set voice | `UpdateContactTextToSpeechVoice` | `set-voice.html` |
| Set callback number | `UpdateContactCallbackNumber` | `set-callback-number.html` |
| Set disconnect flow | `UpdateContactEventHooks` | `set-disconnect-flow.html` |
| Set event flow | `UpdateContactEventHooks` | `set-event-flow.html` |
| Set hold flow | `UpdateContactEventHooks` | `set-hold-flow.html` |
| Set whisper flow | `UpdateContactEventHooks` | `set-whisper-flow.html` |

### Integration — 統合・フロー制御系 (`references/params/integration.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| AWS Lambda function | `InvokeLambdaFunction` | `invoke-lambda-function-block.html` |
| Invoke module | `InvokeFlowModule` | `invoke-module-block.html` |
| Return from module | `EndFlowModuleExecution` | `return-module.html` |
| Loop | `Loop` | `loop.html` |
| Disconnect / hang up | `DisconnectParticipant` | `disconnect-hang-up.html` |
| End flow / Resume | `EndFlowExecution` | `end-flow-resume.html` |
| Resume contact | `ResumeContact` | `resume-contact.html` |
| Connect assistant | `CreateWisdomSession` | `connect-assistant-block.html` |

### Security — 認証・メディア系 (`references/params/security.md`)

| UIブロック名 | ActionType | AWS Docs パス |
|-------------|-----------|--------------|
| Authenticate Customer | `AuthenticateParticipant` | `authenticate-customer.html` |
| Check Voice ID | `CheckVoiceId` | `check-voice-id.html` |
| Set Voice ID | `StartVoiceIdStream` | `set-voice-id.html` |
| Hold customer or agent | `UpdateParticipantState` | `hold-customer-agent.html` |
| Start media streaming | `StartMediaStreaming` | `start-media-streaming.html` |
| Stop media streaming | `StopMediaStreaming` | `stop-media-streaming.html` |

> Note: AWS Docs パスはすべて `amazonconnect/latest/adminguide/` 配下。

### パラメータ参照手順

1. まず `references/params/*.md` のローカルキャッシュでパラメータ仕様を確認する
2. キャッシュにない情報が必要な場合のみ `aws___read_documentation` でフォールバック参照する
3. フローJSON生成時にドキュメントの仕様に従う

```
例: GetParticipantInput のパラメータを確認する場合
→ references/params/interact.md の「Get customer input」セクションを参照
→ 不足があれば aws___read_documentation(path="amazonconnect/latest/adminguide/get-customer-input.html")
```
