#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-worksheet.XXXXXX")
html=$(mktemp "${TMPDIR:-/tmp}/one-more-puzzle-worksheet-html.XXXXXX")
trap 'rm -f "$bin" "$html"' EXIT
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
rm -f "$html"
"$bin" --challenge quarantine --worksheet --html "$html" >/dev/null
grep -F 'Challenge: The cold chain' "$html"
grep -F 'via cord' "$html"
grep -F 'max 4 steps' "$html"
grep -F '<details><summary>Answer key' "$html"
grep -F 'cold → cord → card → ward → warm' "$html"
grep -F 'word blank">____' "$html"
rm -f "$html"
"$bin" --from cold --to warm --via cord --avoid gold --max-steps 4 --worksheet --html "$html" >/dev/null
grep -F 'Constraints:' "$html"
grep -F 'via cord' "$html"
grep -F 'avoid gold' "$html"
set +e
"$bin" --neighbors cold --worksheet >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
"$bin" --reachable cold --max-steps 1 --worksheet >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
"$bin" --from cold --to warm --worksheet >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
set +e
"$bin" --from cold --to warm --worksheet --json >/dev/null 2>/dev/null
status=$?
set -e
test "$status" -eq 2
echo 'worksheet tests passed: blanks, answer key, challenge constraints, mode errors'
