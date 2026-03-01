# Data — データ・属性・タスク系ブロック

> Source: AWS 公式ドキュメント (https://docs.aws.amazon.com/connect/latest/adminguide/)
> Generated: 2026-03-01

---

## Set contact attributes / `UpdateContactAttributes`

- Docs: `set-contact-attributes.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `Attributes` | Object | ○ | 設定する属性のキー・バリューペア。キーと値は静的/動的に定義可能 |
| `TargetContact` | String | ○（静的） | 属性設定対象: `"Current"`（現在のコンタクト）または `"Related"`（関連コンタクト） |

`Attributes` 内のキー名に `$` や `.`（ピリオド）は使用不可（JSONPath 構文の予約文字）。

**属性の種類**:
- **Current contact**: フロー外（Lambda、コンタクトレコード、GetMetricDataV2 API）からもアクセス可能
- **Related contact**: 元のコンタクトプロパティのコピーを含む新規コンタクトに関連付け
- **Flow 属性**（UI のみ）: フロー内のみ有効な一時変数。最大 32KB。Lambda/モジュールには渡されない

**参照構文**:
- 同一名前空間: 属性名をそのまま使用
- 異なる名前空間: JSONPath（例: `$.External.AttributeKey`）
- 特殊文字を含む場合: `$.Attributes.['user attribute name']`

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

エラー条件: 属性サイズが 32KB を超過した場合。全属性が設定されるか、まったく設定されないかの原子的操作。

### JSON例（抜粋）

```json
{
  "Identifier": "uuid-set-attrs",
  "Type": "UpdateContactAttributes",
  "Parameters": {
    "Attributes": {
      "Language": "ja-JP",
      "CustomerTier": "Premium"
    },
    "TargetContact": "Current"
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

動的値を使用する例:

```json
{
  "Type": "UpdateContactAttributes",
  "Parameters": {
    "Attributes": {
      "GreetingPlayed": "true",
      "CallerName": "$.External.CustomerName"
    },
    "TargetContact": "Current"
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

## Check contact attributes / `Compare`

- Docs: `check-contact-attributes.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ComparisonValue` | String (JSONPath) | ○ | 比較対象の値。フローデータオブジェクトの有効な JSONPath 識別子（例: `$.Attributes.CustomerTier`） |

**比較可能な属性ソース**:
- ユーザー定義属性: `$.Attributes.xxx`
- システム属性: `$.SystemEndpoint.Address` 等
- Lex 属性: `$.Lex.IntentName`, `$.Lex.Slots._slotName_`, `$.Lex.SentimentResponse.Label`
- 外部属性: `$.External.xxx`
- メトリクス: `$.Metrics.Queue.xxx`

### Transitions

- **NextAction**: No Match 時のデフォルト遷移先
- **Conditions**: 最低1つの条件が必須。条件は順序通り評価され、最初にマッチした条件の分岐先へ遷移
- **Errors**: `NoMatchingCondition`（条件が一つもマッチしなかった場合）

**サポートされる演算子**:
- `Equals` — 完全一致（大文字小文字区別あり）
- `NumberGreaterOrEqualTo` — 数値以上
- `NumberLessOrEqualTo` — 数値以下
- `NumberGreaterThan` — 数値より大きい
- `NumberLessThan` — 数値より小さい
- `StartsWith` — 前方一致
- `Contains` — 部分一致

**注意**: 大文字小文字を区別しないパターンマッチングは非対応。NULL 値チェックには Lambda が必要。

### JSON例（抜粋）

```json
{
  "Identifier": "uuid-compare",
  "Type": "Compare",
  "Parameters": {
    "ComparisonValue": "$.Attributes.CustomerTier"
  },
  "Transitions": {
    "NextAction": "no-match-uuid",
    "Conditions": [
      {
        "NextAction": "premium-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["Premium"]
        }
      },
      {
        "NextAction": "standard-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["Standard"]
        }
      }
    ],
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingCondition" }
    ]
  }
}
```

Lex センチメントスコアの比較例:

```json
{
  "Type": "Compare",
  "Parameters": {
    "ComparisonValue": "$.Lex.SentimentResponse.Scores.Negative"
  },
  "Transitions": {
    "NextAction": "default-uuid",
    "Conditions": [
      {
        "NextAction": "escalate-uuid",
        "Condition": {
          "Operator": "NumberGreaterOrEqualTo",
          "Operands": ["0.7"]
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

## Contact tags / `TagContact` + `UnTagContact`

- Docs: `contact-tags-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

UI 上は1つの「Contact tags」ブロックだが、JSON では操作に応じて `TagContact`（タグ付与）と `UnTagContact`（タグ削除）の2つの ActionType に分かれる。

### Parameters — TagContact

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `Tags` | Object | ○ | 設定するタグのキー・バリューペア。キーと値は静的/動的に定義可能 |

コンタクトあたり最大 6 個のユーザー定義タグ。システムタグ（`aws:` プレフィックス）は変更不可。全タグの設定は原子的操作（全て成功 or 全て失敗）。

### Parameters — UnTagContact

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `TagKeys` | Array of String | ○ | 削除するタグキーの配列。静的に定義する必要がある |

システムタグは削除不可。既存のユーザー定義タグのみ削除可能。

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

### JSON例（抜粋）

TagContact:

```json
{
  "Identifier": "uuid-tag",
  "Type": "TagContact",
  "Parameters": {
    "Tags": {
      "Department": "Sales",
      "Priority": "High"
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

UnTagContact:

```json
{
  "Identifier": "uuid-untag",
  "Type": "UnTagContact",
  "Parameters": {
    "TagKeys": ["Department", "Priority"]
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

## Customer profiles / `GetCustomerProfile` 他

- Docs: `customer-profiles-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

UI 上は1つの「Customer profiles」ブロックだが、JSON では操作に応じて複数の ActionType に分かれる:

| ActionType | UI アクション名 |
|-----------|----------------|
| `GetCustomerProfile` | Get profile |
| `CreateCustomerProfile` | Create profile |
| `UpdateCustomerProfile` | Update profile |
| `GetCustomerProfileObject` | Get profile object |
| `GetCalculatedAttributesForCustomerProfile` | Get calculated attributes |
| `AssociateContactToCustomerProfile` | Associate contact to profile |

**前提条件**: Customer Profiles がインスタンスで有効化されていること。

### Parameters — GetCustomerProfile

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ProfileRequestData.IdentifierName` | String | 条件付き※ | 単一検索の識別子名 |
| `ProfileRequestData.IdentifierValue` | String | 条件付き※ | 単一検索の識別子値 |
| `ProfileRequestData.SearchCriteria` | Array | 条件付き※ | 複数検索条件（最大5つ）。各要素に `IdentifierName` と `IdentifierValue` を含む |
| `ProfileRequestData.LogicalOperator` | String | SearchCriteria使用時必須 | `"AND"` または `"OR"` |
| `ProfileResponseData` | Array of String | 任意 | レスポンスとして保持するフィールド名のリスト |

※ `IdentifierName`+`IdentifierValue` または `SearchCriteria` のいずれか必須。

**レスポンスフィールド**: `$.Customer` パスで参照。例: `$.Customer.FirstName`, `$.Customer.ProfileId`

利用可能フィールド: FirstName, MiddleName, LastName, BirthDate, Gender, PhoneNumber, EmailAddress, AccountNumber, BusinessName, Address1-4, City, Country, PostalCode, Attributes.x 等（多数）。

### Parameters — CreateCustomerProfile

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ProfileRequestData.*` | 各種 | 全て任意 | 作成するプロファイルのフィールド（FirstName, LastName, PhoneNumber 等） |
| `ProfileResponseData` | Array of String | 任意 | レスポンスとして保持するフィールド名のリスト |

### Parameters — UpdateCustomerProfile

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ProfileRequestData.ProfileId` | String | ○ | 更新対象のプロファイルID（`$.Customer.ProfileId` から取得） |
| `ProfileRequestData.*` | 各種 | 任意 | 更新するフィールド |
| `ProfileResponseData` | Array of String | 任意 | レスポンスとして保持するフィールド名のリスト |

### Parameters — GetCustomerProfileObject

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ProfileRequestData.ProfileId` | String | ○ | プロファイルID |
| `ProfileRequestData.ObjectType` | String | ○ | 取得するオブジェクトタイプ（例: "Asset", "Order", "Case"） |
| `ProfileRequestData.UseLatest` | Boolean | 条件付き※ | 最新オブジェクトを取得する場合 `true` |
| `ProfileRequestData.IdentifierName` | String | 条件付き※ | 検索識別子名 |
| `ProfileRequestData.IdentifierValue` | String | 条件付き※ | 検索識別子値 |
| `ProfileResponseData` | Array of String | 任意 | レスポンスフィールド（例: `Asset.Price`, `Order.Status` 等） |

※ `UseLatest` または `IdentifierName`+`IdentifierValue` のいずれか必須。

### Parameters — GetCalculatedAttributesForCustomerProfile

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ProfileRequestData.ProfileId` | String | ○ | プロファイルID |
| `ProfileResponseData` | Array of String | 任意 | 計算済み属性名のリスト（例: `CalculatedAttributes._average_hold_time`） |

### Parameters — AssociateContactToCustomerProfile

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ProfileRequestData.ProfileId` | String | ○ | 関連付けるプロファイルID |
| `ProfileRequestData.ContactId` | String | ○ | 関連付けるコンタクトID |

### Transitions

**GetCustomerProfile**:
- **NextAction**: 成功時の遷移先（1件のみ取得）
- **Errors**: `MultipleFoundError`（複数プロファイル該当）, `NoneFoundError`（該当なし）, `NoMatchingError`（その他エラー）

**CreateCustomerProfile / UpdateCustomerProfile / AssociateContactToCustomerProfile**:
- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

**GetCustomerProfileObject / GetCalculatedAttributesForCustomerProfile**:
- **NextAction**: 成功時の遷移先
- **Errors**: `NoneFoundError`（該当なし）, `NoMatchingError`（その他エラー）

**属性サイズ制限**: フロー全体で Customer Profiles ブロックのコンタクト属性合計 14,000 文字。リクエスト値は 255 文字以下。

### JSON例（抜粋）

GetCustomerProfile:

```json
{
  "Identifier": "uuid-get-profile",
  "Type": "GetCustomerProfile",
  "Parameters": {
    "ProfileRequestData": {
      "IdentifierName": "PhoneNumber",
      "IdentifierValue": "$.SystemEndpoint.Address"
    },
    "ProfileResponseData": [
      "FirstName",
      "LastName",
      "AccountNumber",
      "Attributes.LoyaltyPoints"
    ]
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "multiple-uuid", "ErrorType": "MultipleFoundError" },
      { "NextAction": "none-uuid", "ErrorType": "NoneFoundError" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

CreateCustomerProfile:

```json
{
  "Identifier": "uuid-create-profile",
  "Type": "CreateCustomerProfile",
  "Parameters": {
    "ProfileRequestData": {
      "PhoneNumber": "$.SystemEndpoint.Address",
      "FirstName": "Unknown"
    },
    "ProfileResponseData": [
      "ProfileId",
      "PhoneNumber"
    ]
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## Cases / `CreateCase` + `GetCase` + `UpdateCase`

- Docs: `cases-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

UI 上は1つの「Cases」ブロックだが、JSON では操作に応じて3つの ActionType に分かれる。

**前提条件**: Amazon Connect Cases がインスタンスで有効化されていること。

### Parameters — CreateCase

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `CaseTemplateId` | String | ○ | ケーステンプレートの ID |
| `LinkContactToCase` | String | 任意 | `"true"` でコンタクトをケースに自動リンク |
| `CaseRequestFields` | Object | 任意 | ケースフィールドのキー・バリューマップ。キーは Cases ドメインのフィールド、値は静的/動的 |

### Parameters — GetCase

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `CustomerId` | String | ○ | 検索対象の顧客 ID |
| `LinkContactToCase` | String | 任意 | `"true"` でコンタクトをケースに自動リンク |
| `GetLastUpdatedCase` | String | 任意 | `"true"` で最終更新のケースのみ返す |
| `CaseRequestFields` | Object | 任意 | 検索フィルタ用のフィールドマップ |
| `CaseResponseFields` | Array of String | 任意 | レスポンスとして保持するフィールド名のリスト（最大10フィールド） |

**レスポンス参照**: `$.Case.status`, `$.Case.caseId`, `$.Case.{UUID}`（カスタムフィールド）

### Parameters — UpdateCase

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `CaseId` | String | ○ | 更新対象のケース ID |
| `LinkContactToCase` | String | ○ | `"true"` でコンタクトをケースに自動リンク |
| `CaseRequestFields` | Object | 任意 | 更新するフィールドのマップ。キーは Cases ドメインのフィールド、値は静的/動的 |

### Transitions

**CreateCase**:
- **NextAction**: 成功時の遷移先（ケース作成＋コンタクトリンク成功）
- **Errors**: `ContactNotLinked`（ケース作成成功だがコンタクトリンク失敗）, `NoMatchingError`（システムエラー/設定エラー）

**GetCase**:
- **NextAction**: 成功時の遷移先（1件取得＋コンタクトリンク成功）
- **Errors**: `ContactNotLinked`（取得成功だがリンク失敗）, `MultipleFound`（複数ケース該当）, `NoneFound`（該当なし）, `NoMatchingError`（システムエラー）

**UpdateCase**:
- **NextAction**: 成功時の遷移先（更新＋コンタクトリンク成功）
- **Errors**: `ContactNotLinked`（更新成功だがリンク失敗）, `NoMatchingError`（システムエラー）

**カスタムフィールドのUUID取得方法**:
Agent applications > Custom fields > フィールド選択 > URL から UUID を抽出

### JSON例（抜粋）

CreateCase:

```json
{
  "Identifier": "uuid-create-case",
  "Type": "CreateCase",
  "Parameters": {
    "CaseTemplateId": "template-uuid-1234",
    "LinkContactToCase": "true",
    "CaseRequestFields": {
      "title": "Support Request",
      "status": "Open"
    }
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "not-linked-uuid", "ErrorType": "ContactNotLinked" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

GetCase:

```json
{
  "Identifier": "uuid-get-case",
  "Type": "GetCase",
  "Parameters": {
    "CustomerId": "$.Customer.ProfileId",
    "LinkContactToCase": "true",
    "GetLastUpdatedCase": "true",
    "CaseResponseFields": ["status", "title", "caseId"]
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "not-linked-uuid", "ErrorType": "ContactNotLinked" },
      { "NextAction": "multiple-uuid", "ErrorType": "MultipleFound" },
      { "NextAction": "none-uuid", "ErrorType": "NoneFound" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

UpdateCase:

```json
{
  "Identifier": "uuid-update-case",
  "Type": "UpdateCase",
  "Parameters": {
    "CaseId": "$.Case.caseId",
    "LinkContactToCase": "true",
    "CaseRequestFields": {
      "status": "Resolved"
    }
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "not-linked-uuid", "ErrorType": "ContactNotLinked" },
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## Create task / `CreateTask`

- Docs: `create-task-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ContactFlowId` | String (Flow ID / ARN) | ○ | タスク実行時のフロー ID または ARN。完全静的または有効な JSONPath |
| `Name` | String | ○ | タスク名 |
| `Description` | String | 任意 | タスクの説明 |
| `Attributes` | Object | 任意 | タスクに設定する属性のキー・バリューペア。静的/動的に定義可能 |
| `References` | Object | 任意 | タスクの参照情報。`"Type": "Value"` 形式。静的/動的に定義可能 |
| `DelaySeconds` | Integer | 任意 | タスク作成までの遅延秒数（1〜518400 = 6日）。`ScheduledTime` と排他 |
| `ScheduledTime` | String (DateTime) | 任意 | タスク作成予定日時（ISO 8601 形式）。`DelaySeconds` と排他 |
| `TaskTemplateId` | String | 任意 | タスクテンプレート ID。静的に定義する必要がある |

**タスクテンプレート使用時**: テンプレートのフィールドは読み取り専用（上書き不可）。フローが含まれないテンプレートの場合は `ContactFlowId` の指定が必要。

### Transitions

- **NextAction**: 成功時の遷移先。作成されたタスクのコンタクト ID は `$.System.Task Contact id` で参照可能
- **Errors**: `NoMatchingError`（キャッチオール）

エラー条件: タスク作成失敗、スケジュール日時が過去の場合。

**IAM 注意**: 2018年10月以前に作成されたインスタンスでは、サービスロールに `connect:StartTaskContact` ポリシーの追加が必要。

### JSON例（抜粋）

```json
{
  "Identifier": "uuid-create-task",
  "Type": "CreateTask",
  "Parameters": {
    "ContactFlowId": "arn:aws:connect:us-west-2:111111111111:instance/aaaa-bbbb/contact-flow/cccc-dddd",
    "Name": "Follow-up callback",
    "Description": "Customer requested callback regarding order issue",
    "Attributes": {
      "OrderId": "$.Attributes.OrderId",
      "CustomerName": "$.External.CustomerName"
    },
    "DelaySeconds": 3600
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

テンプレート使用例:

```json
{
  "Type": "CreateTask",
  "Parameters": {
    "TaskTemplateId": "template-uuid-5678",
    "Name": "Escalation Task",
    "ContactFlowId": "arn:aws:connect:us-west-2:111111111111:instance/aaaa/contact-flow/bbbb"
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

---

## Create persistent contact association / `CreatePersistentContactAssociation`

- Docs: `create-persistent-contact-association-block.html`
- Channels: Voice × / Chat ○ / Task × / Email ×

チャットの永続化（顧客が中断したチャットを再開可能にする）を有効にするブロック。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `RehydrationType` | String | ○ | チャット再水和方式: `"ENTIRE_PAST_SESSION"`（終了した過去のセッション全体から最新を自動選択）または `"FROM_SEGMENT"`（指定した過去のチャットコンタクトから再水和） |
| `SourceContactId` | String | ○ | 再水和元のコンタクト ID。`ENTIRE_PAST_SESSION` の場合は過去セッションの initialContactId、`FROM_SEGMENT` の場合は特定のチャットコンタクト ID |
| `ClientToken` | String | 任意 | 冪等性を保証するための一意の識別子 |

**制約事項**:
- `StartChatContact` API の `SourceContactId` パラメータとの併用不可（どちらか一方を使用）
- Voice / Task チャネルで使用するとエラー分岐に遷移

**利用可能フロータイプ**: Inbound, Customer Queue, Customer Hold, Customer Whisper, Outbound Whisper, Agent Hold, Agent Whisper, Transfer to Agent, Transfer to Queue

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

エラー条件: 非対応チャネル（Voice/Task）での使用、設定不備。

### JSON例（抜粋）

```json
{
  "Identifier": "uuid-persistent-chat",
  "Type": "CreatePersistentContactAssociation",
  "Parameters": {
    "RehydrationType": "ENTIRE_PAST_SESSION",
    "SourceContactId": "$.Attributes.PreviousSessionContactId"
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```

FROM_SEGMENT 方式:

```json
{
  "Type": "CreatePersistentContactAssociation",
  "Parameters": {
    "RehydrationType": "FROM_SEGMENT",
    "SourceContactId": "$.Attributes.SpecificChatContactId"
  },
  "Transitions": {
    "NextAction": "success-uuid",
    "Errors": [
      { "NextAction": "error-uuid", "ErrorType": "NoMatchingError" }
    ]
  }
}
```
