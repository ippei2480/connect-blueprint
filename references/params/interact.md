# Interact — 顧客対話・入出力系ブロック

> Source: AWS 公式ドキュメント (https://docs.aws.amazon.com/connect/latest/adminguide/)
> Generated: 2026-03-01

---

## Play prompt / `MessageParticipant`

- Docs: `play.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ×

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `PromptId` | String (ARN) | 条件付き※ | Amazon Connect ライブラリのプロンプト ARN |
| `Media.Uri` | String (URL/JSONPath) | 条件付き※ | S3 ファイルパス。属性や連結をサポート |
| `Media.SourceType` | String | `Media` 使用時必須 | `"S3"` 固定 |
| `Media.MediaType` | String | `Media` 使用時必須 | `"Audio"` 固定 |
| `Text` | String | 条件付き※ | TTS テキスト（プレーンまたは SSML）。最大 6,000 文字（課金対象 3,000 文字） |

※ `PromptId` / `Media` / `Text` のいずれか一つを指定する。

**S3 音声ファイル要件**: `.wav` のみ、8KHz/モノラル/U-Law、50MB 未満、5 分未満。

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

エラー条件: S3 ダウンロード失敗、不正な音声形式、50MB/5分超過、不正な SSML、6,000 文字超過、不正なプロンプト ARN、コールバック（エージェント/顧客不在）。

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "MessageParticipant",
  "Parameters": {
    "PromptId": "arn:aws:connect:us-west-2:1111111111:instance/aaaa-bbbb/prompt/abcdef"
  },
  "Transitions": {
    "NextAction": "a625f619-81b0-46c3-a855-89151600bdb1",
    "Errors": [
      {
        "NextAction": "a625f619-81b0-46c3-a855-89151600bdb1",
        "ErrorType": "NoMatchingError"
      }
    ]
  }
}
```

```json
{
  "Type": "MessageParticipant",
  "Parameters": {
    "Media": {
      "Uri": "https://u1.s3.amazonaws.com/en.lob1/welcome.wav",
      "SourceType": "S3",
      "MediaType": "Audio"
    }
  },
  "Transitions": {
    "NextAction": "next-id",
    "Errors": [{ "NextAction": "error-id", "ErrorType": "NoMatchingError" }]
  }
}
```

```json
{
  "Type": "MessageParticipant",
  "Parameters": {
    "Text": "<speak>Thank you for calling</speak>"
  },
  "Transitions": {
    "NextAction": "next-id",
    "Errors": [{ "NextAction": "error-id", "ErrorType": "NoMatchingError" }]
  }
}
```

---

## Get customer input / `GetParticipantInput` | `ConnectParticipantWithLexBot`

- Docs: `get-customer-input.html`
- Channels: Voice ○ / Chat ○（Lex 使用時のみ） / Task × / Email ×

DTMF 入力時は `GetParticipantInput`、Amazon Lex 統合時は `ConnectParticipantWithLexBot` を使用する。

### Parameters（DTMF モード: `GetParticipantInput`）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `Text` | String | ○ | 顧客に再生するプロンプトテキスト |
| `InputTimeLimitSeconds` | String (数値) | ○ | DTMF 入力タイムアウト（1-180 秒） |
| `StoreInput` | String ("True"/"False") | 任意 | 入力を `$.StoredCustomerInput` に保存するか（デフォルト: "False"） |

### Parameters（Lex モード: `ConnectParticipantWithLexBot`）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `LexV2Bot.AliasArn` | String (ARN) | ○ | Lex V2 ボットエイリアス ARN |
| `Text` | String | 任意 | プロンプトテキストまたは初期メッセージ |
| `LexTimeoutSeconds` | Object | 任意 | Lex インタラクションのタイムアウト |

**Lex セッション属性（主要）**:
- `x-amz-lex:audio:start-timeout-ms` — 発話開始待ちタイムアウト（デフォルト 3000ms）
- `x-amz-lex:audio:end-timeout-ms` — 発話終了検出タイムアウト（デフォルト 600ms）
- `x-amz-lex:audio:max-length-ms` — 最大発話長（デフォルト 12000ms、最大 15000ms）
- `x-amz-lex:dtmf:end-character` — DTMF 終了文字（デフォルト `#`）
- `x-amz-lex:dtmf:deletion-character` — DTMF 削除文字（デフォルト `*`）
- `x-amz-lex:dtmf:end-timeout-ms` — DTMF 桁間タイムアウト（デフォルト 5000ms）
- `x-amz-lex:dtmf:max-length` — DTMF 最大桁数（デフォルト 1024）
- `x-amz-lex:allow-interrupt` — バージイン許可

### Transitions

- **NextAction**: デフォルト遷移先
- **Conditions**: DTMF 値（`Equals` + `Operands: ["1"]` 等）またはインテント名
- **Errors**: `InputTimeLimitExceeded` / `NoMatchingCondition` / `NoMatchingError`

### JSON例（抜粋）

```json
{
  "Identifier": "get-input-1",
  "Type": "GetParticipantInput",
  "Parameters": {
    "StoreInput": "False",
    "InputTimeLimitSeconds": "5",
    "Text": "Press 1 for sales, press 2 for support"
  },
  "Transitions": {
    "NextAction": "default-id",
    "Conditions": [
      {
        "NextAction": "sales-id",
        "Condition": { "Operator": "Equals", "Operands": ["1"] }
      },
      {
        "NextAction": "support-id",
        "Condition": { "Operator": "Equals", "Operands": ["2"] }
      }
    ],
    "Errors": [
      { "NextAction": "timeout-id", "ErrorType": "InputTimeLimitExceeded" },
      { "NextAction": "nomatch-id", "ErrorType": "NoMatchingCondition" },
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

```json
{
  "Identifier": "lex-input-1",
  "Type": "ConnectParticipantWithLexBot",
  "Parameters": {
    "Text": "How can I help you?",
    "LexV2Bot": {
      "AliasArn": "arn:aws:lex:us-west-2:123456789012:bot-alias/BOTID/ALIASID"
    },
    "LexTimeoutSeconds": { "Text": "300" }
  },
  "Transitions": {
    "NextAction": "default-id",
    "Errors": [
      { "NextAction": "timeout-id", "ErrorType": "InputTimeLimitExceeded" },
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" },
      { "NextAction": "nomatch-id", "ErrorType": "NoMatchingCondition" }
    ]
  }
}
```

---

## Store customer input / `StoreUserInput`

- Docs: `store-customer-input.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

複数桁の DTMF 入力（クレジットカード番号等）を収集するブロック。入力値は `$.StoredCustomerInput` システム属性に格納される。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Prompt | Audio/TTS | ○ | 顧客に再生するプロンプト（音声ファイルまたは TTS） |
| Maximum Digits | Integer | ○ | 顧客が入力できる最大桁数（例: 20） |
| Phone Number Format | Enum | 任意 | `Local`（国選択）または `International`（国番号必須） |
| Timeout before first entry | Integer (秒) | ○ | 最初の入力までの待機時間（例: 20 秒） |
| Timeout in between each entry | Integer (秒) | ○ | 各入力間の待機時間（1-20 秒、デフォルト 5 秒） |
| Encrypt entry | Boolean | 任意 | 入力を暗号化するか |
| Specify terminating keypress | String | 任意 | カスタム終了キー（最大 5 桁、`#` `*` `0-9` 使用可） |
| Disable cancel key | Boolean | 任意 | `*` をキャンセルキーとして無効化するか（デフォルト: 有効） |

### Transitions

- **NextAction**: 入力取得成功時（タイムアウト時は値 `"Timeout"` が返る）
- **Errors**: エラー分岐（Chat/Task/Email チャネル時など）

**注意**: タイムアウト判定には後続の `Compare` ブロックで `$.StoredCustomerInput` を評価する必要がある。

### JSON例（抜粋）

ドキュメントに JSON サンプルなし。

---

## Loop prompts / `LoopPrompts`

- Docs: `loop-prompts.html`
- Channels: Voice ○ / Chat × / Task × / Email ×

キュー待機中・保留中にプロンプトをループ再生するブロック。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Prompt Type | Enum | ○ | `Audio recording` / `Text to Speech` / `S3 file path` |
| Prompts Sequence | List | ○ | ループ再生するプロンプトの順序リスト |
| Interrupt | Integer (秒) | 任意 | ループ中断のタイムアウト（推奨: 20 秒以上） |
| Continue prompts during interrupt | Boolean | 任意 | 中断後にプロンプトを中断点から再開するか |

**利用可能フロータイプ**: Customer Queue / Customer Hold / Agent Hold のみ。

**配置制約**: 以下のブロックの後に配置不可 — Get customer input, Loop, Play prompt, Start/Stop media streaming, Store customer input, Transfer to phone number, Transfer to queue。

### Transitions

- **Timeout**: 中断タイムアウト到達時
- **Error**: 非対応チャネル（Chat/Task/Email）時

### JSON例（抜粋）

ドキュメントに JSON サンプルなし。

---

## Send message / `SendMessage`

- Docs: `send-message.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

SMS / WhatsApp / Email でアウトバウンドメッセージを送信するブロック。

### Parameters（SMS）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| From | Phone Number (ARN) | ○ | 送信元電話番号（インスタンスで取得済みの番号） |
| To | String (E.164) | ○ | 送信先電話番号（E.164 形式） |
| Message | String | ○ | プレーンテキスト（最大 1024 文字） |
| Flow | Flow ARN | 任意 | アウトバウンドフロー（作成されたコンタクトのハンドリング用） |
| Link to contact | Boolean | 任意 | インバウンドコンタクトとのリンク |

### Parameters（WhatsApp）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| From | WhatsApp Number (ARN) | ○ | 送信元 WhatsApp 番号 |
| To | String (E.164) | ○ | 送信先 WhatsApp 番号（E.164 形式） |
| Message template | Template | ○ | WhatsApp テンプレート（必須） |
| Flow | Flow ARN | 任意 | アウトバウンドフロー |
| Link to contact | Boolean | 任意 | インバウンドコンタクトとのリンク |

### Parameters（Email）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| From | Email Address | ○ | 送信元メールアドレス |
| To | Email Address | ○ | 送信先メールアドレス（1 件） |
| CC | Email Address List | 任意 | CC アドレス（セミコロン `;` 区切り） |
| Message (Subject) | String | ○ | 件名（最大 998 文字） |
| Message (Body) | String | ○ | 本文（プレーンテキスト、最大 5,000 文字） |
| Link to contact | Boolean | 任意 | インバウンドコンタクトとのリンク |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`

エラー条件: 不正な送信元アドレス、メール送信サービス障害、テンプレート属性のポピュレート失敗。

**注意**: Email で Send message を使用する場合、無限ループ防止のため `Check contact attributes` ブロックで `$.Channel` を判定してから分岐すること。

### JSON例（抜粋）

ドキュメントに JSON サンプルなし。

---

## Wait / `Wait`

- Docs: `wait.html`
- Channels: Voice ○（条件付き） / Chat ○ / Task ○ / Email ○

顧客の返信やイベントを待機するブロック。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Participant Type | Enum | ○ | `Default`（顧客コンタクト）または `Bot`（カスタム参加者/サードパーティボット） |
| Timeout | Integer + Unit | ○ | 最大 7 日。動的設定時は秒単位 |
| Customer return | Branch | 任意 | 顧客復帰時のルーティング（Default 時のみ） |
| Set Event based Wait | Lambda/RequestId | 任意 | Lambda 完了待ち（Default 時のみ） |
| Keep running while waiting | Boolean | 任意 | 待機中に Continue 分岐を実行（Default 時のみ） |

### Transitions

**Participant Type = Default 時**:
- **Time Expired**: タイムアウト
- **Customer return**: 顧客がメッセージ送信で復帰
- **Lambda Return**: Lambda 実行完了（イベントベース待機時）
- **Continue**: 待機中の継続分岐
- **Error**: エラー

**Participant Type = Bot 時**:
- **Bot participant disconnected**: カスタム参加者の切断
- **Participant not found**: カスタム参加者が見つからない
- **Time Expired**: タイムアウト
- **Error**: エラー

**制約**: Wait ブロックのネスト（Wait の Continue 分岐内に別の Wait）は不可。

### JSON例（抜粋）

ドキュメントに JSON サンプルなし。

---

## Show view / `ShowView`

- Docs: `show-view-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

エージェントワークスペースまたはチャットでビュー（フォーム等）を表示するブロック。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ViewResource.Id` | String (ARN) | ○ | ビューリソースの ARN（例: `arn:aws:connect:us-west-2:aws:view/form:1`） |
| `InvocationTimeLimitSeconds` | String (数値) | ○ | ステップ完了タイムアウト（秒） |
| `ViewData` | Object | 任意 | ビューに渡す動的データ |

**ViewData の主要サブパラメータ**（Form ビューの例）:

| パラメータ | 型 | 説明 |
|-----------|-----|------|
| `Sections` | String/Object | フォームセクション構成 |
| `AttributeBar` | Array | 属性バー（`Label`, `Value`, `LinkType`, `ResourceId`, `Copyable`） |
| `Back` / `Cancel` | Object | ボタン構成（`{"Label": "Back"}` 等） |
| `Heading` | String | 見出し（動的参照 `$.Customer.LastName` 対応） |
| `SubHeading` | String | サブ見出し |
| `ErrorText` | String | エラーメッセージ |
| `Wizard` | Object | プログレストラッカー（`Heading`, `Selected`） |

**追加設定**: `This view has sensitive data` — 有効時、機密データがトランスクリプトに記録されない。

**出力属性**: `$.Views.Action`（操作内容）、`$.Views.ViewResultData`（出力データ）

### Transitions

- **NextAction**: デフォルト遷移先
- **Conditions**: ビューのアクションに基づく分岐（例: `Equals` + `["Back"]`, `["Next"]`）
- **Errors**: `NoMatchingCondition` / `NoMatchingError` / `TimeLimitExceeded`

### JSON例（抜粋）

```json
{
  "Identifier": "53c6be8a-d01f-4dd4-97a5-a001174f7f66",
  "Type": "ShowView",
  "Parameters": {
    "ViewResource": {
      "Id": "arn:aws:connect:us-west-2:aws:view/form:1"
    },
    "InvocationTimeLimitSeconds": "2",
    "ViewData": {
      "Heading": "$.Customer.LastName",
      "SubHeading": "$.Customer.FirstName",
      "AttributeBar": [
        { "Label": "Example", "Value": "Attribute" },
        { "Label": "Case", "Value": "Case 123456", "LinkType": "case", "ResourceId": "123456", "Copyable": true }
      ],
      "Back": { "Label": "Back" },
      "Cancel": { "Label": "Cancel" },
      "Next": "Next",
      "Wizard": { "Heading": "Progress tracker", "Selected": "Step Selected" }
    }
  },
  "Transitions": {
    "NextAction": "7c5ef809-544e-4b5f-894f-52f214d8d412",
    "Conditions": [
      {
        "NextAction": "back-id",
        "Condition": { "Operator": "Equals", "Operands": ["Back"] }
      },
      {
        "NextAction": "next-id",
        "Condition": { "Operator": "Equals", "Operands": ["Next"] }
      }
    ],
    "Errors": [
      { "NextAction": "nomatch-id", "ErrorType": "NoMatchingCondition" },
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" },
      { "NextAction": "timeout-id", "ErrorType": "TimeLimitExceeded" }
    ]
  }
}
```

---

## Get stored content / `LoadContactContent`

- Docs: `get-stored-content.html`
- Channels: Voice × / Chat × / Task × / Email ○

S3 バケットからメールメッセージのコンテンツを取得するブロック。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ContentType` | Enum | ○ | 現在 `"EmailMessage"` のみサポート |

取得したコンテンツは `$.Email.EmailMessage.Plaintext` フロー属性に格納される。最大サイズ: **32 KB**。

### Transitions

- **NextAction**: コンテンツ取得成功時
- **Errors**: `NoMatchingError`

エラー条件: メールプレーンテキストが 32KB 超過、S3 バケットからのダウンロード失敗（バケットポリシー/権限/CORS の不備）、プレーンテキストメールが存在しない。

### JSON例（抜粋）

```json
{
  "Identifier": "load-content-1",
  "Type": "LoadContactContent",
  "Parameters": {
    "ContentType": "EmailMessage"
  },
  "Transitions": {
    "NextAction": "next-id",
    "Errors": [
      { "NextAction": "error-id", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## Data Table / `EvaluateDataTable` | `ListDataTable` | `WriteDataTable`

- Docs: `data-table-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

データテーブルの読み取り（評価/リスト）または書き込みを行うブロック。操作タイプにより ActionType が異なる。

### Parameters（Evaluate: データテーブル値の評価）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Action | Enum | ○ | `"Read from data table"` |
| Read Action | Enum | ○ | `"Evaluate Data Table values"` |
| Data Table | Reference | ○ | 対象データテーブル |
| Query Name | String | ○ | クエリ名（フロー全体でユニーク） |
| Primary Attributes | Object | ○ | フィルタ条件（スキーマから自動生成、完全一致） |
| Query Attributes | Array | ○ | 取得する属性（最低 1 つ） |

最大 5 クエリ/ブロック。結果は `$.DataTables.{QueryName}.{AttributeName}` で参照。

### Parameters（List: データテーブル値のリスト取得）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Action | Enum | ○ | `"Read from data table"` |
| Read Action | Enum | ○ | `"List Data Table values"` |
| Data Table | Reference | ○ | 対象データテーブル |
| Group Name | String | ○ | プライマリ値グループ名（フロー全体でユニーク） |
| Primary Attributes | Object | ○ | フィルタ条件（スキーマから自動生成） |

最大 5 グループ/ブロック。結果は `$.DataTableList.ResultData.primaryKeyGroups.{GroupName}[{index}]` で参照。

### Parameters（Write: データテーブルへの書き込み）

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Action | Enum | ○ | `"Write to data table"` |
| Data Table | Reference | ○ | 対象データテーブル |
| Group Name | String | ○ | プライマリ値グループ名（フロー全体でユニーク） |
| Primary Attributes | Object | ○ | キーフィールド（スキーマから自動生成、全て必須） |
| Attribute Name | String | ○ | 書き込む属性名 |
| Attribute Value | String | 条件付き | `"Set attribute value"` 選択時に必須 |
| Use Default Value | Boolean | 任意 | スキーマで定義されたデフォルト値を使用 |
| Lock Version | Enum | ○ | `"Use Latest"`（デフォルト）または `"Set dynamically"` |

全グループ合計で最大 **25 属性**。Upsert 動作（一致レコードがあれば更新、なければ作成）。

### Transitions

- **NextAction**: 成功時
- **Errors**: エラー分岐

### 制約・注意事項

- クエリ名/グループ名はフロー全体でユニークであること
- プライマリ属性は完全一致でフィルタ
- リスト型のデータテーブル値は非サポート
- 後続の Data Table ブロックは前のクエリ結果をクリアする
- クエリ結果はそのフロー内でのみ参照可能

### JSON例（抜粋）

ドキュメントに JSON サンプルなし。アクセスパターン例:

```
// Evaluate
$.DataTables.CustomerLookup.accountStatus

// List
$.DataTableList.ResultData.primaryKeyGroups.OrderHistory[0].attributes[0].attributeValue
```
