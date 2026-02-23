#!/usr/bin/env bash
# deploy.sh — Amazon Connect フローのデプロイヘルパー
#
# Usage:
#   # 新規作成
#   ./scripts/deploy.sh create <flow.json> --name "Flow Name" --instance-id <ID> --profile <PROFILE>
#
#   # 既存更新
#   ./scripts/deploy.sh update <flow.json> --flow-id <FLOW_ID> --instance-id <ID> --profile <PROFILE>
#
# ローカルバリデーション → レイアウト → デプロイの3ステップを自動実行する。
# デプロイ時に Connect API が自動でフロー内容をバリデーションする（InvalidContactFlowException で失敗通知）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

MODE=""
FLOW_FILE=""
FLOW_NAME=""
FLOW_ID=""
INSTANCE_ID=""
PROFILE=""
SKIP_VALIDATE=false
SKIP_LAYOUT=false

# Parse arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <create|update> <flow.json> [options]"
  exit 1
fi

MODE="$1"; shift
FLOW_FILE="$1"; shift

while [[ $# -gt 0 ]]; do
  case $1 in
    --name) FLOW_NAME="$2"; shift 2 ;;
    --flow-id) FLOW_ID="$2"; shift 2 ;;
    --instance-id) INSTANCE_ID="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --skip-validate) SKIP_VALIDATE=true; shift ;;
    --skip-layout) SKIP_LAYOUT=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$INSTANCE_ID" ]]; then
  echo -e "${RED}Error: --instance-id is required${NC}"
  exit 1
fi

if [[ ! "$INSTANCE_ID" =~ ^[a-z0-9-]+$ ]]; then
  echo -e "${RED}Error: Invalid --instance-id format${NC}"
  exit 1
fi

if [[ -n "$PROFILE" && ! "$PROFILE" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo -e "${RED}Error: Invalid --profile format${NC}"
  exit 1
fi

if [[ ! -f "$FLOW_FILE" ]]; then
  echo -e "${RED}Error: File not found: $FLOW_FILE${NC}"
  exit 1
fi

# Step 1: Local validation
if ! $SKIP_VALIDATE; then
  echo "Step 1: ローカルバリデーション..."
  bash "$SCRIPT_DIR/validate.sh" "$FLOW_FILE"
  echo ""
fi

# Step 2: Layout
if ! $SKIP_LAYOUT; then
  echo "Step 2: レイアウト座標付与..."
  python3 "$SCRIPT_DIR/layout.py" "$FLOW_FILE"
  echo ""
fi

# Step 3: Deploy
# Note: Connect API validates flow content automatically on create/update (--status PUBLISHED).
#       InvalidContactFlowException is returned if validation fails.
echo "Step 3: デプロイ..."
case "$MODE" in
  create)
    if [[ -z "$FLOW_NAME" ]]; then
      echo -e "${RED}Error: --name is required for create${NC}"
      exit 1
    fi
    aws_create_args=(
      connect create-contact-flow
      --instance-id "$INSTANCE_ID"
      --name "$FLOW_NAME"
      --type CONTACT_FLOW
      --content "$(cat "$FLOW_FILE")"
    )
    [[ -n "$PROFILE" ]] && aws_create_args+=(--profile "$PROFILE")
    if RESULT=$(aws "${aws_create_args[@]}" 2>&1); then
      echo -e "${GREEN}✓${NC} フロー作成完了"
      echo "$RESULT" | python3 -m json.tool
    else
      echo -e "${RED}✗${NC} フロー作成失敗（InvalidContactFlowException の場合はフローJSONを修正してください）"
      echo "$RESULT"
      exit 1
    fi
    ;;
  update)
    if [[ -z "$FLOW_ID" ]]; then
      echo -e "${RED}Error: --flow-id is required for update${NC}"
      exit 1
    fi
    if [[ ! "$FLOW_ID" =~ ^[a-z0-9-]+$ ]]; then
      echo -e "${RED}Error: Invalid --flow-id format${NC}"
      exit 1
    fi
    aws_update_args=(
      connect update-contact-flow-content
      --instance-id "$INSTANCE_ID"
      --contact-flow-id "$FLOW_ID"
      --content "$(cat "$FLOW_FILE")"
    )
    [[ -n "$PROFILE" ]] && aws_update_args+=(--profile "$PROFILE")
    if aws "${aws_update_args[@]}" 2>&1; then
      echo -e "${GREEN}✓${NC} フロー更新完了 (Flow ID: $FLOW_ID)"
    else
      echo -e "${RED}✗${NC} フロー更新失敗（InvalidContactFlowException の場合はフローJSONを修正してください）"
      exit 1
    fi
    ;;
  *)
    echo -e "${RED}Error: Mode must be 'create' or 'update'${NC}"
    exit 1
    ;;
esac
