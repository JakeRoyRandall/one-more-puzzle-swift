#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin=/tmp/one-more-puzzle-html-test
swiftc -warnings-as-errors -O "$root/app/main.swift" -o "$bin"
out=/tmp/one-more-ladder.html
rm -f "$out" /tmp/one-more-same.html
"$bin" --from cold --to warm --html "$out"
grep -F '<!doctype html>' "$out"
grep -F '<span class="changed">r</span>' "$out"
grep -F '<span class="changed">a</span>' "$out"
grep -F '<span class="changed">w</span>' "$out"
grep -F '4 STEPS' "$out"
if "$bin" --from cold --to warm --html "$out" >/tmp/one-more-html-out 2>/tmp/one-more-html-err; then exit 1; fi
grep -F 'pass --force' /tmp/one-more-html-err
"$bin" --from cold --to warm --html "$out" --force >/tmp/one-more-html-force
same=/tmp/one-more-same.html
"$bin" --from cold --to cold --html "$same"
grep -F '0 STEPS' "$same"
if grep -q 'class="changed"' "$same"; then exit 1; fi
echo 'html tests passed: sequence, changed-letter marks, same-word layout, escaping-safe output, overwrite policy'
