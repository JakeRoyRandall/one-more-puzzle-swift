import Foundation

let wordBank = [
    "bail", "bald", "ball", "bold", "cold", "cord", "card", "ward", "warm", "worm", "word", "wood", "good", "gold", "game", "gain", "main", "mail", "rain",
    "cat", "cot", "cog", "dog", "dot", "hot", "hog", "log", "lot", "sin", "sun", "same"
].sorted()

enum LadderError: LocalizedError {
    case missingOption(String), unknownWord(String), wrongLength, nonASCII, unreachable
    case tooManyAvoid, avoidedEndpoint(String), invalidMaxSteps
    var errorDescription: String? {
        switch self {
        case .missingOption(let option): return "missing \(option); try --from COLD --to WARM"
        case .unknownWord(let word): return "\(word) is not in the built-in couch-club word list"
        case .wrongLength: return "FROM and TO must have the same length"
        case .nonASCII: return "use simple ASCII letters for FROM and TO"
        case .unreachable: return "no ladder connects those words in the curated word list"
        case .tooManyAvoid: return "at most 32 --avoid words are allowed"
        case .avoidedEndpoint(let word): return "cannot avoid ladder endpoint " + word
        case .invalidMaxSteps: return "--max-steps must be an integer from 0 through 32"
        }
    }
}

func neighbors(of word: String, in words: [String] = wordBank) -> [String] {
    words.filter { candidate in
        candidate.count == word.count && candidate != word && zip(candidate, word).filter { $0 != $1 }.count == 1
    }.sorted()
}

func reachableWords(from start: String, maxSteps: Int, avoiding: Set<String>) -> [(String, Int)] {
    var distances = [start: 0]
    var queue = [start]
    var head = 0
    while head < queue.count {
        let current = queue[head]
        head += 1
        let distance = distances[current]!
        if distance >= maxSteps { continue }
        for next in neighbors(of: current) where !avoiding.contains(next) && distances[next] == nil {
            distances[next] = distance + 1
            queue.append(next)
        }
    }
    return distances.map { ($0.key, $0.value) }.sorted { left, right in
        left.1 == right.1 ? left.0 < right.0 : left.1 < right.1
    }
}

struct LadderState: Hashable {
    let word: String
    let visitedVia: Bool
}

func ladder(from start: String, to goal: String, in words: [String] = wordBank, avoiding: Set<String> = [], maxSteps: Int? = nil, via: String? = nil, viaAlreadyVisited: Bool = false) throws -> [String] {
    let from = start.lowercased(), target = goal.lowercased()
    let waypoint = via?.lowercased()
    guard from.allSatisfy({ $0.isASCII && $0.isLetter }) && target.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
    guard from.count == target.count else { throw LadderError.wrongLength }
    if avoiding.contains(from) { throw LadderError.avoidedEndpoint(from) }
    if avoiding.contains(target) { throw LadderError.avoidedEndpoint(target) }
    guard words.contains(from) else { throw LadderError.unknownWord(from) }
    guard words.contains(target) else { throw LadderError.unknownWord(target) }
    if let waypoint {
        guard waypoint.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
        guard words.contains(waypoint) else { throw LadderError.unknownWord(waypoint) }
        if avoiding.contains(waypoint) { throw LadderError.avoidedEndpoint(waypoint) }
    }
    if from == target && (waypoint == nil || waypoint == from) { return [from] }
    let initial = LadderState(word: from, visitedVia: viaAlreadyVisited || waypoint == from)
    var queue = [initial], head = 0, parent: [LadderState: LadderState?] = [initial: nil], depth = [initial: 0]
    while head < queue.count {
        let current = queue[head]; head += 1
        if current.word == target && (waypoint == nil || current.visitedVia) {
            var path = [current.word]; var cursor = current
            while let previous = parent[cursor] ?? nil { path.append(previous.word); cursor = previous }
            return path.reversed()
        }
        if let maxSteps, depth[current, default: 0] >= maxSteps { continue }
        for nextWord in neighbors(of: current.word, in: words) where !avoiding.contains(nextWord) {
            let next = LadderState(word: nextWord, visitedVia: current.visitedVia || nextWord == waypoint)
            if parent[next] == nil {
                parent[next] = current; queue.append(next)
                depth[next] = depth[current, default: 0] + 1
            }
        }
    }
    throw LadderError.unreachable
}

func parse(_ arguments: [String]) throws -> (String, String, Bool, Bool, String?, Bool, Bool, Set<String>, Int?, String?, String?, String?) {
    var from: String?, to: String?, via: String?, neighborsWord: String?, reachableWord: String?, selfTest = false, play = false, html: String?, force = false, json = false, avoiding = Set<String>(), maxSteps: Int?; var index = 0
    while index < arguments.count {
        switch arguments[index] {
        case "--from": index += 1; guard index < arguments.count else { throw LadderError.missingOption("--from") }; from = arguments[index]
        case "--to": index += 1; guard index < arguments.count else { throw LadderError.missingOption("--to") }; to = arguments[index]
        case "--via":
            index += 1
            guard index < arguments.count else { throw LadderError.missingOption("--via") }
            guard via == nil else { throw LadderError.missingOption("duplicate --via") }
            let word = arguments[index].lowercased()
            guard word.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
            guard wordBank.contains(word) else { throw LadderError.unknownWord(word) }
            via = word
        case "--neighbors":
            index += 1
            guard index < arguments.count else { throw LadderError.missingOption("--neighbors") }
            guard neighborsWord == nil else { throw LadderError.missingOption("duplicate --neighbors") }
            let word = arguments[index].lowercased()
            guard word.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
            guard wordBank.contains(word) else { throw LadderError.unknownWord(word) }
            neighborsWord = word
        case "--reachable":
            index += 1
            guard index < arguments.count else { throw LadderError.missingOption("--reachable") }
            guard reachableWord == nil else { throw LadderError.missingOption("duplicate --reachable") }
            let word = arguments[index].lowercased()
            guard word.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
            guard wordBank.contains(word) else { throw LadderError.unknownWord(word) }
            reachableWord = word
        case "--self-test": selfTest = true
        case "--play": play = true
        case "--json": json = true
        case "--avoid":
            index += 1
            guard index < arguments.count else { throw LadderError.missingOption("--avoid") }
            let word = arguments[index].lowercased()
            guard word.allSatisfy({ $0.isASCII && $0.isLetter }) else { throw LadderError.nonASCII }
            guard wordBank.contains(word) else { throw LadderError.unknownWord(word) }
            if !avoiding.contains(word) {
                if avoiding.count == 32 { throw LadderError.tooManyAvoid }
                avoiding.insert(word)
            }
        case "--max-steps":
            index += 1
            guard index < arguments.count, let value = Int(arguments[index]), (0...32).contains(value) else { throw LadderError.invalidMaxSteps }
            if maxSteps != nil { throw LadderError.missingOption("duplicate --max-steps") }
            maxSteps = value
        case "--html": index += 1; guard index < arguments.count else { throw LadderError.missingOption("--html") }; html = arguments[index]
        case "--force": force = true
        case "--help", "-h": print("Usage: one-more-puzzle --from WORD --to WORD [--via WORD] [--avoid WORD ...] [--max-steps N] [--play | --html FILE | --json] [--force]\n       one-more-puzzle --neighbors WORD [--avoid WORD ...] [--json]\n       one-more-puzzle --reachable WORD --max-steps N [--avoid WORD ...] [--json]\nFinds shortest one-letter ladders in a small built-in couch-club word list. Use --neighbors to inspect sorted one-letter neighbors, --reachable to list words within a finite step bound, --via for a same-length curated waypoint, --avoid to exclude curated words, --max-steps for a 0..32 path bound, --play to submit words interactively, --html to export a printable page, or --json for machine-readable output. Words are case-insensitive; no network or system dictionary is used."); exit(0)
        default: throw LadderError.missingOption("unknown option \(arguments[index])")
        }
        index += 1
    }
    if selfTest && from == nil && to == nil { return ("cat", "cat", true, false, nil, false, false, avoiding, maxSteps, via, neighborsWord, reachableWord) }
    if let reachableWord {
        guard let maxSteps else { throw LadderError.invalidMaxSteps }
        if from != nil || to != nil || play || html != nil || via != nil || neighborsWord != nil { throw LadderError.missingOption("--reachable cannot be combined with solver options") }
        return (reachableWord, reachableWord, false, false, nil, false, json, avoiding, maxSteps, nil, nil, reachableWord)
    }
    if let neighborsWord {
        if from != nil || to != nil || play || html != nil || via != nil || maxSteps != nil { throw LadderError.missingOption("--neighbors cannot be combined with solver options") }
        return (neighborsWord, neighborsWord, false, false, nil, false, json, avoiding, nil, nil, neighborsWord, nil)
    }
    guard let start = from else { throw LadderError.missingOption("--from") }
    guard let goal = to else { throw LadderError.missingOption("--to") }
    if play && html != nil { throw LadderError.missingOption("--play cannot be combined with --html") }
    if json && (play || html != nil) { throw LadderError.missingOption("--json cannot be combined with --play or --html") }
    return (start, goal, selfTest, play, html, force, json, avoiding, maxSteps, via, neighborsWord, reachableWord)
}

func jsonEscape(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}

func jsonLadder(_ path: [String], maxSteps: Int?, via: String?) -> String {
    let words = path.map { "\"\(jsonEscape($0))\"" }.joined(separator: ",")
    let limit = maxSteps.map(String.init) ?? "null"
    let waypoint = via.map { "\"\(jsonEscape($0))\"" } ?? "null"
    return "{\"schema_version\":1,\"from\":\"\(jsonEscape(path.first!))\",\"to\":\"\(jsonEscape(path.last!))\",\"via\":\(waypoint),\"steps\":\(path.count - 1),\"max_steps\":\(limit),\"words\":[\(words)]}"
}

func jsonNeighbors(_ word: String, _ neighbors: [String]) -> String {
    let values = neighbors.map { "\"\(jsonEscape($0))\"" }.joined(separator: ",")
    return "{\"schema_version\":1,\"word\":\"\(jsonEscape(word))\",\"neighbors\":[\(values)],\"count\":\(neighbors.count)}"
}

func jsonReachable(_ word: String, _ values: [(String, Int)], maxSteps: Int) -> String {
    let entries = values.map { "{\"word\":\"\(jsonEscape($0.0))\",\"distance\":\($0.1)}" }.joined(separator: ",")
    return "{\"schema_version\":1,\"word\":\"\(jsonEscape(word))\",\"max_steps\":\(maxSteps),\"reachable\":[\(entries)],\"count\":\(values.count)}"
}

func htmlEscape(_ value: String) -> String { value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "'", with: "&#39;") }
func htmlLadder(_ path: [String], maxSteps: Int? = nil) -> String {
    _ = maxSteps
    let tiles = path.enumerated().map { offset, word in
        let previous = offset > 0 ? Array(path[offset - 1]) : []
        let letters = Array(word).enumerated().map { index, letter in
            let marked = offset > 0 && index < previous.count && previous[index] != letter
            return marked ? "<span class=\"changed\">\(htmlEscape(String(letter)))</span>" : htmlEscape(String(letter))
        }.joined()
        return "<li><span class=\"step\">\(offset == 0 ? "START" : String(offset))</span><span class=\"word\">\(letters)</span></li>"
    }.joined(separator: "\n")
    return """
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One More Puzzle · \(htmlEscape(path.first!)) → \(htmlEscape(path.last!))</title><style> :root{--ink:#10271b;--green:#1c5b3a;--paper:#f6f2e7;--rule:#173b28}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font-family:Georgia,serif;background-image:repeating-linear-gradient(0deg,#10271b08 0,#10271b08 1px,transparent 1px,transparent 5px)}main{max-width:760px;margin:0 auto;padding:54px 34px}.mast{border-top:8px solid var(--green);border-bottom:3px solid var(--green);padding:18px 0 22px}.kicker{font:700 12px "Courier New",monospace;letter-spacing:.18em;color:var(--green)}h1{font-size:clamp(48px,9vw,88px);line-height:.82;letter-spacing:-.06em;margin:18px 0 12px}h1 em{color:var(--green);font-style:normal}.dek{font-size:18px;line-height:1.45;max-width:600px}.badge{display:inline-block;border:2px solid var(--green);padding:8px 10px;font:700 11px "Courier New",monospace;transform:rotate(-2deg)}ol{list-style:none;margin:34px 0;padding:0;border-left:3px solid var(--green)}li{display:flex;align-items:center;gap:18px;padding:11px 0 11px 20px}.step{width:58px;color:var(--green);font:700 11px "Courier New",monospace}.word{font:700 clamp(30px,7vw,58px)/1 "Courier New",monospace;letter-spacing:.08em}.changed{color:white;background:var(--green);padding:0 .08em}.note{border-top:2px solid var(--green);padding-top:16px;font:12px/1.5 "Courier New",monospace}.foot{margin-top:42px;border-top:1px solid var(--rule);padding-top:12px;font:11px/1.5 "Courier New",monospace}@media print{body{background:#fff}main{padding:20px}.foot{margin-top:20px}}</style></head><body><main><header class="mast"><div class="kicker">ONE MORE PUZZLE · COUCH CLUB EDITION</div><h1>Change one<br><em>letter.</em></h1><p class="dek">A newspaper puzzle for a stay-at-home year. Follow the shortest route from <b>\(htmlEscape(path.first!.uppercased()))</b> to <b>\(htmlEscape(path.last!.uppercased()))</b>.</p><span class="badge">\(path.count - 1) STEPS</span></header><ol>\(tiles)</ol><p class="note">Green tiles mark the letter changed on each step. The word bank is a small curated puzzle set, not a complete English dictionary.</p><footer class="foot">Created retrospectively in September 2026 as a fictional 2020-inspired art project. No network or external assets.</footer></main></body></html>
"""
}

func playGame(from start: String, to target: String, avoiding: Set<String>, maxSteps: Int?, via: String?) {
    let from = start.lowercased(), target = target.lowercased()
    var history = [from], validMoves = 0, hints = 0
    print("COUCH CLUB PLAY · \(from.uppercased()) → \(target.uppercased())")
    print("Enter a one-letter neighbor, 'hint', 'undo', or 'quit'.")
    if from == target && (via == nil || via == from) { print("VICTORY · 0 valid moves · 0 hints · \(from)"); return }
    while let line = readLine() {
        let command = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if command == "quit" || command == "q" { print("Session ended · \(validMoves) valid moves · \(hints) hints"); return }
        if command == "undo" || command == "u" { if history.count > 1 { history.removeLast(); print("Back to \(history.last!) · \(validMoves) valid moves") } else { print("Already at the start; nothing to undo.") }; continue }
        if command == "hint" || command == "h" { do { let used = history.count - 1; let remaining = maxSteps.map { max(0, $0 - used) }; let visited = via.map { history.contains($0) } ?? false; let route = try ladder(from: history.last!, to: target, avoiding: avoiding, maxSteps: remaining, via: via, viaAlreadyVisited: visited); if route.count > 1 { print("Hint: try \(route[1])") } else { print("You are already there.") }; hints += 1 } catch { print("No hint route within the remaining step budget; undo to restore steps.") }; continue }
        if let maxSteps, history.count - 1 >= maxSteps { print("Step budget exhausted; undo or quit."); continue }
        guard !avoiding.contains(command), wordBank.contains(command), neighbors(of: history.last!).contains(command) else { print("Invalid move; choose a word in the bank differing by one letter. You have not advanced."); continue }
        history.append(command); validMoves += 1
        if command == target && (via == nil || history.contains(via!)) { print("VICTORY · \(validMoves) valid moves · \(hints) hints · \(history.joined(separator: " → "))"); return }
        if command == target { print("At the destination, but the required via word has not been visited.") }
        print("Now at \(command) · \(validMoves) valid moves")
    }
    print("Input ended · \(validMoves) valid moves · \(hints) hints")
}

func selfTest() -> Bool {
    guard htmlEscape("<tag & \"quote\">") == "&lt;tag &amp; &quot;quote&quot;&gt;" else { return false }
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
    if let word = options.11 {
        let limit = options.8!
        if options.7.contains(word) { throw LadderError.avoidedEndpoint(word) }
        let values = reachableWords(from: word, maxSteps: limit, avoiding: options.7)
        if options.6 {
            print(jsonReachable(word, values, maxSteps: limit))
        } else {
            print("REACHABLE FROM \(word.uppercased()) · MAX \(limit) STEPS · \(values.count) WORDS")
            for (value, distance) in values { print("\(distance) \(value)") }
        }
        exit(0)
    }
    if let word = options.10 {
        let listed = neighbors(of: word).filter { !options.7.contains($0) }
        if options.6 {
            print(jsonNeighbors(word, listed))
        } else {
            print("NEIGHBORS FOR \(word.uppercased()) · \(listed.count)")
            if !listed.isEmpty { print(listed.joined(separator: "\n")) }
        }
        exit(0)
    }
    if options.7.contains(options.0.lowercased()) { throw LadderError.avoidedEndpoint(options.0.lowercased()) }
    if options.7.contains(options.1.lowercased()) { throw LadderError.avoidedEndpoint(options.1.lowercased()) }
    if let via = options.9, options.7.contains(via) { throw LadderError.avoidedEndpoint(via) }
    if options.3 { _ = try ladder(from: options.0, to: options.1, avoiding: options.7, via: options.9); playGame(from: options.0, to: options.1, avoiding: options.7, maxSteps: options.8, via: options.9); exit(0) }
    let path = try ladder(from: options.0, to: options.1, avoiding: options.7, maxSteps: options.8, via: options.9)
    if options.6 { print(jsonLadder(path, maxSteps: options.8, via: options.9)); exit(0) }
    if let htmlPath = options.4 {
        if FileManager.default.fileExists(atPath: htmlPath) && !options.5 { throw NSError(domain: "OneMorePuzzle", code: 5, userInfo: [NSLocalizedDescriptionKey: "HTML file already exists; pass --force to overwrite"]) }
        do { try htmlLadder(path, maxSteps: options.8).write(toFile: htmlPath, atomically: true, encoding: .utf8) } catch { throw NSError(domain: "OneMorePuzzle", code: 6, userInfo: [NSLocalizedDescriptionKey: "could not write HTML file: \(error.localizedDescription)"]) }
        print("HTML written to \(htmlPath) · \(path.count - 1) steps")
        exit(0)
    }
    print("COUCH CLUB WORD LADDER")
    print("\(path.first!.uppercased()) → \(path.last!.uppercased()) · \(path.count - 1) steps")
    print(path.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
} catch { fputs("One More Puzzle: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)\n", stderr); exit(2) }
