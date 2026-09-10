import XCTest
#if SWIFT_PACKAGE
@testable import LumaLiltCore
#else
@testable import LumaLilt
#endif

final class PuzzleTests: XCTestCase {
    func testDestinationTapUsesShortestLegalShiftForEveryBoardSize() {
        for size in 3...5 {
            for source in 0..<(size * size) {
                for destination in 0..<(size * size) {
                    let shifts = Puzzle.shifts(from: source, to: destination, size: size)
                    let aligned = source != destination && (source / size == destination / size || source % size == destination % size)
                    XCTAssertEqual(!shifts.isEmpty, aligned)
                    guard aligned else { continue }
                    XCTAssertLessThanOrEqual(shifts.count, size / 2)
                    var board = Array(0..<(size * size))
                    for move in shifts { Puzzle.rotate(&board, size: size, move: move) }
                    XCTAssertEqual(board[destination], source)
                    XCTAssertEqual(board.sorted(), Array(0..<(size * size)))
                    for move in shifts.reversed() { Puzzle.rotate(&board, size: size, move: move.inverse) }
                    XCTAssertEqual(board, Array(0..<(size * size)))
                }
            }
        }
    }

    func testDestinationTapRejectsInvalidInputAndWrapsBothWays() {
        XCTAssertTrue(Puzzle.shifts(from: -1, to: 0, size: 3).isEmpty)
        XCTAssertTrue(Puzzle.shifts(from: 0, to: 9, size: 3).isEmpty)
        XCTAssertTrue(Puzzle.shifts(from: 0, to: 0, size: 0).isEmpty)
        XCTAssertEqual(Puzzle.shifts(from: 0, to: 4, size: 5), [Move(axis: .row, index: 0, direction: -1)])
        XCTAssertEqual(Puzzle.shifts(from: 4, to: 0, size: 5), [Move(axis: .row, index: 0, direction: 1)])
        XCTAssertEqual(Puzzle.shifts(from: 0, to: 20, size: 5), [Move(axis: .column, index: 0, direction: -1)])
        XCTAssertEqual(Puzzle.shifts(from: 20, to: 0, size: 5), [Move(axis: .column, index: 0, direction: 1)])
    }

    func testDestinationTapPreservesMoveCountingUndoAndHintRoute() throws {
        var puzzle = Puzzle(difficulty: .deep, seed: 19)
        let original = puzzle
        let shifts = Puzzle.shifts(from: 0, to: 2, size: 5)
        for move in shifts { puzzle.play(move) }
        XCTAssertEqual(puzzle.moves, 2)
        XCTAssertTrue(puzzle.isValid)
        let restored = try JSONDecoder().decode(Puzzle.self, from: JSONEncoder().encode(puzzle))
        XCTAssertEqual(restored, puzzle)
        for _ in shifts { puzzle.undo() }
        XCTAssertEqual(puzzle, original)
        for move in shifts { puzzle.play(move) }
        for _ in 0..<puzzle.route.count { puzzle.hint() }
        XCTAssertTrue(puzzle.solved)
        XCTAssertTrue(puzzle.isValid)
    }

    func testEnhancedPalettesIncreaseAdjacentColorSeparation() {
        func distance(_ a: TileAppearance, _ b: TileAppearance) -> Double {
            abs(a.red - b.red) + abs(a.green - b.green) + abs(a.blue - b.blue)
        }
        for size in 3...5 {
            for palette in ["Tide", "Dusk", "Ember"] {
                for value in 0..<(size * size) {
                    let enhanced = TileAppearance.color(value, size: size, palette: palette, enhanced: true)
                    let original = TileAppearance.color(value, size: size, palette: palette, enhanced: false)
                    for channel in [enhanced.red, enhanced.green, enhanced.blue] {
                        XCTAssertTrue((0...1).contains(channel))
                    }
                    var neighbors: [Int] = []
                    if value % size < size - 1 { neighbors.append(value + 1) }
                    if value / size < size - 1 { neighbors.append(value + size) }
                    for neighbor in neighbors {
                        XCTAssertGreaterThan(distance(enhanced, TileAppearance.color(neighbor, size: size, palette: palette, enhanced: true)),
                                             distance(original, TileAppearance.color(neighbor, size: size, palette: palette, enhanced: false)))
                    }
                }
            }
        }
    }

    func testRowWrapAndInverse() {
        var board = Array(0..<9)
        let right = Move(axis: .row, index: 1, direction: 1)
        Puzzle.rotate(&board, size: 3, move: right)
        XCTAssertEqual(board, [0, 1, 2, 5, 3, 4, 6, 7, 8])
        Puzzle.rotate(&board, size: 3, move: right.inverse)
        XCTAssertEqual(board, Array(0..<9))
    }

    func testColumnWrapAndInvalidInput() {
        var board = Array(0..<9)
        Puzzle.rotate(&board, size: 3, move: Move(axis: .column, index: 0, direction: -1))
        XCTAssertEqual(board, [3, 1, 2, 6, 4, 5, 0, 7, 8])
        let before = board
        Puzzle.rotate(&board, size: 3, move: Move(axis: .row, index: 8, direction: 1))
        XCTAssertEqual(board, before)
    }

    func testEveryGeneratedBoardHasKnownSolution() {
        for difficulty in Difficulty.allCases {
            for seed in UInt64(0)..<200 {
                var puzzle = Puzzle(difficulty: difficulty, seed: seed)
                XCTAssertFalse(puzzle.solved)
                XCTAssertTrue(puzzle.isValid)
                let bound = puzzle.route.count
                for _ in 0..<bound { puzzle.hint() }
                XCTAssertTrue(puzzle.solved, "Unsolved: \(difficulty) / \(seed)")
                XCTAssertTrue(puzzle.isValid)
            }
        }
    }

    func testHintsAfterArbitraryPlayerMoves() {
        var puzzle = Puzzle(difficulty: .deep, seed: 19)
        var generator = SeededGenerator(seed: 42)
        for _ in 0..<100 {
            puzzle.play(Move(axis: generator.number(2) == 0 ? .row : .column,
                             index: generator.number(5), direction: generator.number(2) == 0 ? -1 : 1))
        }
        XCTAssertTrue(puzzle.isValid)
        for _ in 0..<puzzle.route.count { puzzle.hint() }
        XCTAssertTrue(puzzle.solved)
    }

    func testUndoAndRestartRetainAssistance() {
        var puzzle = Puzzle(difficulty: .flowing, seed: 100)
        let original = puzzle.board
        puzzle.hint()
        puzzle.undo()
        XCTAssertEqual(puzzle.board, original)
        XCTAssertEqual(puzzle.moves, 0)
        XCTAssertEqual(puzzle.hints, 1)
        puzzle.restart()
        XCTAssertEqual(puzzle.board, original)
        XCTAssertEqual(puzzle.hints, 1)
        XCTAssertTrue(puzzle.undoStack.isEmpty)
    }

    func testDailyIsStableAcrossTimeZonesAndWithinUTCDay() {
        let parser = ISO8601DateFormatter()
        let a = parser.date(from: "2026-09-09T00:00:00Z")!
        let b = parser.date(from: "2026-09-09T23:59:59Z")!
        let c = parser.date(from: "2026-09-10T00:00:00Z")!
        XCTAssertEqual(Puzzle.dailyPuzzle(on: a), Puzzle.dailyPuzzle(on: b))
        XCTAssertNotEqual(Puzzle.dailyPuzzle(on: a).id, Puzzle.dailyPuzzle(on: c).id)
        XCTAssertEqual(Puzzle.dayKey(a), "2026-09-09")
    }

    func testSaveRoundTripAndWinDeduplication() throws {
        var puzzle = Puzzle(difficulty: .gentle, seed: 7)
        for _ in 0..<puzzle.route.count { puzzle.hint() }
        var progress = Progress()
        progress.free = puzzle
        progress.record(puzzle)
        progress.record(puzzle)
        let restored = try JSONDecoder().decode(Progress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(restored.free, puzzle)
        XCTAssertEqual(restored.wins.count, 1)
        XCTAssertEqual(restored.unassisted, 0)
        XCTAssertTrue(restored.free!.isValid)
    }

    func testUndoIsBoundedAndSolvedPuzzleCannotChange() {
        var puzzle = Puzzle(difficulty: .deep, seed: 123)
        for _ in 0..<130 { puzzle.play(Move(axis: .row, index: 0, direction: 1)) }
        XCTAssertLessThanOrEqual(puzzle.undoStack.count, 100)
        for _ in 0..<puzzle.route.count { puzzle.hint() }
        let solved = puzzle
        puzzle.undo()
        puzzle.play(Move(axis: .row, index: 0, direction: 1))
        XCTAssertEqual(puzzle, solved)
    }
}
