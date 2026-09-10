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
    let route: [Move]
    let moves: Int
}

struct Puzzle: Codable, Equatable, Identifiable {
    let id: String
    let difficulty: Difficulty
    let seed: UInt64
    let daily: Bool
    private(set) var board: [Int]
    private(set) var route: [Move]
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
        board = Array(0..<(difficulty.size * difficulty.size))
        route = []
        var generator = SeededGenerator(seed: seed)
        for _ in 0..<difficulty.scrambleCount {
            var move: Move
            repeat {
                move = Move(axis: generator.number(2) == 0 ? .row : .column,
                            index: generator.number(difficulty.size),
                            direction: generator.number(2) == 0 ? -1 : 1)
            } while route.last == move.inverse
            Self.rotate(&board, size: size, move: move)
            route.append(move)
        }
        if solved {
            let move = Move(axis: .row, index: 0, direction: 1)
            Self.rotate(&board, size: size, move: move)
            route.append(move)
        }
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

    private mutating func remember() {
        undoStack.append(Turn(board: board, route: route, moves: moves))
        if undoStack.count > 100 { undoStack.removeFirst() }
    }

    mutating func play(_ move: Move) {
        guard !solved, move.isValid(size: size) else { return }
        remember()
        Self.rotate(&board, size: size, move: move)
        moves += 1
        if route.last == move.inverse { route.removeLast() } else { route.append(move) }
    }

    /// A destination chooses a cyclic shift, never an arbitrary tile swap.
    /// Keep each single-position shift in the existing move/undo history.
    static func shifts(from source: Int, to destination: Int, size: Int) -> [Move] {
        guard size >= 2, (0..<(size * size)).contains(source),
              (0..<(size * size)).contains(destination), source != destination else { return [] }
        let axis: Axis
        let index: Int
        let distance: Int
        if source / size == destination / size {
            axis = .row
            index = source / size
            distance = destination % size - source % size
        } else if source % size == destination % size {
            axis = .column
            index = source % size
            distance = destination / size - source / size
        } else { return [] }
        let forward = (distance + size) % size
        let backward = size - forward
        let direction = forward <= backward ? 1 : -1
        return Array(repeating: Move(axis: axis, index: index, direction: direction),
                     count: min(forward, backward))
    }

    /// Retraces a known valid route. It guarantees progress along that route, not an optimal solution.
    mutating func hint() {
        guard !solved, let move = route.last else { return }
        remember()
        Self.rotate(&board, size: size, move: move.inverse)
        route.removeLast()
        moves += 1
        hints += 1
    }

    mutating func undo() {
        guard !solved, let turn = undoStack.popLast() else { return }
        board = turn.board
        route = turn.route
        moves = turn.moves
        // Assistance remains recorded even if the hinted move is undone.
    }

    mutating func restart() {
        let usedHints = hints
        self = Puzzle(id: id, difficulty: difficulty, seed: seed, daily: daily)
        hints = usedHints
    }

    var isValid: Bool {
        guard !id.isEmpty, moves >= 0, hints >= 0, undoStack.count <= 100,
              board.sorted() == Array(0..<(size * size)),
              route.allSatisfy({ $0.isValid(size: size) }) else { return false }
        func reconstruct(_ path: [Move]) -> [Int] {
            var result = Array(0..<(size * size))
            for move in path { Self.rotate(&result, size: size, move: move) }
            return result
        }
        guard reconstruct(route) == board else { return false }
        return undoStack.allSatisfy {
            $0.moves >= 0 && $0.moves <= moves &&
            $0.route.allSatisfy { $0.isValid(size: size) } && reconstruct($0.route) == $0.board
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
