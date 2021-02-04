#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-neighbors.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
output=$($bin --neighbors cold --json)
JSON_RESULT="$output" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r == {'schema_version': 1, 'word': 'cold', 'neighbors': ['bold', 'cord', 'gold'], 'count': 3}
PY
filtered=$($bin --neighbors cold --avoid cord)
printf '%s\n' "$filtered" | grep -F 'NEIGHBORS FOR COLD · 2'
printf '%s\n' "$filtered" | grep -F 'bold'
if printf '%s\n' "$filtered" | grep -q 'cord'; then exit 1; fi
empty=$($bin --neighbors same --avoid game --json)
JSON_RESULT="$empty" python3 -c 'import json,os; r=json.loads(os.environ["JSON_RESULT"]); assert r["neighbors"]==[] and r["count"]==0'
set +e
$bin --neighbors cold --from warm >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
$bin --neighbors cold --play >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'neighbors tests passed: stable JSON, avoid filtering, empty list, conflicts'
