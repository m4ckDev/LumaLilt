import Foundation

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case gentle, flowing, deep
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var size: Int { self == .gentle ? 3 : self == .flowing ? 4 : 5 }
    var scrambleCount: Int { self == .gentle ? 5 : self == .flowing ? 10 : 16 }
}

enum Axis: String, Codable { case row, column }

struct Move: Codable, Equatable {
    let axis: Axis
    let index: Int
    let direction: Int
    var inverse: Move { Move(axis: axis, index: index, direction: -direction) }
    func isValid(size: Int) -> Bool { (0..<size).contains(index) && (direction == 1 || direction == -1) }
}

/// Explicit, stable generator: daily puzzles do not depend on Swift's randomized hashValue.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func number(_ upperBound: Int) -> Int { Int(next() % UInt64(upperBound)) }
}

struct Turn: Codable, Equatable {
    let board: [Int]
    let moves: Int
}

struct TileSwap: Equatable {
    let source: Int
    let destination: Int
}

struct Puzzle: Codable, Equatable, Identifiable {
    let id: String
    let difficulty: Difficulty
    let seed: UInt64
    let daily: Bool
    private(set) var board: [Int]
    private(set) var startingBoard: [Int]
    private(set) var undoStack: [Turn] = []
    private(set) var moves = 0
    private(set) var hints = 0
    var size: Int { difficulty.size }
    var solved: Bool { board == Array(0..<(size * size)) }
    var matched: Int { board.enumerated().filter { $0.offset == $0.element }.count }

    init(id: String = UUID().uuidString, difficulty: Difficulty, seed: UInt64, daily: Bool = false) {
        self.id = id
        self.difficulty = difficulty
        self.seed = seed
        self.daily = daily
        var generator = SeededGenerator(seed: seed)
        var tiles = Array(0..<(difficulty.size * difficulty.size))
        for index in stride(from: tiles.count - 1, through: 1, by: -1) {
            tiles.swapAt(index, generator.number(index + 1))
        }
        if tiles == Array(0..<tiles.count) { tiles.swapAt(0, 1) }
        board = tiles
        startingBoard = tiles
    }

    /// Swap exactly two positions. One user action creates one undo entry.
    mutating func swap(_ source: Int, _ destination: Int) {
        guard !solved, source != destination,
              board.indices.contains(source), board.indices.contains(destination) else { return }
        remember()
        board.swapAt(source, destination)
        moves += 1
    }

    /// Place a misplaced tile home, without disturbing any tile already home.
    /// Each hint strictly increases the number of correct positions.
    var suggestedSwap: TileSwap? {
        guard let destination = board.indices.first(where: { board[$0] != $0 }),
              let source = board.firstIndex(of: destination) else { return nil }
        return TileSwap(source: source, destination: destination)
    }

    @discardableResult
    mutating func hint() -> TileSwap? {
        guard let suggestion = suggestedSwap else { return nil }
        swap(suggestion.source, suggestion.destination)
        hints += 1
        return suggestion
    }

    private mutating func remember() {
        undoStack.append(Turn(board: board, moves: moves))
        if undoStack.count > 100 { undoStack.removeFirst() }
    }

    mutating func undo() {
        guard !solved, let turn = undoStack.popLast() else { return }
        board = turn.board
        moves = turn.moves
        // Assistance remains recorded even when its move is undone.
    }

    mutating func restart() {
        board = startingBoard
        moves = 0
        undoStack = []
    }

    var isValid: Bool {
        let expected = Array(0..<(size * size))
        return !id.isEmpty && moves >= 0 && hints >= 0 && undoStack.count <= 100 &&
            board.sorted() == expected && startingBoard.sorted() == expected &&
            undoStack.allSatisfy { $0.moves >= 0 && $0.moves <= moves && $0.board.sorted() == expected }
    }

    // Existing build 1–3 saves retain their exact boards, history, counters and IDs.
    // Unknown legacy `route` fields are ignored. Original seeds reconstruct Reset.
    private enum CodingKeys: String, CodingKey {
        case id, difficulty, seed, daily, board, startingBoard, undoStack, moves, hints, rulesVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .rulesVersion) ?? 1
        guard version == 1 || version == 2 else {
            throw DecodingError.dataCorruptedError(forKey: .rulesVersion, in: container,
                                                   debugDescription: "Unsupported puzzle rules version")
        }
        id = try container.decode(String.self, forKey: .id)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        seed = try container.decode(UInt64.self, forKey: .seed)
        daily = try container.decode(Bool.self, forKey: .daily)
        board = try container.decode([Int].self, forKey: .board)
        undoStack = try container.decode([Turn].self, forKey: .undoStack)
        moves = try container.decode(Int.self, forKey: .moves)
        hints = try container.decode(Int.self, forKey: .hints)
        if version == 1 { startingBoard = Self.legacyBoard(difficulty: difficulty, seed: seed) }
        else { startingBoard = try container.decode([Int].self, forKey: .startingBoard) }
        guard isValid else {
            throw DecodingError.dataCorruptedError(forKey: .board, in: container,
                                                   debugDescription: "Invalid puzzle save")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(2, forKey: .rulesVersion)
        try container.encode(id, forKey: .id)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(seed, forKey: .seed)
        try container.encode(daily, forKey: .daily)
        try container.encode(board, forKey: .board)
        try container.encode(startingBoard, forKey: .startingBoard)
        try container.encode(undoStack, forKey: .undoStack)
        try container.encode(moves, forKey: .moves)
        try container.encode(hints, forKey: .hints)
    }

    private static func legacyBoard(difficulty: Difficulty, seed: UInt64) -> [Int] {
        var result = Array(0..<(difficulty.size * difficulty.size))
        var route: [Move] = []
        var generator = SeededGenerator(seed: seed)
        for _ in 0..<difficulty.scrambleCount {
            var move: Move
            repeat {
                move = Move(axis: generator.number(2) == 0 ? .row : .column,
                            index: generator.number(difficulty.size),
                            direction: generator.number(2) == 0 ? -1 : 1)
            } while route.last == move.inverse
            rotate(&result, size: difficulty.size, move: move)
            route.append(move)
        }
        if result == Array(0..<result.count) {
            rotate(&result, size: difficulty.size, move: Move(axis: .row, index: 0, direction: 1))
        }
        return result
    }

    static func rotate(_ board: inout [Int], size: Int, move: Move) {
        guard move.isValid(size: size), board.count == size * size else { return }
        let old = board
        for position in 0..<size {
            let destination = (position + move.direction + size) % size
            if move.axis == .row {
                board[move.index * size + destination] = old[move.index * size + position]
            } else {
                board[destination * size + move.index] = old[position * size + move.index]
            }
        }
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func dailyPuzzle(on date: Date = Date()) -> Puzzle {
        let key = dayKey(date)
        let seed = key.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        return Puzzle(id: "daily-\(key)", difficulty: .flowing, seed: seed, daily: true)
    }
}
