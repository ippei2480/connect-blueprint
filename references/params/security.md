# Security — 認証・メディア系ブロック

## Authenticate Customer / `AuthenticateParticipant`

- Docs: `authenticate-customer.html`
- Channels: Voice × / Chat ○ / Task × / Email ×

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| CognitoUserPoolId | String | ○ | Amazon Cognito ユーザープールの選択 |
| CognitoAppClientId | String | ○ | Amazon Cognito アプリクライアントの選択 |
| StoreByDefaultTemplate | Boolean | × | デフォルトテンプレートで Cognito 標準属性を統合プロファイルに取り込む |
| UniqueIdentifier | String | × | カスタムオブジェクトタイプマッピング名 |
| Timeout | Integer | ○ | 非アクティブ顧客のタイムアウト時間（3〜15分、デフォルト: 3） |

### Transitions

- **Success**: 顧客が認証に成功
- **Timeout**: 顧客が割り当て時間内にサインインしなかった
- **OptedOut**: 顧客がサインインを辞退
- **Error**: Customer Profiles 未有効、チャットサブタイプ非対応、認証コードエラー、Cognito トークンエンドポイントエラー等

### 対応フロータイプ

Inbound flow のみ

### 制約事項

- Customer Profiles が有効であること
- Amazon Cognito ユーザープールが作成済みであること
- Voice/Task/Email チャネルでは Error 分岐に遷移

---

## Check Voice ID / `CheckVoiceId`

- Docs: `check-voice-id.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

> **注意**: Amazon Connect Voice ID は 2026年5月20日以降サポート終了予定

### Parameters

設定可能なプロパティなし。先行する Set Voice ID ブロックの結果に基づいて自動的に分岐を生成する。

### Transitions

3つのモードがあり、それぞれ異なる分岐を持つ：

**Enrollment Status（登録状態）:**
- **Enrolled**: 音声認証に登録済み
- **Not Enrolled**: 未登録
- **Opted Out**: 音声認証をオプトアウト

**Voice Authentication（音声認証）:**
- **Authenticated**: 認証スコアが閾値以上（デフォルト: 90）
- **Not Authenticated**: スコアが閾値未満
- **Inconclusive**: 分析不可（通常10秒未満の音声）
- **Not Enrolled**: 未登録
- **Opted Out**: オプトアウト

**Fraud Detection（不正検出）:**
- **High Risk**: リスクスコアが閾値以上
- **Low Risk**: リスクスコアが閾値未満
- **Inconclusive**: 不正検出分析不可

- **Error**: 非対応チャネル（Chat/Task/Email）で使用した場合

### 対応フロータイプ

Inbound flow, Customer queue flow, Customer whisper flow, Outbound whisper flow, Agent whisper flow, Transfer to agent flow, Transfer to queue flow

### 制約事項

- 事前に Set Voice ID ブロックと Set contact attributes（CustomerId 設定）が必要
- Inconclusive / Not Enrolled / Opted Out の結果には課金なし

---

## Set Voice ID / `StartVoiceIdStream`

- Docs: `set-voice-id.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

> **注意**: Amazon Connect Voice ID は 2026年5月20日以降サポート終了予定

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| StartStreaming | Boolean | ○ | Voice ID への音声ストリーミングを有効にする（一度有効にすると無効化不可） |
| AuthenticationThreshold | Integer (0-100) | × | 認証一致の信頼度スコア閾値（デフォルト: 90） |
| AuthenticationResponseTime | Integer (5-10) | × | 認証分析の許容時間（秒、デフォルト: 10） |
| FraudThreshold | Integer (0-100) | × | 不正リスクスコア閾値（デフォルト: 50） |
| FraudWatchlistId | String (22文字英数字) | × | 不正検出用ウォッチリストID（デフォルトまたは動的に設定） |

### Transitions

- **Success**: ブロック実行成功
- **Error**: 無効なウォッチリスト形式、その他のエラー

### 対応フロータイプ

Inbound flow, Customer queue flow, Customer whisper flow, Outbound whisper flow, Agent whisper flow, Transfer to agent flow, Transfer to queue flow

### 制約事項

- 一度有効にした音声ストリーミングは無効化不可
- Set Voice ID の前に Play prompt ブロックを推奨（音声ストリーミングの適切な開始のため）
- CustomerId 属性は Set contact attributes ブロックで Set Voice ID の後に設定

---

## Hold customer or agent / `UpdateParticipantState`

- Docs: `hold-customer-agent.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| HoldType | Enum | ○ | `AgentOnHold`（エージェント保留）/ `CustomerOnHold`（顧客保留）/ `ConferenceAll`（全員通話） |

### Transitions

- **Success**: ブロック実行成功
- **Error**: 非対応チャネル（Chat/Task/Email）で使用した場合

### 対応フロータイプ

Inbound flow, Outbound whisper flow, Transfer to agent flow, Transfer to queue flow

### 制約事項

- ビデオ通話中は保留状態でもエージェントは顧客のビデオ/画面共有を見ることができる

---

## Start media streaming / `StartMediaStreaming`

- Docs: `start-media-streaming.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| StreamDirection | Enum | ○ | `FromTheCustomer`（顧客が発する音声をキャプチャ）/ `ToTheCustomer`（顧客が聞く音声をキャプチャ） |

### Transitions

- **Success**: メディアストリーミング開始成功
- **Error**: 非対応チャネル（Chat/Task/Email）で使用した場合

### 対応フロータイプ

Inbound flow, Customer queue flow, Agent whisper flow, Customer whisper flow, Outbound whisper flow, Transfer to agent flow, Transfer to queue flow

### 制約事項

- インスタンスでライブメディアストリーミングが有効であること
- Stop media streaming ブロックが呼ばれるまで音声キャプチャが継続
- フロー転送後もキャプチャは継続

---

## Stop media streaming / `StopMediaStreaming`

- Docs: `stop-media-streaming.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

### Parameters

設定可能なプロパティなし。

### Transitions

- **Success**: メディアストリーミング停止成功
- **Error**: 非対応チャネル（Chat/Task/Email）で使用した場合

### 対応フロータイプ

Inbound flow, Customer queue flow, Customer whisper flow, Outbound whisper flow, Agent whisper flow, Transfer to agent flow, Transfer to queue flow

### 制約事項

- Start media streaming ブロックとペアで使用する
- フロー転送後も Stop media streaming が呼ばれるまでキャプチャは継続
