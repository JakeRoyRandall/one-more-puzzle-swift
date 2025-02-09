#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-challenges.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
list=$($bin --list-challenges)
test "$(printf '%s\n' "$list" | wc -l | tr -d ' ')" -eq 8
printf '%s\n' "$list" | grep -F 'quarantine · The cold chain · max 4'
for id in quarantine couch raincheck golden woodwork boldmove nightshift samepage; do
    fixture=$($bin --challenge "$id" --json)
    JSON_RESULT="$fixture" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r['steps'] == r['max_steps']
PY
done
result=$($bin --challenge quarantine --json)
JSON_RESULT="$result" python3 - <<'PY'
import json, os
r = json.loads(os.environ['JSON_RESULT'])
assert r['challenge'] == 'quarantine' and r['via'] == 'cord' and r['steps'] == 4
PY
plain=$($bin --challenge boldmove)
printf '%s\n' "$plain" | grep -F 'CHALLENGE BOLDMOVE · Bold move'
printf '%s\n' "$plain" | grep -F 'BOLD → WORD · 3 steps'
html=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-challenge-html.XXXXXX")
trap 'rm -f "$bin" "$html"' EXIT
rm -f "$html"
"$bin" --challenge quarantine --html "$html" >/dev/null
grep -F 'Challenge: The cold chain' "$html"
grep -F 'A warm-up exercise for a chilly inbox.' "$html"
grep -F 'max 4 steps' "$html"
grep -F 'via cord' "$html"
rm -f "$html"
"$bin" --challenge golden --html "$html" >/dev/null
grep -F 'avoid mail' "$html"
play=$(printf 'hint\ncord\nhint\ncard\nhint\nward\nhint\nwarm\n' | "$bin" --challenge quarantine --play)
printf '%s\n' "$play" | grep -F 'RULES · max 4 steps · via cord'
printf '%s\n' "$play" | grep -F 'Hint: try cord'
printf '%s\n' "$play" | grep -F 'VICTORY · 4 valid moves'
set +e
$bin --challenge couch --from cat --to dog >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
$bin --list-challenges --json >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
$bin --challenge couch --json --play </dev/null >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
$bin --self-test --challenge couch >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'challenge tests passed: listing, constrained JSON, title/plain route, conflict errors'
