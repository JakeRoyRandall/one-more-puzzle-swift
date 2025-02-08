#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-reachable.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
output=$($bin --reachable cold --max-steps 2 --json)
JSON_RESULT="$output" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r['max_steps'] == 2
assert [(x['word'], x['distance']) for x in r['reachable']] == [
    ('cold', 0), ('bold', 1), ('cord', 1), ('gold', 1),
    ('bald', 2), ('card', 2), ('good', 2), ('word', 2),
]
assert r['count'] == 8
PY
filtered=$($bin --reachable cold --max-steps 1 --avoid cord)
printf '%s\n' "$filtered" | grep -F 'bold'
if printf '%s\n' "$filtered" | grep -q 'cord'; then exit 1; fi
zero=$($bin --reachable cold --max-steps 0 --json)
JSON_RESULT="$zero" python3 -c 'import json,os; r=json.loads(os.environ["JSON_RESULT"]); assert r["reachable"]==[{"word":"cold","distance":0}]'
for command in '--reachable cold' '--reachable cold --max-steps -1' '--reachable cold --max-steps 33'; do
    set +e
    # shellcheck disable=SC2086
    $bin $command >/dev/null 2>/dev/null
    status=$?
    set -e
    test "$status" -eq 2
done
set +e
$bin --reachable cold --max-steps 1 --avoid cold >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
$bin --reachable cold --max-steps 1 --neighbors cold >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'reachable tests passed: distances, stable sorting, zero bound, avoid, required bound, conflicts'
