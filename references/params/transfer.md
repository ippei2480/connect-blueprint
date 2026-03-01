# Transfer — 転送・発信系ブロック

> 取得元: AWS 公式ドキュメント (docs.aws.amazon.com/connect/latest/adminguide/)
> および API Reference (docs.aws.amazon.com/connect/latest/APIReference/)

---

## Transfer to queue / `TransferContactToQueue`

- Docs: `transfer-to-queue.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### 概要

キューにまだ入っていないコンタクトを、TargetQueue に配置する。
既にキューに入っている（エージェントへルーティング中・接続中）場合は失敗する。

Customer Queue フローで使用する場合は `DequeueContactAndTransferToQueue` として動作し、
コールバック設定時は `CreateCallbackContact` として動作する。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| *(なし)* | — | — | TransferContactToQueue 自体はパラメータ不要。事前に `UpdateContactTargetQueue`（Set working queue）でキューを設定する |

### Transitions

- **NextAction**: 成功時（コンタクトがまだキューに入っていない場合）
- **Errors**:
  - `QueueAtCapacity` — キューが容量上限に達している
  - `NoMatchingError` — その他のエラー

### 制限事項

- Inbound フロー、Transfer フローで使用可能
- Whisper フロー、Customer Queue フロー、Hold フローでは使用不可
- キュー間転送の最大チェーン数: 12（転送回数は最大11回）
- Customer Queue フロー内で使用する場合は `Loop prompts` ブロックを事前配置が必要

### JSON例（抜粋）

```json
{
    "Parameters": {},
    "Identifier": "a12c905c-84dd-45c1-8f53-4287d1752d59",
    "Type": "TransferContactToQueue",
    "Transitions": {
        "NextAction": "",
        "Errors": [
            {
                "NextAction": "0a1dc9a4-8657-4941-a980-772046b94f1e",
                "ErrorType": "QueueAtCapacity"
            },
            {
                "NextAction": "6e84a9b5-1ed0-40b1-815d-a3bdd4b2dc8a",
                "ErrorType": "NoMatchingError"
            }
        ]
    }
}
```

---

### (補足) キュー間転送 / `DequeueContactAndTransferToQueue`

- 使用可能フロー: Customer Queue フローのみ
- Transfer to queue ブロックを Customer Queue フロー内で使うとこの ActionType になる

#### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `QueueId` | String (Queue ID or ARN) | △ | 転送先キュー。`AgentId` と排他 |
| `AgentId` | String (Agent ID or ARN) | △ | エージェントキュー。`QueueId` と排他 |

> `QueueId` と `AgentId` のいずれか一方を指定する（同時指定不可）。

#### Errors

- `QueueAtCapacity` — 転送先キューが容量上限
- `NoMatchingError` — その他のエラー

#### JSON例

```json
{
    "Parameters": {
        "QueueId": "arn:aws:connect:us-west-2:1111111111:instance/aaaa-bbbb-cccc/queue/abcdef-1234"
    },
    "Identifier": "180c3ae1-3ae6-43ee-b293-546e5df0286a",
    "Type": "DequeueContactAndTransferToQueue",
    "Transitions": {
        "NextAction": "",
        "Errors": [
            {
                "NextAction": "0a1dc9a4-8657-4941-a980-772046b94f1e",
                "ErrorType": "QueueAtCapacity"
            },
            {
                "NextAction": "6e84a9b5-1ed0-40b1-815d-a3bdd4b2dc8a",
                "ErrorType": "NoMatchingError"
            }
        ]
    }
}
```

---

### (補足) コールバック / `CreateCallbackContact`

- Transfer to queue ブロックでコールバック設定を行った場合に使用される ActionType
- Contact フロー、Transfer フロー、Customer Queue フローで使用可能

#### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `QueueId` | String (Queue ID or ARN) | 任意 | コールバック先キュー。`AgentId` と排他 |
| `AgentId` | String (Agent ID or ARN) | 任意 | エージェントキュー。`QueueId` と排他 |
| `InitialCallDelaySeconds` | Integer | 必須 | コールバック開始までの待機秒数（1〜259200） |
| `MaximumConnectionAttempts` | Integer | 必須 | 最大接続試行回数（1以上） |
| `RetryDelaySeconds` | Integer | 必須 | 再試行間隔秒数（1〜259200） |
| `ContactFlowId` | String (Flow ID or ARN) | 任意 | コールバック作成後に実行するフロー。指定時は `InitialCallDelaySeconds` は無視 |
| `CallerId` | String (Phone Number) | 任意 | 顧客に表示する発信者番号。インスタンスに紐づく番号のみ |

#### Errors

- `NoMatchingError` — エラー発生時

---

## Transfer to phone number / `TransferToPhoneNumber`

- Docs: `transfer-to-phone-number.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### 概要

顧客をインスタンス外部の電話番号に転送する。Chat/Task/Email チャネルでは Error 分岐に遷移する。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Country code | String | 必須 | 国コード（例: +1） |
| Phone number | String | 必須 | 転送先の外部電話番号 |
| Timeout | Integer (秒) | 任意 | タイムアウト秒数（デフォルト: 30秒） |
| Resume flow after disconnect | Boolean | 任意 | 外部側が切断後にフローを再開するか |
| Send DTMF | String | 任意 | 送信するDTMFトーン（カンマ `,` で750msポーズ） |
| Caller ID number | String | 任意 | 発信者番号として表示する番号 |
| Caller ID name | String | 任意 | 発信者名（表示は保証されない） |

### Transitions

- **NextAction**: Success — 転送成功
- **Errors**:
  - `CallFailed` — 転送試行が失敗
  - `Timeout` — 呼び出しがタイムアウト
  - `NoMatchingError` — その他のエラー（非対応チャネル等）

### 制限事項

- Inbound フロー、Customer Queue フロー、Transfer to Agent フロー、Transfer to Queue フローで使用可能
- 外部発信には対象国のサービスクォータ引き上げが必要
- オーストラリアでは Amazon Connect DID 番号を Caller ID として使用必須

### JSON例

ドキュメントにJSON例の掲載なし。以下は推定構造:

```json
{
    "Parameters": {
        "PhoneNumber": "+15551234567",
        "CountryCode": "+1",
        "ThirdPartyPhoneNumber": "+15551234567",
        "SendDTMF": "1,,2",
        "CallerIdNumber": "+15559876543",
        "ConnectionTimeLimitSeconds": "30"
    },
    "Identifier": "uuid-here",
    "Type": "TransferToPhoneNumber",
    "Transitions": {
        "NextAction": "success-uuid",
        "Errors": [
            {
                "NextAction": "callfailed-uuid",
                "ErrorType": "CallFailure"
            },
            {
                "NextAction": "timeout-uuid",
                "ErrorType": "ConnectionTimeLimitExceeded"
            },
            {
                "NextAction": "error-uuid",
                "ErrorType": "NoMatchingError"
            }
        ]
    }
}
```

---

## Transfer to flow / `TransferToFlow`

- Docs: `transfer-to-flow.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### 概要

現在のフローを終了し、指定した別のフローに顧客を転送する。
指定できるフローは公開済み（Published）のもののみ。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ContactFlowId` | String (Flow ID or ARN) | 必須 | 転送先フローのID or ARN。完全に静的か、単一の有効なJSONPathで指定 |

### Transitions

- **NextAction**: なし（フロー終了して別フローへ遷移するため）
- **Conditions**: なし
- **Errors**:
  - `NoMatchingError` — 指定フローが無効、または無効なフロータイプの場合

### 制限事項

- Inbound フロー、Transfer フローで使用可能
- Hold フロー、Customer Queue フロー、Whisper フローでは使用不可
- 転送先は Inbound / Transfer to Agent / Transfer to Queue タイプのフローのみ

### JSON例

```json
{
    "Parameters": {
        "ContactFlowId": "arn:aws:connect:us-west-2:123456789012:instance/aaaa-bbbb/contact-flow/cccc-dddd"
    },
    "Identifier": "uuid-here",
    "Type": "TransferToFlow",
    "Transitions": {
        "NextAction": "",
        "Errors": [
            {
                "NextAction": "error-uuid",
                "ErrorType": "NoMatchingError"
            }
        ]
    }
}
```

---

## Transfer to agent (beta) / `TransferContactToAgent`

- Docs: `transfer-to-agent-block.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### 概要

現在のフローを終了し、顧客をエージェントに転送する（ベータ機能）。
エージェントが別の顧客と対応中の場合、コンタクトは切断される。
エージェントが After Contact Work (ACW) 状態の場合、転送時に自動的にACWが解除される。

> AWS はオムニチャネル対応のため、代わりに `Set working queue` ブロックの使用を推奨。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| *(なし)* | — | — | このブロックにはプロパティ設定がない |

### Transitions

- **NextAction**: なし（フロー終了してエージェントへ転送）
- **Conditions**: なし
- **Errors**: なし

### 制限事項

- Transfer to Agent フロー、Transfer to Queue フローでのみ使用可能
- Voice チャネルのみ対応（ベータ）
- Chat/Task/Email では使用不可

### JSON例

```json
{
    "Parameters": {},
    "Identifier": "uuid-here",
    "Type": "TransferContactToAgent",
    "Transitions": {}
}
```

---

## Call phone number / `CompleteOutboundCall`

- Docs: `call-phone-number.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### 概要

アウトバウンドコールを発信する。Outbound Whisper フロー専用。
このブロックを使用しない場合、最初の参加者アクションが暗黙的にアウトバウンドコールを完了する。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `CallerId.Number` | String (Phone Number) | 任意 | 発信時に表示する電話番号。VoiceConnector使用時は無視される |
| `VoiceConnector.VoiceConnectorType` | String | 任意 | `"ChimeConnector"` 固定（Voice Connector使用時） |
| `VoiceConnector.VoiceConnectorArn` | String | 任意 | Voice Connector の ARN |
| `VoiceConnector.FromUser` | String | 条件付必須 | Voice Connector 使用時の発信元ユーザー |
| `VoiceConnector.ToUser` | String | 条件付必須 | Voice Connector 使用時の宛先ユーザー |
| `VoiceConnector.UserToUserInformation` | String | 任意 | SIP User-to-User 情報 |
| `ConnectionTimeLimitSeconds` | Integer (1-600) | 任意 | Voice Connector使用時のみ。接続待機秒数 |

### Transitions

- **NextAction**: Success — 発信成功
- **Errors**: なし（発信失敗時はフロー終了、エージェントはACW状態になる）

### 制限事項

- Outbound Whisper フローでのみ使用可能
- カスタム Caller ID の利用には AWS サポートチケットが必要
- Caller ID 未指定の場合はキューに設定された Caller ID が使用される
- 公開済みフローのみアウトバウンド Whisper フローとして選択可能

### JSON例

```json
{
    "Parameters": {
        "CallerId": {
            "Number": "+15559876543"
        }
    },
    "Identifier": "uuid-here",
    "Type": "CompleteOutboundCall",
    "Transitions": {
        "NextAction": "next-uuid"
    }
}
```

Voice Connector 使用時:

```json
{
    "Parameters": {
        "VoiceConnector": {
            "VoiceConnectorType": "ChimeConnector",
            "VoiceConnectorArn": "arn:aws:chime:us-east-1:123456789012:vc/abcdef",
            "FromUser": "sip:from@example.com",
            "ToUser": "sip:to@example.com",
            "UserToUserInformation": "optional-info"
        },
        "ConnectionTimeLimitSeconds": "30"
    },
    "Identifier": "uuid-here",
    "Type": "CompleteOutboundCall",
    "Transitions": {
        "NextAction": "next-uuid"
    }
}
```

---

## Check call progress / `CheckOutboundCallStatus`

- Docs: `check-call-progress.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### 概要

留守番電話の検出を行い、結果に応じてコンタクトをルーティングする。
Amazon Connect のアウトバウンドキャンペーン専用。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| *(なし)* | — | — | パラメータ不要（空オブジェクト `{}` を指定） |

### Transitions

- **Conditions** (Equals 演算子のみ対応):
  - `CallAnswered` — 通話が人に応答された
  - `VoicemailBeep` — ボイスメール（ビープ音あり）を検出
  - `VoicemailNoBeep` — ボイスメール（ビープ音なし、または不明）を検出
  - `NotDetected` — 応答種別を判定不能（長時間の無音、過度のバックグラウンドノイズ等）
- **Errors**:
  - `NoMatchingError` — その他のエラー（メディア確立後のシステムエラー、非対応チャネル等）

### 制限事項

- Amazon Connect のアウトバウンドキャンペーン有効時のみ使用可能

### JSON例

```json
{
    "Parameters": {},
    "Identifier": "uuid-here",
    "Type": "CheckOutboundCallStatus",
    "Transitions": {
        "NextAction": "not-detected-uuid",
        "Conditions": [
            {
                "NextAction": "answered-uuid",
                "Condition": {
                    "Operator": "Equals",
                    "Operands": ["CallAnswered"]
                }
            },
            {
                "NextAction": "voicemail-beep-uuid",
                "Condition": {
                    "Operator": "Equals",
                    "Operands": ["VoicemailBeep"]
                }
            },
            {
                "NextAction": "voicemail-nobeep-uuid",
                "Condition": {
                    "Operator": "Equals",
                    "Operands": ["VoicemailNoBeep"]
                }
            },
            {
                "NextAction": "not-detected-uuid",
                "Condition": {
                    "Operator": "Equals",
                    "Operands": ["NotDetected"]
                }
            }
        ],
        "Errors": [
            {
                "NextAction": "error-uuid",
                "ErrorType": "NoMatchingError"
            }
        ]
    }
}
```
