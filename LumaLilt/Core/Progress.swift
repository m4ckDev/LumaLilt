import Foundation

struct Win: Codable, Identifiable {
    let id: String
    let difficulty: Difficulty
    let moves: Int
    let hints: Int
    let daily: Bool
    let finishedAt: Date
}

struct Progress: Codable {
    var version = 1
    var free: Puzzle?
    var daily: Puzzle?
    var wins: [Win] = []

    mutating func record(_ puzzle: Puzzle, date: Date = Date()) {
        guard puzzle.solved, !wins.contains(where: { $0.id == puzzle.id }) else { return }
        wins.append(Win(id: puzzle.id, difficulty: puzzle.difficulty, moves: puzzle.moves,
                        hints: puzzle.hints, daily: puzzle.daily, finishedAt: date))
    }
    var unassisted: Int { wins.filter { $0.hints == 0 }.count }
}
