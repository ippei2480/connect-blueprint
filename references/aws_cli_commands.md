# Connect Blueprint — AWS CLI コマンドリファレンス

## 環境情報の取得

```bash
# Connect インスタンス一覧
aws connect list-instances --profile $PROFILE

# キュー一覧
aws connect list-queues --instance-id $INSTANCE_ID --queue-types STANDARD --profile $PROFILE

# プロンプト一覧
aws connect list-prompts --instance-id $INSTANCE_ID --profile $PROFILE

# Lambda一覧（Connect連携済み）
aws connect list-lambda-functions --instance-id $INSTANCE_ID --profile $PROFILE

# フローモジュール一覧
aws connect list-contact-flow-modules --instance-id $INSTANCE_ID --profile $PROFILE

# 既存フロー一覧
aws connect list-contact-flows --instance-id $INSTANCE_ID --profile $PROFILE

# 営業時間一覧
aws connect list-hours-of-operations --instance-id $INSTANCE_ID --profile $PROFILE
```

## フロー操作

```bash
# フロー新規作成（2ステップ: SAVED → ACTIVE）
# Step 1: SAVED状態で作成
aws connect create-contact-flow \
  --instance-id $INSTANCE_ID \
  --name "フロー名" \
  --type CONTACT_FLOW \
  --content "$(cat flow.json)" \
  --status SAVED \
  --profile $PROFILE

# Step 2: ACTIVE状態に変更（$FLOW_ID は Step 1 の出力から取得）
aws connect update-contact-flow-metadata \
  --instance-id $INSTANCE_ID \
  --contact-flow-id $FLOW_ID \
  --contact-flow-state ACTIVE \
  --profile $PROFILE

# フロー更新
aws connect update-contact-flow-content \
  --instance-id $INSTANCE_ID \
  --contact-flow-id $FLOW_ID \
  --content "$(cat flow.json)" \
  --profile $PROFILE

# フロー詳細取得
aws connect describe-contact-flow \
  --instance-id $INSTANCE_ID \
  --contact-flow-id $FLOW_ID \
  --profile $PROFILE
```

> **Note:** `create-contact-flow` をデフォルト（PUBLISHED）で実行すると `InvalidContactFlowException` になる場合がある。`--status SAVED` で作成後、`update-contact-flow-metadata --contact-flow-state ACTIVE` で公開する2ステップ方式を推奨。

## フロータイプ

`--type` に指定可能な値：

| 値 | 説明 |
|----|------|
| `CONTACT_FLOW` | 標準コンタクトフロー |
| `CUSTOMER_QUEUE` | カスタマーキューフロー |
| `CUSTOMER_HOLD` | カスタマー保留フロー |
| `CUSTOMER_WHISPER` | カスタマーウィスパーフロー |
| `AGENT_HOLD` | エージェント保留フロー |
| `AGENT_WHISPER` | エージェントウィスパーフロー |
| `OUTBOUND_WHISPER` | アウトバウンドウィスパーフロー |
| `AGENT_TRANSFER` | エージェント転送フロー |
| `QUEUE_TRANSFER` | キュー転送フロー |
