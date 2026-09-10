import XCTest
#if SWIFT_PACKAGE
@testable import LumaLiltCore
#else
@testable import LumaLilt
#endif

final class PuzzleTests: XCTestCase {
    func testSwapChangesOnlyChosenPositionsForEveryPairAndSize() {
        for difficulty in Difficulty.allCases {
            let original = Puzzle(difficulty: difficulty, seed: 42)
            for source in original.board.indices {
                for destination in original.board.indices where source != destination {
                    var puzzle = original
                    puzzle.swap(source, destination)
                    XCTAssertEqual(puzzle.board[destination], original.board[source])
                    XCTAssertEqual(puzzle.board[source], original.board[destination])
                    for index in puzzle.board.indices where index != source && index != destination {
                        XCTAssertEqual(puzzle.board[index], original.board[index])
                    }
                    XCTAssertEqual(puzzle.moves, 1)
                    XCTAssertEqual(puzzle.undoStack.count, 1)
                    XCTAssertTrue(puzzle.isValid)
                    puzzle.undo()
                    XCTAssertEqual(puzzle, original)
                }
            }
        }
    }

    func testInvalidOrRepeatedSelectionDoesNothing() {
        var puzzle = Puzzle(difficulty: .gentle, seed: 4)
        let original = puzzle
        puzzle.swap(-1, 0)
        puzzle.swap(0, 9)
        puzzle.swap(0, 0)
        XCTAssertEqual(puzzle, original)
    }

    func testHintsSolve600BoardsWithoutDisturbingCorrectTiles() {
        for difficulty in Difficulty.allCases {
            for seed in UInt64(0)..<200 {
                var puzzle = Puzzle(difficulty: difficulty, seed: seed)
                XCTAssertFalse(puzzle.solved)
                XCTAssertTrue(puzzle.isValid)
                for _ in 0..<(puzzle.size * puzzle.size - 1) where !puzzle.solved {
                    let before = puzzle.board
                    let matched = puzzle.matched
                    XCTAssertNotNil(puzzle.hint())
                    XCTAssertGreaterThan(puzzle.matched, matched)
                    for index in before.indices where before[index] == index {
                        XCTAssertEqual(puzzle.board[index], index)
                    }
                }
                XCTAssertTrue(puzzle.solved, "Unsolved: \(difficulty) / \(seed)")
                XCTAssertTrue(puzzle.isValid)
            }
        }
    }

    func testHintsAfterArbitrarySwapsStillMakeProgress() {
        var puzzle = Puzzle(difficulty: .deep, seed: 19)
        var generator = SeededGenerator(seed: 42)
        for _ in 0..<100 { puzzle.swap(generator.number(25), generator.number(25)) }
        while !puzzle.solved {
            let before = puzzle.matched
            puzzle.hint()
            XCTAssertGreaterThan(puzzle.matched, before)
        }
        XCTAssertTrue(puzzle.isValid)
    }

    func testHintUndoAndRestartRetainAssistance() {
        var puzzle = Puzzle(difficulty: .flowing, seed: 100)
        let original = puzzle.board
        puzzle.hint()
        puzzle.undo()
        XCTAssertEqual(puzzle.board, original)
        XCTAssertEqual(puzzle.moves, 0)
        XCTAssertEqual(puzzle.hints, 1)
        puzzle.swap(0, 15)
        puzzle.restart()
        XCTAssertEqual(puzzle.board, original)
        XCTAssertEqual(puzzle.hints, 1)
        XCTAssertTrue(puzzle.undoStack.isEmpty)
    }

    func testDailyIsStableWithinUTCDay() {
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
        while !puzzle.solved { puzzle.hint() }
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

    func testInProgressRoundTripPreservesUndoAndStartingBoard() throws {
        var puzzle = Puzzle(difficulty: .deep, seed: 10)
        puzzle.swap(0, 24)
        let saved = puzzle
        puzzle.hint()
        var restored = try JSONDecoder().decode(Puzzle.self, from: JSONEncoder().encode(puzzle))
        restored.undo()
        XCTAssertEqual(restored.board, saved.board)
        XCTAssertEqual(restored.moves, saved.moves)
        XCTAssertEqual(restored.startingBoard, saved.startingBoard)
        XCTAssertEqual(restored.hints, 1)
    }

    func testUndoIsBoundedAndSolvedPuzzleCannotChange() {
        var puzzle = Puzzle(difficulty: .deep, seed: 123)
        for _ in 0..<130 { puzzle.swap(0, 1) }
        XCTAssertEqual(puzzle.undoStack.count, 100)
        while !puzzle.solved { puzzle.hint() }
        let solved = puzzle
        puzzle.undo()
        puzzle.swap(0, 1)
        puzzle.hint()
        XCTAssertEqual(puzzle, solved)
    }

    func testLegacyBuild3SaveMigratesWithoutLosingProgress() throws {
        // This valid build-3 fixture contains a one-move player history.
        let legacy = Data(Self.legacyJSON.utf8)
        var puzzle = try JSONDecoder().decode(Puzzle.self, from: legacy)
        XCTAssertEqual(puzzle.id, "existing-player")
        XCTAssertEqual(puzzle.moves, 1)
        XCTAssertEqual(puzzle.hints, 0)
        XCTAssertEqual(puzzle.board, Self.legacyAfterMove)
        puzzle.undo()
        XCTAssertEqual(puzzle.board, Self.legacyStartingBoard)
        puzzle.swap(0, 8)
        puzzle.restart()
        XCTAssertEqual(puzzle.board, Self.legacyStartingBoard)
        let restored = try JSONDecoder().decode(Puzzle.self, from: JSONEncoder().encode(puzzle))
        XCTAssertEqual(restored, puzzle)
        while !puzzle.solved { puzzle.hint() }
        XCTAssertTrue(puzzle.solved)
    }

    func testLegacyProgressKeepsDailyAndCompletionHistory() throws {
        let json = "{\"version\":1,\"free\":" + Self.legacyJSON +
            ",\"daily\":" + Self.legacyJSON + ",\"wins\":[{\"id\":\"old-win\",\"difficulty\":\"gentle\",\"moves\":5,\"hints\":0,\"daily\":false,\"finishedAt\":0}]}"
        let progress = try JSONDecoder().decode(Progress.self, from: Data(json.utf8))
        XCTAssertEqual(progress.free?.board, Self.legacyAfterMove)
        XCTAssertEqual(progress.daily?.board, Self.legacyAfterMove)
        XCTAssertEqual(progress.wins.map(\.id), ["old-win"])
        XCTAssertEqual(progress.unassisted, 1)
    }

    func testMalformedAndFutureSavesAreRejected() throws {
        let puzzle = Puzzle(difficulty: .gentle, seed: 42)
        let data = try JSONEncoder().encode(puzzle)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["rulesVersion"] = 99
        XCTAssertThrowsError(try JSONDecoder().decode(Puzzle.self, from: JSONSerialization.data(withJSONObject: object)))
        object["rulesVersion"] = 2
        object["board"] = Array(repeating: 0, count: 9)
        XCTAssertThrowsError(try JSONDecoder().decode(Puzzle.self, from: JSONSerialization.data(withJSONObject: object)))
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


    static let legacyStartingBoard = [0, 4, 8, 5, 2, 7, 1, 3, 6]
    static let legacyAfterMove = [8, 0, 4, 5, 2, 7, 1, 3, 6]
    static let legacyJSON = #"{"id":"existing-player","difficulty":"gentle","seed":42,"daily":false,"board":[8,0,4,5,2,7,1,3,6],"route":[{"axis":"column","index":1,"direction":-1},{"axis":"row","index":1,"direction":-1},{"axis":"column","index":2,"direction":1},{"axis":"row","index":2,"direction":-1},{"axis":"row","index":1,"direction":-1},{"axis":"row","index":0,"direction":1}],"undoStack":[{"board":[0,4,8,5,2,7,1,3,6],"route":[{"axis":"column","index":1,"direction":-1},{"axis":"row","index":1,"direction":-1},{"axis":"column","index":2,"direction":1},{"axis":"row","index":2,"direction":-1},{"axis":"row","index":1,"direction":-1}],"moves":0}],"moves":1,"hints":0}"#
}
