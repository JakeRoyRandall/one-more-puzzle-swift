#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-max.XXXXXX")
trap 'rm -f "$bin"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
same=$($bin --from cold --to cold --max-steps 0 --json)
JSON_RESULT="$same" python3 -c 'import json,os; r=json.loads(os.environ["JSON_RESULT"]); assert r["steps"]==0 and r["max_steps"]==0'
set +e
$bin --from cold --to warm --max-steps 3 >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
for value in -1 33; do
    set +e
    $bin --from cold --to warm --max-steps "$value" >/dev/null 2>/dev/null
    status=$?
    set -e
    test "$status" -eq 2
done
play=$(printf 'cot\ncog\nhint\ndog\nundo\nundo\nhint\nquit\n' | "$bin" --from cat --to dog --play --max-steps 2)
printf '%s\n' "$play" | grep -F 'No hint route within the remaining step budget'
printf '%s\n' "$play" | grep -F 'Step budget exhausted; undo or quit.'
printf '%s\n' "$play" | grep -F 'Back to cot · 2 valid moves'
echo 'max-steps tests passed: zero, too-short, bounds, play exhaustion, undo budget restore'
