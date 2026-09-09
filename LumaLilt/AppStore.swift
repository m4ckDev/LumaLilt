import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var progress = Progress()
    @Published var storageMessage: String?
    private let fileURL: URL?
    private var maySave = true

    init() {
        fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("LumaLilt", isDirectory: true).appendingPathComponent("progress.json")
        if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let decoded = try JSONDecoder().decode(Progress.self, from: Data(contentsOf: fileURL))
                guard decoded.version == 1, decoded.free?.isValid != false, decoded.daily?.isValid != false else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                progress = decoded
            } catch {
                maySave = false
                storageMessage = "Saved progress could not be opened. Your original save is preserved. You can play this session, or reset saved progress in Settings."
            }
        }
        refreshDaily()
    }

    func refreshDaily() {
        let today = Puzzle.dailyPuzzle()
        if progress.daily?.id != today.id { progress.daily = today; save() }
    }

    func startFree(_ difficulty: Difficulty) {
        progress.free = Puzzle(difficulty: difficulty, seed: UInt64.random(in: .min ... .max))
        save()
    }

    func puzzle(daily: Bool) -> Puzzle? { daily ? progress.daily : progress.free }

    func update(daily: Bool, _ action: (inout Puzzle) -> Void) {
        guard var puzzle = puzzle(daily: daily) else { return }
        action(&puzzle)
        progress.record(puzzle)
        if daily { progress.daily = puzzle } else { progress.free = puzzle }
        save()
    }

    func save() {
        guard maySave else { return }
        guard let fileURL else {
            storageMessage = "Progress cannot be saved on this device right now."
            return
        }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(progress).write(to: fileURL, options: .atomic)
        } catch {
            storageMessage = "Progress could not be saved. Free some device storage, then reopen the app."
        }
    }

    func reset() {
        maySave = true
        progress = Progress()
        storageMessage = nil
        refreshDaily()
    }
}
