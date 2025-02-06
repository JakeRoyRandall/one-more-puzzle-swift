#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-avoid.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
changed=$($bin --from cold --to warm --avoid cord --json)
JSON_RESULT="$changed" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r['words'] == ['cold', 'gold', 'good', 'wood', 'word', 'ward', 'warm']
assert 'cord' not in r['words']
PY
set +e
$bin --from cat --to dog --avoid cot >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
hint=$(printf 'hint\nquit\n' | "$bin" --from cold --to warm --play --avoid cord)
printf '%s\n' "$hint" | grep -F 'Hint: try gold'
set +e
$bin --from cold --to warm --avoid notaword >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
duplicate=$($bin --from cold --to warm --avoid cord --avoid CORD --json)
JSON_RESULT="$duplicate" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r['words'][0] == 'cold' and 'cord' not in r['words']
PY
set +e
$bin --from cold --to warm --avoid cold >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'avoid tests passed: changed route, blocked route, hint, unknown, idempotent duplicate, endpoint errors'
