# One More Puzzle

One More Puzzle is an offline Swift word-ladder CLI for an imaginary 2020 couch club. Give it two words of the same length; it finds a shortest path where each step changes exactly one letter. Ties are resolved by stable lexicographic neighbor order.

Created September 2026 retrospectively as a fictional art project, not a historical work record. The built-in list is a small curated puzzle set, not a complete English dictionary.

Build and run:

```sh
cd app
swiftc -warnings-as-errors -O main.swift -o one-more-puzzle
./one-more-puzzle --from COLD --to WARM
printf 'hint\ncord\ncard\nward\nwarm\n' | ./one-more-puzzle --from COLD --to WARM --play
./one-more-puzzle --from COLD --to WARM --html ladder.html
./one-more-puzzle --from COLD --to WARM --json
./one-more-puzzle --from COLD --to WARM --avoid CORD
./one-more-puzzle --from COLD --to WARM --max-steps 4
./one-more-puzzle --self-test
sh ../tests/test_play.sh
sh ../tests/test_html.sh
sh ../tests/test_json.sh
sh ../tests/test_avoid.sh
```

The program uses Swift Foundation and no packages, network access, system dictionaries, or external data. Errors explain unknown words, mismatched lengths, non-ASCII input, and unreachable pairs.

With `--play`, submit one next word per line. `hint` suggests the next shortest-path word without moving, `undo` returns to the previous word, and `quit` or EOF ends cleanly. Invalid moves do not advance the puzzle; a victory summary reports valid moves and hints.

`--html FILE` exports a standalone printable newspaper-style ladder page with one tile per word and the changed letter highlighted in forest green. It works for three-letter, four-letter, and same-word ladders, refuses to overwrite an existing file unless `--force` is supplied, and cannot be combined with `--play`.

`--json` prints one valid machine-readable object containing `schema_version`, `from`, `to`, `steps`, and the complete `words` array. It is mutually exclusive with `--play` and `--html`; the output describes this same curated shortest path and is not a dictionary or proof of linguistic optimality beyond the built-in word graph.

Repeat `--avoid WORD` (up to 32 unique words) to remove curated words from the graph. Exclusions apply to text, JSON, HTML, play moves, and hints; unknown, non-ASCII, and endpoint exclusions are errors. Repeating a word is harmless and counts once. The list is intentionally small, so avoiding a bridge may make a pair unreachable.

`--max-steps N` bounds the shortest path to `0..32` letter changes. A same-word puzzle succeeds with zero, while a route needing more steps is unreachable. In `--play`, undo restores the available budget; hints search only within the remaining steps, and an exhausted budget reports a clear message.
