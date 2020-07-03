import Foundation

let wordBank = [
    "bail", "bald", "ball", "bold", "cold", "cord", "card", "ward", "warm", "worm", "word", "wood", "good", "gold", "game", "gain", "main", "mail", "rain",
    "cat", "cot", "cog", "dog", "dot", "hot", "hog", "log", "lot", "sin", "sun", "same"
].sorted()

enum LadderError: LocalizedError {
    case missingOption(String), unknownWord(String), wrongLength, nonASCII, unreachable
    var errorDescription: String? {
        switch self {
        case .missingOption(let option): return "missing \(option); try --from COLD --to WARM"
        case .unknownWord(let word): return "\(word) is not in the built-in couch-club word list"
        case .wrongLength: return "FROM and TO must have the same length"
        case .nonASCII: return "use simple ASCII letters for FROM and TO"
        case .unreachable: return "no ladder connects those words in the curated word list"
        }
    }
}

func neighbors(of word: String, in words: [String] = wordBank) -> [String] {
    words.filter { candidate in
        candidate.count == word.count && candidate != word && zip(candidate, word).filter { $0 != $1 }.count == 1
    }.sorted()
}

func ladder(from start: String, to goal: String, in words: [String] = wordBank) throws -> [String] {
    let from = start.lowercased(), target = goal.lowercased()
    guard from.allSatisfy({ $0.isASCII && $0.isLetter }) && target.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
    guard from.count == target.count else { throw LadderError.wrongLength }
    guard words.contains(from) else { throw LadderError.unknownWord(from) }
    guard words.contains(target) else { throw LadderError.unknownWord(target) }
    if from == target { return [from] }
    var queue = [from], head = 0, parent: [String: String?] = [from: nil]
    while head < queue.count {
        let current = queue[head]; head += 1
        for next in neighbors(of: current, in: words) where parent[next] == nil {
            parent[next] = current; queue.append(next)
            if next == target {
                var path = [target]; var cursor = target
                while let previous = parent[cursor] ?? nil { path.append(previous); cursor = previous }
                return path.reversed()
            }
        }
    }
    throw LadderError.unreachable
}

func parse(_ arguments: [String]) throws -> (String, String, Bool) {
    var from: String?, to: String?, selfTest = false; var index = 0
    while index < arguments.count {
        switch arguments[index] {
        case "--from": index += 1; guard index < arguments.count else { throw LadderError.missingOption("--from") }; from = arguments[index]
        case "--to": index += 1; guard index < arguments.count else { throw LadderError.missingOption("--to") }; to = arguments[index]
        case "--self-test": selfTest = true
        case "--help", "-h": print("Usage: one-more-puzzle --from WORD --to WORD\nFinds a shortest one-letter ladder in a small built-in couch-club word list. Words are case-insensitive; no network or system dictionary is used."); exit(0)
        default: throw LadderError.missingOption("unknown option \(arguments[index])")
        }
        index += 1
    }
    if selfTest && from == nil && to == nil { return ("cat", "cat", true) }
    guard let start = from else { throw LadderError.missingOption("--from") }
    guard let goal = to else { throw LadderError.missingOption("--to") }
    return (start, goal, selfTest)
}

func selfTest() -> Bool {
    guard neighbors(of: "cold").contains("cord") else { return false }
    guard (try? ladder(from: "cold", to: "warm")) == ["cold", "cord", "card", "ward", "warm"] else { return false }
    guard (try? ladder(from: "cat", to: "cat")) == ["cat"] else { return false }
    guard (try? ladder(from: "cat", to: "dog")) != nil else { return false }
    guard (try? ladder(from: "cat", to: "sun")) == nil else { return false }
    guard (try? ladder(from: "cat", to: "cold")) == nil else { return false }
    guard (try? ladder(from: "cåt", to: "cat")) == nil else { return false }
    return true
}

do {
    let options = try parse(Array(CommandLine.arguments.dropFirst()))
    if options.2 { let passed = selfTest(); print(passed ? "self-tests passed: neighbors, stable BFS, cycles, same-word, unreachable, Unicode and length errors" : "self-tests failed"); exit(passed ? 0 : 1) }
    let path = try ladder(from: options.0, to: options.1)
    print("COUCH CLUB WORD LADDER")
    print("\(path.first!.uppercased()) → \(path.last!.uppercased()) · \(path.count - 1) steps")
    print(path.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
} catch { fputs("One More Puzzle: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)\n", stderr); exit(2) }
