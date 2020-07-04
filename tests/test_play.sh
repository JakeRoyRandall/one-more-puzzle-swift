#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=/tmp/one-more-puzzle-play-test
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
output=$(printf 'nope\nhint\ncot\nundo\ncot\ncog\ndog\n' | "$bin" --from cat --to dog --play)
printf '%s\n' "$output" | grep -F 'Invalid move; choose a word'
printf '%s\n' "$output" | grep -F 'Hint: try cot'
printf '%s\n' "$output" | grep -F 'Back to cat'
printf '%s\n' "$output" | grep -F 'VICTORY · 4 valid moves · 1 hints'
same=$($bin --from COLD --to cold --play </dev/null)
printf '%s\n' "$same" | grep -F 'VICTORY · 0 valid moves · 0 hints'
if "$bin" --from cat --to sun --play </dev/null >/tmp/one-more-unreachable.out 2>/tmp/one-more-unreachable.err; then exit 1; fi
grep -F 'no ladder connects' /tmp/one-more-unreachable.err
echo 'play tests passed: invalid move, hint, undo, victory, same-word, endpoint status'
