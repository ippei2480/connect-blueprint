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

## ActionType × AWS Docs パス対応テーブル

各ActionTypeのパラメータ・Transitions・Errors の正確な仕様は AWS MCP で参照する。

| ActionType | AWS Docs パス |
|-----------|--------------|
| `MessageParticipant` | `amazonconnect/latest/adminguide/play-prompt.html` |
| `GetParticipantInput` | `amazonconnect/latest/adminguide/get-customer-input.html` |
| `UpdateContactTargetQueue` | `amazonconnect/latest/adminguide/set-working-queue.html` |
| `TransferContactToQueue` | `amazonconnect/latest/adminguide/transfer-to-queue.html` |
| `DisconnectParticipant` | `amazonconnect/latest/adminguide/disconnect-hang-up.html` |
| `InvokeLambdaFunction` | `amazonconnect/latest/adminguide/invoke-lambda-function-block.html` |
| `UpdateContactAttributes` | `amazonconnect/latest/adminguide/set-contact-attributes.html` |
| `Compare` | `amazonconnect/latest/adminguide/check-contact-attributes.html` |
| `InvokeFlowModule` | `amazonconnect/latest/adminguide/invoke-module.html` |
| `CheckHoursOfOperation` | `amazonconnect/latest/adminguide/check-hours-of-operation.html` |
| `Loop` | `amazonconnect/latest/adminguide/loop.html` |
| `UpdateContactRecordingBehavior` | `amazonconnect/latest/adminguide/set-recording-behavior.html` |
| `UpdateContactRecordingAndAnalyticsBehavior` | `amazonconnect/latest/adminguide/set-recording-behavior.html` |
| `UpdateContactTextToSpeechVoice` | `amazonconnect/latest/adminguide/set-voice.html` |
| `UpdateFlowLoggingBehavior` | `amazonconnect/latest/adminguide/set-logging-behavior.html` |
| `TransferToPhoneNumber` | `amazonconnect/latest/adminguide/transfer-to-phone-number.html` |

### AWS MCP での参照手順

1. `aws___read_documentation` でパスを指定して公式ドキュメントを取得する
2. パラメータ名・型・必須/任意を確認する
3. フローJSON生成時にドキュメントの仕様に従う

```
例: GetParticipantInput のパラメータを確認する場合
→ aws___read_documentation(path="amazonconnect/latest/adminguide/get-customer-input.html")
```
