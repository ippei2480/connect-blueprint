# Routing — ルーティング・キュー系ブロック

> Source: AWS 公式ドキュメント (docs.aws.amazon.com/connect/latest/adminguide/ および APIReference)

---

## Set working queue / `UpdateContactTargetQueue`

- Docs: `set-working-queue.html`
- API Ref: `contact-actions-updatecontacttargetqueue.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `QueueId` | string (Queue ID or ARN) | Optional※ | 設定するキューのIDまたはARN。`AgentId` と排他。完全に静的か、単一の有効なJSONPath識別子で指定 |
| `AgentId` | string (Agent ID or ARN) | Optional※ | エージェントキューを表すエージェントIDまたはARN。`QueueId` と排他。完全に静的か、単一の有効なJSONPath識別子で指定 |

※ `QueueId` と `AgentId` のいずれか一方を指定する。

### Transitions

- **NextAction**: 成功時の遷移先（Conditions なし）
- **Conditions**: なし
- **Errors**: `NoMatchingError`

### 制約

- Inbound flow、Transfer flow でのみ使用可能
- Whisper flow、Hold flow、Customer queue flow では使用不可

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactTargetQueue",
  "Parameters": {
    "QueueId": "arn:aws:connect:REGION:ACCOUNT:instance/INSTANCE_ID/queue/QUEUE_ID"
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

動的設定の場合:
```json
{
  "Parameters": {
    "QueueId": "$.Attributes.targetQueue"
  }
}
```

---

## Check queue status / `CheckMetricData`

- Docs: `check-queue-status.html`
- API Ref: `flow-control-actions-checkmetricdata.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

> **注意**: Check queue status と Check staffing は同一の ActionType `CheckMetricData` を共有する。`MetricType` パラメータの値で動作が異なる。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `MetricType` | string (enum) | Yes | 取得するメトリクスの種別。Check queue status では `OldestContactInQueueAgeSeconds` または `NumberOfContactsInQueue` を使用 |
| `QueueId` | string (Queue ID or ARN) | Optional※ | 対象キューのIDまたはARN。`AgentId` と排他。動的値サポート |
| `AgentId` | string (Agent ID or ARN) | Optional※ | エージェントキューを表すエージェントIDまたはARN。`QueueId` と排他。動的値サポート。どちらも未指定時はコンタクトの TargetQueue を使用 |

**MetricType の有効値（Check queue status 用）**:
- `OldestContactInQueueAgeSeconds` — キュー内の最も古いコンタクトの待ち時間（秒）
- `NumberOfContactsInQueue` — キュー内のコンタクト数

### Transitions

- **NextAction**: 条件に一致しない場合の遷移先
- **Conditions**: `Equals` および `Number*` オペランド（`NumberGreaterThan`, `NumberLessThan` 等）による比較分岐。条件は追加順に評価され、最初に一致した条件で分岐
- **Errors**: `NoMatchingError`, `NoMatchingCondition`（条件に一致しない場合）

### 制約

- Inbound flow、Transfer flow、Customer queue flow で使用可能
- Whisper flow、Hold flow では使用不可

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "CheckMetricData",
  "Parameters": {
    "MetricType": "NumberOfContactsInQueue"
  },
  "Transitions": {
    "NextAction": "no-match-uuid",
    "Conditions": [
      {
        "NextAction": "condition-met-uuid",
        "Condition": {
          "Operator": "NumberGreaterThan",
          "Operands": ["5"]
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

---

## Check staffing / `CheckMetricData`

- Docs: `check-staffing.html`
- API Ref: `flow-control-actions-checkmetricdata.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

> **注意**: Check queue status と同一の ActionType `CheckMetricData` を使用。`MetricType` で動作が決まる。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `MetricType` | string (enum) | Yes | 取得するメトリクスの種別。Check staffing では `NumberOfAgentsAvailable`, `NumberOfAgentsStaffed`, `NumberOfAgentsOnline` のいずれか |
| `QueueId` | string (Queue ID or ARN) | Optional※ | 対象キューのIDまたはARN。`AgentId` と排他。動的値サポート |
| `AgentId` | string (Agent ID or ARN) | Optional※ | エージェントキューを表すエージェントIDまたはARN。`QueueId` と排他。動的値サポート |

**MetricType の有効値（Check staffing 用）**:
- `NumberOfAgentsAvailable` — Available 状態のエージェントが1人以上いるか
- `NumberOfAgentsStaffed` — Available / On call / ACW 状態のエージェントが1人以上いるか
- `NumberOfAgentsOnline` — Available / Staffed / カスタム状態のエージェントが1人以上いるか

**NumberOfAgents* メトリクスの条件制約**: サポートされる条件は `NumberGreaterThan 0` のみ（True/False の2分岐になる）。

### Transitions

- **NextAction**: False 側の遷移先
- **Conditions**: `NumberGreaterThan 0` のみ → True 分岐
- **Errors**: `NoMatchingError`

### 制約

- Inbound flow、Transfer flow、Customer queue flow で使用可能
- Whisper flow、Hold flow では使用不可
- 事前に `Set working queue` でキューを設定しておく必要がある（未設定時は Error 分岐）

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "CheckMetricData",
  "Parameters": {
    "MetricType": "NumberOfAgentsAvailable"
  },
  "Transitions": {
    "NextAction": "false-uuid",
    "Conditions": [
      {
        "NextAction": "true-uuid",
        "Condition": {
          "Operator": "NumberGreaterThan",
          "Operands": ["0"]
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

---

## Get metrics / `GetMetricData`

- Docs: `get-queue-metrics.html`
- API Ref: `flow-control-actions-getmetricdata.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `QueueId` | string (Queue ID or ARN) | Optional※ | 対象キューのIDまたはARN。`AgentId` と排他。動的値サポート |
| `AgentId` | string (Agent ID or ARN) | Optional※ | エージェントキューを表すエージェントIDまたはARN。`QueueId` と排他。動的値サポート |
| `QueueChannel` | string (`Voice` / `Chat`) | Optional | メトリクスを取得するチャネル。未指定時は全チャネルの集約値。動的設定可 |

※ いずれも未指定時は TargetQueue が使用される。

### 返却されるメトリクス属性

取得後、`$.Metrics.*` で参照可能:

| メトリクス | 説明 |
|-----------|------|
| Queue name | キュー名 |
| Queue ARN | キューARN |
| Contacts in queue | キュー内コンタクト数 |
| Oldest contact in queue | 最古コンタクトの待ち時間 |
| Agents online | オンラインエージェント数 |
| Agents available | Available エージェント数 |
| Agents staffed | Staffed エージェント数 |
| Agents after contact work | ACW 中エージェント数 |
| Agents busy | 対応中エージェント数 |
| Agents missed | 応答なしエージェント数 |
| Agents non-productive | 非生産状態エージェント数 |
| Queue estimated wait time | キュー推定待ち時間（単一チャネル指定時のみ） |
| Contact estimated wait time | コンタクト推定待ち時間 |
| Contact position in queue | キュー内位置 |

### Transitions

- **NextAction**: 成功時の遷移先（Conditions なし）
- **Conditions**: なし
- **Errors**: `NoMatchingError`

### 制約

- すべてのフロータイプで使用可能
- メトリクスはニアリアルタイム（5-10秒の遅延あり）
- コンタクトセンターにアクティビティがない場合、メトリクスは返却されない

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "GetMetricData",
  "Parameters": {
    "QueueId": "arn:aws:connect:REGION:ACCOUNT:instance/INSTANCE_ID/queue/QUEUE_ID",
    "QueueChannel": "Voice"
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

## Check hours of operation / `CheckHoursOfOperation`

- Docs: `check-hours-of-operation.html`
- API Ref: `flow-control-actions-checkhoursofoperation.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `HoursOfOperationId` | string (HoO ID or ARN) | Optional | 営業時間オブジェクトのIDまたはARN。完全に静的または完全に動的。未指定時はコンタクトの TargetQueue に関連付けられた営業時間を使用 |

### Transitions

- **NextAction**: なし（`True`/`False` の Conditions で分岐必須）
- **Conditions**: `Equals "True"` と `Equals "False"` の**両方が必須**。他の条件は不可
- **Errors**: `NoMatchingError`

### 制約

- Inbound flow、Transfer flow、Customer queue flow で使用可能
- Hold flow、Whisper flow では使用不可
- エージェントキュー（自動作成）には営業時間が設定されていないため、エージェントキューで使用すると Error 分岐に遷移

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "CheckHoursOfOperation",
  "Parameters": {
    "HoursOfOperationId": "arn:aws:connect:REGION:ACCOUNT:instance/INSTANCE_ID/operating-hours/HOO_ID"
  },
  "Transitions": {
    "NextAction": "",
    "Conditions": [
      {
        "NextAction": "in-hours-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["True"]
        }
      },
      {
        "NextAction": "out-of-hours-uuid",
        "Condition": {
          "Operator": "Equals",
          "Operands": ["False"]
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

---

## Set routing criteria / `UpdateRoutingCriteria`

- Docs: `set-routing-criteria.html`
- API Ref: `flow-control-actions-updateroutingcriteria.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `RoutingCriteria` | object | Yes | ルーティング条件を定義するオブジェクト |
| `RoutingCriteria.Steps` | array | Yes | ルーティングステップの配列。順次評価され、期限切れ時に次ステップへ進む |
| `Steps[].Expression` | object | Yes | ルーティング式。`AttributeCondition`, `AndExpression`, `OrExpression`, `NotAttributeCondition` のいずれか |
| `Steps[].Expression.AttributeCondition` | object | — | 定義済み属性条件 |
| `Steps[].Expression.AttributeCondition.Name` | string (1-64) | Yes | 属性名（例: "Language", "Technology"） |
| `Steps[].Expression.AttributeCondition.Value` | string (1-64) | Yes | 属性値（例: "English", "AWS Kinesis"） |
| `Steps[].Expression.AttributeCondition.ProficiencyLevel` | float | Yes | 熟練度レベル（1.0〜5.0） |
| `Steps[].Expression.AttributeCondition.ComparisonOperator` | string | Yes | `NumberGreaterOrEqualTo` または `Range` |
| `Steps[].Expression.AndExpression` | array | — | AND 結合する AttributeCondition のリスト（最大8属性） |
| `Steps[].Expression.OrExpression` | array | — | OR 結合する式のリスト（最大3条件）。OR はトップレベルのみ。AND を内包可能だが逆は不可 |
| `Steps[].Expiry` | object | — | ステップの有効期限。最終ステップ以外は必須 |
| `Steps[].Expiry.DurationInSeconds` | number (static) | — | 有効期限（秒）。静的値のみ。未設定時はステップが期限切れにならない |

### Transitions

- **NextAction**: 成功時の遷移先（Conditions なし）
- **Conditions**: なし
- **Errors**: `NoMatchingError`

### 制約

- Inbound flow、Customer queue flow、Transfer to Agent flow、Transfer to Queue flow で使用可能
- 最大 8 属性/AND 条件、最大 3 OR 条件/ステップ、最大 10 優先エージェント/ステップ

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateRoutingCriteria",
  "Parameters": {
    "RoutingCriteria": {
      "Steps": [
        {
          "Expression": {
            "AndExpression": [
              {
                "AttributeCondition": {
                  "Name": "Language",
                  "Value": "English",
                  "ProficiencyLevel": 4,
                  "ComparisonOperator": "NumberGreaterOrEqualTo"
                }
              },
              {
                "AttributeCondition": {
                  "Name": "Technology",
                  "Value": "AWS Kinesis",
                  "ProficiencyLevel": 2,
                  "ComparisonOperator": "NumberGreaterOrEqualTo"
                }
              }
            ]
          },
          "Expiry": {
            "DurationInSeconds": 30
          }
        },
        {
          "Expression": {
            "AttributeCondition": {
              "Name": "Language",
              "Value": "English",
              "ProficiencyLevel": 1,
              "ComparisonOperator": "NumberGreaterOrEqualTo"
            }
          }
        }
      ]
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

## Change routing priority / age / `UpdateContactRoutingBehavior`

- Docs: `change-routing-priority.html`
- API Ref: `contact-actions-updatecontactroutingbehavior.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `QueuePriority` | integer (static) | Optional※ | キュー優先度。低い値ほど優先。デフォルト: 5。範囲: 1〜9223372036854775807。`QueueTimeAdjustmentSeconds` と排他 |
| `QueueTimeAdjustmentSeconds` | integer (static) | Optional※ | キュー滞在時間の調整値（秒）。正の値でコンタクトを「古く」見せて優先度を上げる。負の値も可。`QueuePriority` と排他 |

※ いずれか一方を指定する。

### Transitions

- **NextAction**: 成功時の遷移先
- **Conditions**: なし
- **Errors**: なし

### 制約

- **Inbound flow でのみ使用可能**
- Transfer flow、Whisper flow、Customer queue flow、Hold flow では使用不可
- 既にキューにいるコンタクトへの変更は反映まで最低 60 秒かかる
- 即時適用するには Transfer to queue ブロックの前に設定すること

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactRoutingBehavior",
  "Parameters": {
    "QueuePriority": "1"
  },
  "Transitions": {
    "NextAction": "next-uuid"
  }
}
```

時間調整の例:
```json
{
  "Parameters": {
    "QueueTimeAdjustmentSeconds": "300"
  }
}
```

---

## Set customer queue flow / `UpdateContactEventHooks`

- Docs: `set-customer-queue-flow.html`
- API Ref: `contact-actions-updatecontacteventhooks.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

> **注意**: `UpdateContactEventHooks` は複数のUIブロック（Set customer queue flow / Set hold flow / Set whisper flow / Set event flow）で共有される ActionType。`EventHooks` の Key で動作が決まる。

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `EventHooks` | object | Yes | イベントフックのマップ。Key はイベントタイプ、Value はフローIDまたはARN。エントリは1つのみ |

**Set customer queue flow で使用する Key**: `CustomerQueue`

**EventHooks の有効な Key 一覧**:
- `AgentHold` / `AgentWhisper` / `CustomerHold` / `CustomerQueue` / `CustomerRemaining` / `CustomerWhisper` / `DefaultAgentUI` / `DisconnectAgentUI` / `PauseContact` / `ResumeContact`

### Transitions

- **NextAction**: 成功時の遷移先
- **Conditions**: なし
- **Errors**: `NoMatchingError`

### 制約

- すべてのフロータイプで使用可能

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "UpdateContactEventHooks",
  "Parameters": {
    "EventHooks": {
      "CustomerQueue": "arn:aws:connect:REGION:ACCOUNT:instance/INSTANCE_ID/contact-flow/FLOW_ID"
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

## Distribute by percentage / `DistributeByPercentage`

- Docs: `distribute-by-percentage.html`
- API Ref: `flow-control-actions-distributebypercentage.html`
- Channels: Voice ○ / Chat ○ / Task ○ / Email ○

### Parameters

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| （なし） | — | — | パラメータオブジェクトは空 `{}`。分岐比率は Conditions で制御する |

### Transitions

- **NextAction**: なし（`NoMatchingCondition` エラーのみ。UIではデフォルト分岐に相当）
- **Conditions**: `NumericLessThan` 比較のチェーン。1-100 のランダム値に対し、累積パーセンテージの閾値で分岐。各条件は前の値に加算したパーセンテージを比較値とする
- **Errors**: `NoMatchingCondition`（UIのデフォルト分岐に相当）

### 動作原理

1. 内部で 1-100 のランダム数値を生成
2. Conditions の `NumericLessThan` を順に評価
3. 例: 20% / 40% / 40% の場合:
   - `NumericLessThan 20` → 分岐A（0-20）
   - `NumericLessThan 60` → 分岐B（21-60）
   - それ以外 → デフォルト（61-100）

### 制約

- Inbound flow、Transfer flow、Customer queue flow で使用可能
- Hold flow、Whisper flow では使用不可

### JSON例（抜粋）

```json
{
  "Identifier": "uuid",
  "Type": "DistributeByPercentage",
  "Parameters": {},
  "Transitions": {
    "NextAction": "",
    "Conditions": [
      {
        "NextAction": "branch-a-uuid",
        "Condition": {
          "Operator": "NumberLessThan",
          "Operands": ["20"]
        }
      },
      {
        "NextAction": "branch-b-uuid",
        "Condition": {
          "Operator": "NumberLessThan",
          "Operands": ["60"]
        }
      }
    ],
    "Errors": [
      {
        "NextAction": "default-uuid",
        "ErrorType": "NoMatchingCondition"
      }
    ]
  }
}
```

---

## ActionType 早見表

| UI ブロック名 | ActionType | パラメータオブジェクト空? | Conditions? |
|-------------|------------|----------------------|-------------|
| Set working queue | `UpdateContactTargetQueue` | No | なし |
| Check queue status | `CheckMetricData` | No | あり（Number比較） |
| Check staffing | `CheckMetricData` | No | あり（NumberGreaterThan 0） |
| Get metrics | `GetMetricData` | No | なし |
| Check hours of operation | `CheckHoursOfOperation` | No | あり（True/False必須） |
| Set routing criteria | `UpdateRoutingCriteria` | No | なし |
| Change routing priority / age | `UpdateContactRoutingBehavior` | No | なし |
| Set customer queue flow | `UpdateContactEventHooks` | No | なし |
| Distribute by percentage | `DistributeByPercentage` | Yes (`{}`) | あり（NumericLessThan チェーン） |
