#!/usr/bin/env bash
# validate.sh — Amazon Connect フローJSONのローカルバリデーション
# Usage: ./scripts/validate.sh <flow.json>
#
# ローカルチェック:
#   - JSON構文 / Version / StartAction / 遷移先参照整合性 / UUID形式 / DisconnectParticipant

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

while [[ $# -gt 0 ]]; do
  case $1 in
    -*) echo "Unknown option: $1"; exit 1 ;;
    *) FLOW_FILE="$1"; shift ;;
  esac
done

if [[ -z "$FLOW_FILE" ]]; then
  echo "Usage: $0 <flow.json>"
  exit 1
fi

if [[ ! -f "$FLOW_FILE" ]]; then
  echo -e "${RED}Error: File not found: $FLOW_FILE${NC}"
  exit 1
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

print("---")
if errors == 0:
    print(f"{GREEN}All checks passed!{NC}")
else:
    print(f"{RED}{errors} error(s) found.{NC}")
    sys.exit(1)
PYEOF
