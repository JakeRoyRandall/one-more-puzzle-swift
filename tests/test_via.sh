#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-via.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
via=$($bin --from cold --to warm --via cord --max-steps 4 --json)
JSON_RESULT="$via" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r['via'] == 'cord' and r['steps'] == 4
assert r['words'] == ['cold', 'cord', 'card', 'ward', 'warm']
PY
set +e
$bin --from cold --to warm --via cord --max-steps 3 >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
same=$($bin --from cold --to cold --via cold --json)
JSON_RESULT="$same" python3 -c 'import json,os; r=json.loads(os.environ["JSON_RESULT"]); assert r["steps"]==0 and r["via"]=="cold"'
play=$(printf 'cord\ncard\nward\nwarm\n' | "$bin" --from cold --to warm --play --via cord --max-steps 4)
printf '%s\n' "$play" | grep -F 'VICTORY · 4 valid moves'
hint=$(printf 'cord\nhint\nquit\n' | "$bin" --from cold --to warm --play --via cord)
printf '%s\n' "$hint" | grep -F 'Hint: try card'
set +e
$bin --from cold --to warm --via cord --avoid cord >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
$bin --from cold --to warm --via notaword >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'via tests passed: waypoint route, shared bound, endpoint, play victory, avoid and unknown errors'
