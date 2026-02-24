#!/usr/bin/env bash
# validate.sh — Amazon Connect フローJSONのバリデーション
# Usage:
#   ./scripts/validate.sh <flow.json>                              # ローカルチェックのみ
#   ./scripts/validate.sh --api --instance-id $ID --profile $P flow.json  # ローカル + Connect API
#
# ローカルチェック:
#   - JSON構文 / Version / StartAction / 遷移先参照整合性 / UUID形式 / DisconnectParticipant
#   - ActionTypeホワイトリスト / DTMFConfigurationフィールド名 / パラメータ名検証
#   - 孤立ブロック検出 / デッドエンド検出
#
# APIバリデーション (--api):
#   - ローカルチェック通過後、create-contact-flow --status SAVED で下書き作成
#   - 成功 → 下書きを自動削除
#   - 失敗 → InvalidContactFlowException のエラー内容を表示

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

ERRORS=0
FLOW_FILE=""
API_VALIDATE=false
INSTANCE_ID=""
AWS_PROFILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --api) API_VALIDATE=true; shift ;;
    --instance-id) INSTANCE_ID="$2"; shift 2 ;;
    --profile) AWS_PROFILE="$2"; shift 2 ;;
    -*) echo "Unknown option: $1"; exit 1 ;;
    *) FLOW_FILE="$1"; shift ;;
  esac
done

if [[ -z "$FLOW_FILE" ]]; then
  echo "Usage: $0 [--api --instance-id <id> --profile <profile>] <flow.json>"
  exit 1
fi

if [[ ! -f "$FLOW_FILE" ]]; then
  echo -e "${RED}Error: File not found: $FLOW_FILE${NC}"
  exit 1
fi

if [[ "$API_VALIDATE" == true ]]; then
  if [[ -z "$INSTANCE_ID" ]]; then
    echo -e "${RED}Error: --instance-id is required with --api${NC}"
    exit 1
  fi
fi

echo "Validating: $FLOW_FILE"
echo "---"

# All checks via Python
FLOW_FILE_PATH="$FLOW_FILE" python3 << 'PYEOF'
import json, sys, re, os

RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[0;33m'
NC = '\033[0m'

errors = 0

def p(msg): print(f"{GREEN}✓{NC} {msg}")
def f(msg):
    global errors
    errors += 1
    print(f"{RED}✗{NC} {msg}")
def w(msg): print(f"{YELLOW}⚠{NC} {msg}")

fpath = os.environ['FLOW_FILE_PATH']

# 1. JSON syntax
try:
    with open(fpath) as fp:
        data = json.load(fp)
    p("JSON syntax valid")
except json.JSONDecodeError as e:
    f(f"JSON syntax error: {e}")
    sys.exit(1)

# 2. Version
ver = data.get('Version', '')
if ver == '2019-10-30':
    p("Version: 2019-10-30")
else:
    f(f"Version should be '2019-10-30', got '{ver}'")

# 3. Actions
actions = data.get('Actions', [])
ids = {a['Identifier'] for a in actions}
p(f"{len(actions)} actions found")

# 4. StartAction
start = data.get('StartAction', '')
if start and start in ids:
    p("StartAction references valid Action")
elif not start:
    f("StartAction is empty")
else:
    f(f"StartAction '{start}' not found in Actions")

# 5. UUID format
UUID_RE = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', re.I)
bad = [a['Identifier'] for a in actions if not UUID_RE.match(a['Identifier'])]
if bad:
    for u in bad:
        f(f"Non-UUID Identifier: {u}")
else:
    p(f"All Identifiers are valid UUIDs")

# 6. Transition integrity
missing = set()
for a in actions:
    t = a.get('Transitions', {})
    for ref in ([t.get('NextAction')] +
                [c.get('NextAction') for c in t.get('Conditions', [])] +
                [e.get('NextAction') for e in t.get('Errors', [])]):
        if ref and ref not in ids:
            missing.add(ref)
if missing:
    for m in missing:
        f(f"Transition references missing Action: {m}")
else:
    p("All transition references are valid")

# 7. DisconnectParticipant
if any(a['Type'] == 'DisconnectParticipant' for a in actions):
    p("Flow has DisconnectParticipant")
else:
    w("No DisconnectParticipant found (may be intentional for sub-flows)")

# 8. Non-Disconnect actions must have Transitions
for a in actions:
    if a['Type'] != 'DisconnectParticipant' and not a.get('Transitions'):
        f(f"Action {a['Identifier']} ({a['Type']}) has no Transitions")

# 9. Position metadata
meta = data.get('Metadata', {}).get('ActionMetadata', {})
no_pos = [aid for aid in ids if aid not in meta or 'position' not in meta.get(aid, {})]
if no_pos:
    w(f"{len(no_pos)} action(s) missing position metadata")
else:
    p("All actions have position metadata")

# --- New checks (v0.3.0) ---

# 10. ActionType whitelist check
KNOWN_TYPES = {
    'MessageParticipant',
    'GetParticipantInput',
    'UpdateContactTargetQueue',
    'TransferContactToQueue',
    'DisconnectParticipant',
    'InvokeLambdaFunction',
    'UpdateContactAttributes',
    'Compare',
    'InvokeFlowModule',
    'CheckHoursOfOperation',
    'Loop',
    'UpdateContactRecordingBehavior',
    'UpdateContactRecordingAndAnalyticsBehavior',
    'UpdateContactTextToSpeechVoice',
    'UpdateFlowLoggingBehavior',
    'TransferToPhoneNumber',
}
DEPRECATED_TYPES = {
    'SetVoice': 'UpdateContactTextToSpeechVoice',
    'SetLoggingBehavior': 'UpdateFlowLoggingBehavior',
}
type_ok = True
for a in actions:
    atype = a.get('Type', '')
    if atype in DEPRECATED_TYPES:
        f(f"Deprecated ActionType '{atype}' in {a['Identifier']} — use '{DEPRECATED_TYPES[atype]}' instead")
        type_ok = False
    elif atype not in KNOWN_TYPES:
        w(f"Unknown ActionType '{atype}' in {a['Identifier']}")
        type_ok = False
if type_ok:
    p("All ActionTypes are valid")

# 11. DTMFConfiguration field name validation
dtmf_ok = True
DEPRECATED_DTMF = {
    'FinishOnKey': 'InputTerminationSequence',
    'InactivityTimeLimitSeconds': 'InterdigitTimeLimitSeconds',
}
for a in actions:
    dtmf = a.get('Parameters', {}).get('DTMFConfiguration', {})
    for old_name, new_name in DEPRECATED_DTMF.items():
        if old_name in dtmf:
            f(f"Deprecated DTMFConfiguration field '{old_name}' in {a['Identifier']} — use '{new_name}' instead")
            dtmf_ok = False
if dtmf_ok:
    p("DTMFConfiguration field names are valid")

# 12. UpdateFlowLoggingBehavior parameter validation
for a in actions:
    if a.get('Type') == 'UpdateFlowLoggingBehavior':
        params = a.get('Parameters', {})
        if 'LoggingBehavior' in params:
            f(f"Deprecated parameter 'LoggingBehavior' in {a['Identifier']} — use 'FlowLoggingBehavior' instead")
        val = params.get('FlowLoggingBehavior', '')
        if val and val not in ('Enabled', 'Disabled'):
            f(f"Invalid FlowLoggingBehavior value '{val}' in {a['Identifier']} — must be 'Enabled' or 'Disabled'")

# 13. UpdateContactTextToSpeechVoice parameter validation
for a in actions:
    if a.get('Type') == 'UpdateContactTextToSpeechVoice':
        params = a.get('Parameters', {})
        if 'GlobalVoice' in params:
            f(f"Deprecated parameter 'GlobalVoice' in {a['Identifier']} — use 'TextToSpeechVoice' instead")

# 14. StartAction should be UpdateFlowLoggingBehavior
if start and start in ids:
    start_action = next((a for a in actions if a['Identifier'] == start), None)
    if start_action and start_action.get('Type') == 'UpdateFlowLoggingBehavior':
        p("StartAction is UpdateFlowLoggingBehavior (best practice)")
    else:
        start_type = start_action.get('Type', 'unknown') if start_action else 'unknown'
        w(f"StartAction is '{start_type}' — consider using UpdateFlowLoggingBehavior as the first action")

# 15. ActionType-specific Transitions validation
TRANSITIONS_SPEC = {
    'Loop': {'conditions_required': True, 'required_conditions': {'ContinueLooping', 'DoneLooping'}},
    'CheckHoursOfOperation': {'conditions_required': True, 'required_conditions': {'True', 'False'}},
    'Compare': {'conditions_required': True, 'required_conditions': None},
}
NO_CONDITIONS_TYPES = {
    'MessageParticipant', 'UpdateContactTargetQueue', 'TransferContactToQueue',
    'DisconnectParticipant', 'InvokeLambdaFunction', 'UpdateContactAttributes',
    'InvokeFlowModule', 'UpdateContactRecordingBehavior',
    'UpdateContactRecordingAndAnalyticsBehavior', 'UpdateContactTextToSpeechVoice',
    'UpdateFlowLoggingBehavior', 'TransferToPhoneNumber',
}
transitions_ok = True
for a in actions:
    atype = a.get('Type', '')
    t = a.get('Transitions', {})
    conds = t.get('Conditions', [])
    cond_values = {c.get('Condition', {}).get('Operands', [''])[0] for c in conds}

    if atype in TRANSITIONS_SPEC:
        spec = TRANSITIONS_SPEC[atype]
        if spec['required_conditions'] is not None:
            missing = spec['required_conditions'] - cond_values
            if missing:
                f(f"{atype} in {a['Identifier']} missing required Conditions: {', '.join(sorted(missing))}")
                transitions_ok = False
        else:
            if not conds:
                f(f"{atype} in {a['Identifier']} requires at least one Condition")
                transitions_ok = False

    if atype == 'GetParticipantInput':
        store_input = a.get('Parameters', {}).get('StoreInput', 'False')
        if store_input == 'True' and conds:
            f(f"GetParticipantInput with StoreInput=True in {a['Identifier']} must not have Conditions")
            transitions_ok = False

    if atype in NO_CONDITIONS_TYPES and conds:
        f(f"{atype} in {a['Identifier']} does not support Conditions")
        transitions_ok = False

if transitions_ok:
    p("ActionType-specific Transitions constraints are valid")

# --- New checks (v0.6.0) ---

# 16. Orphan block detection — actions not referenced by StartAction or any Transition
referenced_ids = set()
if start:
    referenced_ids.add(start)
for a in actions:
    t = a.get('Transitions', {})
    next_action = t.get('NextAction')
    if next_action:
        referenced_ids.add(next_action)
    for c in t.get('Conditions', []):
        c_next = c.get('NextAction')
        if c_next:
            referenced_ids.add(c_next)
    for e in t.get('Errors', []):
        e_next = e.get('NextAction')
        if e_next:
            referenced_ids.add(e_next)

orphans = ids - referenced_ids
if orphans:
    for orphan_id in sorted(orphans):
        orphan_type = next((a['Type'] for a in actions if a['Identifier'] == orphan_id), 'unknown')
        f(f"Orphan block: {orphan_id} ({orphan_type}) is not referenced by any Transition or StartAction")
else:
    p("No orphan blocks detected")

# 17. Dead-end detection — non-DisconnectParticipant actions with no NextAction and no Conditions
dead_ends = []
for a in actions:
    if a.get('Type') == 'DisconnectParticipant':
        continue
    t = a.get('Transitions', {})
    has_next = bool(t.get('NextAction'))
    has_conditions = bool(t.get('Conditions', []))
    if not has_next and not has_conditions:
        dead_ends.append(a)

if dead_ends:
    for a in dead_ends:
        f(f"Dead-end: {a['Identifier']} ({a['Type']}) has no NextAction and no Conditions")
else:
    p("No dead-end blocks detected")

print("---")
if errors == 0:
    print(f"{GREEN}All checks passed!{NC}")
else:
    print(f"{RED}{errors} error(s) found.{NC}")
    sys.exit(1)
PYEOF

LOCAL_EXIT=$?
if [[ $LOCAL_EXIT -ne 0 ]]; then
  exit $LOCAL_EXIT
fi

# --- API Validation ---
if [[ "$API_VALIDATE" == true ]]; then
  echo ""
  echo "=== Connect API Validation ==="

  FLOW_NAME="__validation_$(date +%Y%m%d_%H%M%S)__"
  CONTENT="$(cat "$FLOW_FILE")"

  # Build AWS CLI args
  AWS_ARGS=(
    connect create-contact-flow
    --instance-id "$INSTANCE_ID"
    --name "$FLOW_NAME"
    --type CONTACT_FLOW
    --content "$CONTENT"
    --status SAVED
  )
  if [[ -n "$AWS_PROFILE" ]]; then
    AWS_ARGS+=(--profile "$AWS_PROFILE")
  fi

  # Attempt to create draft flow
  API_OUTPUT=""
  API_EXIT=0
  API_OUTPUT=$(aws "${AWS_ARGS[@]}" 2>&1) || API_EXIT=$?

  if [[ $API_EXIT -eq 0 ]]; then
    pass "Connect API validation passed"

    # Extract flow ID and delete the draft
    FLOW_ID=$(echo "$API_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['ContactFlowId'])" 2>/dev/null || true)
    if [[ -n "$FLOW_ID" ]]; then
      DELETE_ARGS=(
        connect delete-contact-flow
        --instance-id "$INSTANCE_ID"
        --contact-flow-id "$FLOW_ID"
      )
      if [[ -n "$AWS_PROFILE" ]]; then
        DELETE_ARGS+=(--profile "$AWS_PROFILE")
      fi

      if aws "${DELETE_ARGS[@]}" 2>/dev/null; then
        pass "Draft flow deleted (ID: $FLOW_ID)"
      else
        warn "Draft flow created but could not be deleted (ID: $FLOW_ID)"
        warn "Manually delete: aws connect delete-contact-flow --instance-id $INSTANCE_ID --contact-flow-id $FLOW_ID"
      fi
    fi
  else
    fail "Connect API validation failed"
    echo -e "${RED}--- API Error ---${NC}"
    echo "$API_OUTPUT"
    echo -e "${RED}--- End API Error ---${NC}"
    exit 1
  fi

  echo "---"
  echo -e "${GREEN}All checks passed (local + API)!${NC}"
fi
