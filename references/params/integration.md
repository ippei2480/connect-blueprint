# Integration — 統合・フロー制御系ブロック

> Source: AWS 公式ドキュメント (https://docs.aws.amazon.com/connect/latest/adminguide/)
> Generated: 2026-03-01

---

## AWS Lambda function / `InvokeLambdaFunction`

- Docs: `invoke-lambda-function-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `LambdaFunctionARN` | String (ARN) | ○ | 呼び出す Lambda 関数の ARN。静的・動的指定可 |
| `InvocationTimeLimitSeconds` | Integer | ○ | Lambda のレスポンス待機時間（秒）。同期: 最大 8 秒、非同期: 最大 60 秒。静的指定のみ |
| `InvocationType` | String | ○ | `"SYNCHRONOUS"` または `"ASYNCHRONOUS"` |
| `LambdaInvocationAttributes` | Map (Object) | × | Lambda に送信する追加データ（キー・値のペア）。静的・動的指定可 |
| `ResponseValidation.ResponseType` | String | × | レスポンスの検証タイプ。`"STRING_MAP"`（フラットなキー/値）または `"JSON"`（ネストされた JSON 可）。静的指定のみ |

**同期モード**: Lambda 完了を待ってから次のブロックに遷移。スロットリングまたは 500 エラー時は最大 3 回リトライ。
**非同期モード**: Lambda 完了を待たずに次のブロックに遷移。`$.LambdaInvocation.InvocationId` で呼び出し ID を取得可能。

**Load Lambda result パラメータ**（非同期モードの結果取得時）:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Lambda Invocation RequestId | String reference | ○ | Lambda 呼び出しの requestId。`$.LambdaInvocation.InvocationId` で参照 |

### Transitions

- **NextAction**: 成功時の遷移先（同期モード: Lambda 完了後、非同期モード: 即座に遷移）
- **Errors**: `NoMatchingError`（キャッチオール）

エラー条件: Lambda 呼び出し失敗、タイムアウト超過、スロットリング（3 回リトライ後）。
Lambda の結果は `$.External` 名前空間で動的に参照可能。

### 対応フロータイプ

Inbound flow / Customer Queue flow / Customer Hold flow / Customer Whisper flow / Agent Hold flow / Agent Whisper flow / Transfer to Agent flow / Transfer to Queue flow

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "InvokeLambdaFunction",
  "Parameters": {
    "LambdaFunctionARN": "arn:aws:lambda:us-west-2:111111111111:function:my-function",
    "InvocationTimeLimitSeconds": "8",
    "InvocationType": "SYNCHRONOUS",
    "LambdaInvocationAttributes": {
      "customKey": "customValue"
    },
    "ResponseValidation": {
      "ResponseType": "STRING_MAP"
    }
  },
  "Transitions": {
    "NextAction": "next-uuid",
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

## Invoke module / `InvokeFlowModule`

- Docs: `invoke-module-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `FlowModuleId` | String (ID or ARN) | ○ | 呼び出すフローモジュールの ID または ARN。静的・動的指定可 |

### Transitions

- **NextAction**: モジュール実行成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

モジュール内の `EndFlowModuleExecution`（Return ブロック）に到達すると、親フローの NextAction に遷移する。

### 対応フロータイプ

Inbound flow のみ

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "InvokeFlowModule",
  "Parameters": {
    "FlowModuleId": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  },
  "Transitions": {
    "NextAction": "next-uuid",
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

## Return from module / `EndFlowModuleExecution`

- Docs: `return-module.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

なし（空オブジェクト `{}`）

### Transitions

なし（ターミナルブロック）。フローモジュールの実行を終了し、親フローに戻る。

### 対応フロータイプ

Flow Modules のみ

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "EndFlowModuleExecution",
  "Parameters": {},
  "Transitions": {}
}
```

---

## Loop / `Loop`

- Docs: `loop.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

**「Set number of loops」モード:**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `LoopCount` | Number (String) | ○ | ループ回数。0〜100 の整数。静的・動的指定可。0 の場合は即座に Complete 分岐へ |

**「Set array for looping」モード:**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Array/List input | Array | ○ | ループ対象の配列 |
| Loop Name | String | ○ | 一意のループ名。ループ変数参照に必須 |

**ループ変数（Loop Name 設定時）:**
- `$.Loop.<loopName>.Index` — 現在のインデックス（0 始まり）
- `$.Loop.<loopName>.Element` — 現在のループ要素（配列ループのみ）
- `$.Loop.<loopName>.Elements` — 入力配列（配列ループのみ）

### Transitions

- **NextAction**: タイムアウト / デフォルト遷移先
- **Conditions**:
  - `ContinueLooping`（`Equals` 条件） — ループ継続時の遷移先
  - `DoneLooping`（`Equals` 条件） — ループ完了時の遷移先
- **Errors**: なし

**重要**: `ContinueLooping` と `DoneLooping` の両方の Conditions が必須。片方でも欠けるとループ制御が機能しない。

### 対応フロータイプ

すべてのフロータイプ

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "Loop",
  "Parameters": {
    "LoopCount": "3"
  },
  "Transitions": {
    "NextAction": "done-uuid",
    "Conditions": [
      {
        "NextAction": "looping-uuid",
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

---

## Disconnect / hang up / `DisconnectParticipant`

- Docs: `disconnect-hang-up.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

なし（空オブジェクト `{}`）

### Transitions

なし（ターミナルブロック）。コンタクトを切断し、フローの実行を停止する。
`Transitions` は空オブジェクト `{}` でOK。Errors 不要。

### 対応フロータイプ

Inbound flow / Customer Queue flow / Transfer to Agent flow / Transfer to Queue flow

### JSON例（抜粋）

```json
{
  "Identifier": "abcdef-abcd-abcd-abcd-abcdefghijkl",
  "Type": "DisconnectParticipant",
  "Parameters": {},
  "Transitions": {}
}
```

---

## End flow / Resume / `EndFlowExecution`

- Docs: `end-flow-resume.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

なし（空オブジェクト `{}`）

### Transitions

なし（ターミナルブロック）。現在のフローを終了するが、コンタクトは切断しない。
参加者はフロー終了後のコンタクトロジックによって切断される可能性がある（例: まだキューに入っていない場合はコンタクト終了）。

**注意**: Inbound flow や Disconnect flow に配置した場合、Disconnect ブロックと同じ動作になりコンタクトが終了する。

### 対応フロータイプ

Whisper flows / Customer Queue flows
（通常のフローには使用不可）

### 主な用途

- Transfer to Queue ブロックの Success 分岐
- Loop prompts ブロックが中断された場合
- Paused flow を終了してコンタクトを返却する場合
- タスクの Pause/Resume ワークフロー

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "EndFlowExecution",
  "Parameters": {},
  "Transitions": {}
}
```

---

## Resume contact / `ResumeContact`

- Docs: `resume-contact.html`
- Channels: Voice × / Chat × / Task ○ / Email ×

Task チャネルのみサポート。他のチャネルでは Error 分岐に遷移する。

### Parameters

ドキュメントにパラメータの詳細記載なし。UI 上では Properties ページで設定を行う。

API レベルでは以下のパラメータが使用される:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `ContactId` | String | ○ | コンタクトの識別子 |
| `InstanceId` | String | ○ | Amazon Connect インスタンスの識別子 |
| `FlowId` | String | × | フローの識別子（最大 500 文字） |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: Error event（サポートされていないチャネルや実行エラー時）

### 対応フロータイプ

すべてのフロータイプ

### 設計上の注意

一時停止したタスクを再開後、割り当て解除・デキューされたタスクをキューに戻すには、Resume contact ブロックの後に **Transfer to queue** ブロックを配置すること。そうしないとタスクがデキュー状態のままになる。

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "ResumeContact",
  "Parameters": {},
  "Transitions": {
    "NextAction": "next-uuid",
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

## Connect assistant / `CreateWisdomSession`

- Docs: `connect-assistant-block.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

Amazon Q in Connect（旧 Amazon Connect Wisdom）のドメインをコンタクトに関連付け、リアルタイムレコメンデーションを有効化する。

**注意**: 送信メールがこのブロックに到達した場合、何も起こらないが **課金は発生する**。Task や送信メールは事前に Check contact attributes ブロックでルーティングすること。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `WisdomAssistantArn` | String (ARN) | ○ | Connect assistant ドメインの ARN。静的・動的指定可 |

UI 上では以下の追加設定が存在:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| Orchestration AI agent | Selection | × | Agent Assistance に使用する Orchestration AI エージェントの指定 |

### Transitions

- **NextAction**: 成功時の遷移先
- **Errors**: `NoMatchingError`（キャッチオール）

### 対応フロータイプ

Inbound flow / Customer Queue flow / Outbound whisper flow / Transfer to Agent flow / Transfer to Queue flow

### 前提条件

- **Voice の場合**: Amazon Connect Contact Lens が必須。Set recording and analytics behavior ブロックで Contact Lens リアルタイムを有効化すること。
- **Chat の場合**: Contact Lens は不要。

### JSON例（抜粋）

```json
{
  "Identifier": "12345678-1234-1234-1234-123456789012",
  "Type": "CreateWisdomSession",
  "Parameters": {
    "WisdomAssistantArn": "arn:aws:wisdom:us-west-2:111111111111:assistant/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  },
  "Transitions": {
    "NextAction": "next-uuid",
    "Errors": [
      {
        "NextAction": "error-uuid",
        "ErrorType": "NoMatchingError"
      }
    ]
  }
}
```
