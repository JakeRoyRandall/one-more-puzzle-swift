# One More Puzzle

One More Puzzle is an offline Swift word-ladder CLI for an imaginary 2020 couch club. Give it two words of the same length; it finds a shortest path where each step changes exactly one letter. Ties are resolved by stable lexicographic neighbor order.

Created September 2026 retrospectively as a fictional art project, not a historical work record. The built-in list is a small curated puzzle set, not a complete English dictionary.

Build and run:

```sh
cd app
swiftc -warnings-as-errors -O main.swift -o one-more-puzzle
./one-more-puzzle --from COLD --to WARM
./one-more-puzzle --self-test
```

The program uses Swift Foundation and no packages, network access, system dictionaries, or external data. Errors explain unknown words, mismatched lengths, non-ASCII input, and unreachable pairs.
