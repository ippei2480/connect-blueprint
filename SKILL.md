---
name: connect-blueprint
description: >
  Design and generate Amazon Connect contact flow JSON from requirements or diagrams.
  Use when: (1) designing a new contact flow from scratch by gathering requirements,
  (2) converting draw.io/Mermaid diagrams or images into flow JSON,
  (3) deploying flows to AWS via CLI, (4) updating existing flows.
  Covers IVR menus, queue routing, Lambda integration, business hours checks, and flow modules.
license: MIT
compatibility: Requires AWS CLI with a valid profile (connect:* permissions). Python 3.8+ for layout.py.
metadata:
  author: ippei2480
  version: "0.2.0"
---

# connect-blueprint

## Overview

2つのモードで Amazon Connect コンタクトフローを生成する：

- **モードA（ゼロから設計）**: 要件ヒアリング → Mermaid設計図 → フローJSON → デプロイ
- **モードB（設計図から生成）**: draw.io/Mermaid/画像 → フローJSON → デプロイ

## Prerequisites

- AWS CLI + 有効なプロファイル（`aws sts get-caller-identity --profile <profile>` で確認）
- Connect インスタンスID（`aws connect list-instances --profile <profile>` で取得可）
- 必要IAM権限: `connect:*`

## Mode A: Design from Scratch

### Step 1: 要件ヒアリング

以下を確認する：
- 電話の目的・業種・主なユースケース
- IVR選択肢（番号と対応内容）
- 営業時間分岐の有無
- 外部システム連携（Lambda/DynamoDB等）
- 既存フローとの統合有無

**環境情報を取得してユーザーに見せる：**
```bash
# キュー一覧
aws connect list-queues --instance-id $INSTANCE_ID --queue-types STANDARD --profile $PROFILE

# プロンプト一覧
aws connect list-prompts --instance-id $INSTANCE_ID --profile $PROFILE

# Lambda一覧（Connect連携済み）
aws connect list-lambda-functions --instance-id $INSTANCE_ID --profile $PROFILE

# フローモジュール一覧
aws connect list-contact-flow-modules --instance-id $INSTANCE_ID --profile $PROFILE
```

実現不可能な要件があれば**この段階で明示してユーザーに伝える**。

### Step 2: Mermaid 設計図の生成

`references/mermaid_notation.md` の記法に従ってMermaid図を生成する。
生成後、必ずユーザーにレビューを依頼し承認を得てから次のステップへ。

### Step 3: フローJSON生成

Mermaidからフロー構造を解析してJSON（Actions配列 + Transitions）を生成する。
`references/flow_json_structure.md` の構造仕様に従う。
`references/action_types.md` で各ActionTypeのパラメータを確認する。

**position付与:**
```bash
python3 scripts/layout.py <flow.json>
```

### Step 4: Validate & Deploy

**IMPORTANT: Always validate before deploying. Never skip this step.**

#### Validate (required)
```bash
aws connect validate-contact-flow-content \
  --instance-id $INSTANCE_ID \
  --type CONTACT_FLOW \
  --content "$(cat flow.json)" \
  --profile $PROFILE
```
If validation returns errors, fix the flow JSON and re-validate before proceeding.
Only deploy after validation passes with no errors.

#### Deploy
```bash
# Create new flow
aws connect create-contact-flow \
  --instance-id $INSTANCE_ID \
  --name "Flow Name" \
  --type CONTACT_FLOW \
  --content "$(cat flow.json)" \
  --profile $PROFILE

# Update existing flow
aws connect update-contact-flow-content \
  --instance-id $INSTANCE_ID \
  --contact-flow-id $FLOW_ID \
  --content "$(cat flow.json)" \
  --profile $PROFILE
```

## Mode B: Convert from Diagram

入力形式に応じて処理：
- **Mermaid**: そのまま Step A-3 へ
- **draw.io XML**: ノード/エッジを抽出してMermaidに変換 → Step A-3 へ
- **画像**: Vision解析でフロー構造を読み取り → Mermaidに変換 → Step A-3 へ

変換後は必ずユーザーに確認してから進む。

## Key Constraints

- `position` は **`Metadata.ActionMetadata.<id>.position`** に入れる（Action直下のMetadataは Connect API が拒否する）
- `Identifier` は UUID v4 形式
- `Version` は `"2019-10-30"` 固定
- `StartAction` は必ず1つ
- 全Actionに `Transitions` 必須（`DisconnectParticipant` は空 `{}` でOK）

## Validation

デプロイ前に必ずバリデーションを実行する：

```bash
# ローカルバリデーション（JSON構造・参照整合性チェック）
./scripts/validate.sh flow.json

# AWS バリデーション（Connect APIによる完全チェック）
./scripts/validate.sh flow.json --aws --instance-id $INSTANCE_ID --profile $PROFILE
```

## Examples

`examples/` ディレクトリにサンプルフローあり（Mermaid図＋JSON付き）：

| ディレクトリ | ユースケース |
|-------------|-------------|
| `business-hours-routing/` | 営業時間内外振り分け |
| `callback-reservation/` | コールバック予約 |
| `nps-survey/` | 顧客満足度アンケート（NPS） |
| `vip-escalation/` | VIP顧客エスカレーション |
| `multilingual/` | 多言語対応（日本語/英語） |
| `inquiry-routing/` | 問い合わせ種別振り分け |

## Troubleshooting

### よくあるエラーと対処法

| エラー | 原因 | 対処 |
|--------|------|------|
| `Invalid flow content` | JSON構造の不備 | `./scripts/validate.sh` でチェック |
| `Position metadata in wrong location` | Action直下にMetadataを配置 | `Metadata.ActionMetadata.<id>.position` に移動 |
| `StartAction not found` | StartActionのIDがActions内に存在しない | UUIDの一致を確認 |
| `Queue not found` | キューARNが不正 | `aws connect list-queues` で正しいARNを取得 |
| `Lambda function not associated` | LambdaがConnectに未連携 | Connect管理画面でLambda関数を追加 |
| `Access denied` | IAM権限不足 | `connect:*` 権限をIAMポリシーに追加 |

### layout.py がエラーになる場合

- Python 3.8以上が必要
- 標準ライブラリのみ使用（追加インストール不要）
- 入力JSONが正しい構造か `validate.sh` で事前確認

## References

- Action Types詳細: `references/action_types.md`
- フローJSON構造: `references/flow_json_structure.md`
- Mermaid記法: `references/mermaid_notation.md`
- AWS CLIコマンド: `references/aws_cli_commands.md`
- レイアウトルール: `references/layout_rules.md`
- エラーハンドリング: `references/error_handling_patterns.md`
