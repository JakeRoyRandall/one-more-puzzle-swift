#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-json.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
output=$($bin --from cold --to warm --json)
JSON_RESULT="$output" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r == {
    'schema_version': 1,
    'from': 'cold',
    'to': 'warm',
    'steps': 4,
    'words': ['cold', 'cord', 'card', 'ward', 'warm'],
}
PY
same=$($bin --from COLD --to cold --json)
JSON_RESULT="$same" python3 -c 'import json,os; r=json.loads(os.environ["JSON_RESULT"]); assert r["steps"]==0 and r["words"]==["cold"]'
set +e
$bin --from cold --to warm --json --play </dev/null >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'json tests passed: parsed shortest route, same-word route, incompatible mode status'
