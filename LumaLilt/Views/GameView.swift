import SwiftUI
import UIKit

/// Tile identity follows its value so swaps animate between positions.
/// Static previews use shapes, never nested interactive buttons.
struct TileGrid: View {
    let board: [Int]
    let size: Int
    let palette: String
    let numbers: Bool
    @AppStorage("enhancedColors") private var enhancedColors = true
    var selected: Int? = nil
    var select: ((Int) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            grid(width: geometry.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func grid(width: CGFloat) -> some View {
        let spacing: CGFloat = 6
        let gaps: CGFloat = CGFloat(size - 1) * spacing
        let side: CGFloat = max(1, (width - gaps) / CGFloat(size))
        return ZStack(alignment: .topLeading) {
            ForEach(board, id: \.self) { value in
                positionedTile(value, side: side)
            }
        }
        .frame(width: width, height: width, alignment: .topLeading)
    }

    private func positionedTile(_ value: Int, side: CGFloat) -> some View {
        let index: Int = board.firstIndex(of: value) ?? 0
        let step: CGFloat = side + 6
        let x: CGFloat = CGFloat(index % size) * step
        let y: CGFloat = CGFloat(index / size) * step
        let depth: Double = selected == index ? 1 : 0
        return tileContent(value, index: index)
            .frame(width: side, height: side)
            .offset(x: x, y: y)
            .zIndex(depth)
    }

    @ViewBuilder
    private func tileContent(_ value: Int, index: Int) -> some View {
        if let select {
            interactiveTile(value, index: index, action: select)
        } else {
            tile(value, index: index).accessibilityHidden(true)
        }
    }

    private func interactiveTile(_ value: Int, index: Int, action: @escaping (Int) -> Void) -> some View {
        let label: String = "Tile \(value + 1), row \(index / size + 1), column \(index % size + 1)"
        let traits: AccessibilityTraits = selected == index ? .isSelected : []
        return Button { action(index) } label: { tile(value, index: index) }
            .buttonStyle(.plain)
            .accessibilityIdentifier("tile-\(index)")
            .accessibilityLabel(Text(label))
            .accessibilityValue(Text(String(value + 1)))
            .accessibilityHint(Text(selectionHint(index)))
            .accessibilityAddTraits(traits)
    }

    private func selectionHint(_ index: Int) -> String {
        if selected == index { return "Deselects this tile" }
        if selected == nil { return "Selects this tile" }
        return "Swaps this tile with the selected tile; all other tiles stay in place"
    }

    private func tile(_ value: Int, index: Int) -> some View {
        RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
            .fill(Theme.tile(value, size: size, palette: palette, enhanced: enhancedColors))
            .overlay {
                if numbers {
                    Text("\(value + 1)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .minimumScaleFactor(0.6).lineLimit(1).foregroundStyle(.white)
                        .padding(5).background(Theme.ink, in: RoundedRectangle(cornerRadius: 7))
                }
            }
            .overlay {
                if selected == index {
                    RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                        .strokeBorder(Theme.ink, lineWidth: 5)
                        .overlay {
                            RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                                .strokeBorder(.white, lineWidth: 3).padding(3)
                        }
                }
            }
    }
}

struct GameView: View {
    let daily: Bool
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("palette") private var palette = "Tide"
    @AppStorage("numbers") private var numbers = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("showMoveCount") private var showMoveCount = false
    @State private var selected: Int? = nil
    @State private var restart = false
    @State private var showHelp = false
    @State private var showTarget = false
    @State private var hintMessage: String? = nil

    var body: some View {
        ScrollView {
            if let puzzle = store.puzzle(daily: daily) {
                VStack(spacing: 16) {
                    if !puzzle.solved {
                        Text(selected.map { "Tile \(puzzle.board[$0] + 1) selected. Tap any other tile to swap." }
                             ?? "Tap a tile, then another. Only those two tiles move.")
                            .font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("swap-instructions")
                    }
                    TileGrid(board: puzzle.board, size: puzzle.size, palette: palette, numbers: numbers,
                             selected: puzzle.solved ? nil : selected, select: { choose($0, puzzle: puzzle) })
                        .allowsHitTesting(!puzzle.solved)
                        .padding(8).background(Theme.panel, in: RoundedRectangle(cornerRadius: 24))
                    HStack {
                        Text("\(puzzle.matched) of \(puzzle.size * puzzle.size) tiles home")
                            .accessibilityIdentifier("matched-count")
                            .accessibilityValue(String(puzzle.matched))
                        Spacer()
                        if showMoveCount { Text("\(puzzle.moves) moves").monospacedDigit() }
                    }.font(.subheadline).foregroundStyle(.secondary)

                    if puzzle.solved {
                        completion(puzzle)
                    } else {
                        HStack(spacing: 12) {
                            Button { selected = nil; hintMessage = nil; change { $0.undo() } } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }.disabled(puzzle.undoStack.isEmpty).accessibilityIdentifier("undo-move")
                            Spacer(minLength: 0)
                            Button { useHint(puzzle) } label: { Label("Hint", systemImage: "lightbulb") }
                                .accessibilityIdentifier("apply-hint")
                            Spacer(minLength: 0)
                            Button { restart = true } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
                        }.font(.subheadline).buttonStyle(.borderless).frame(minHeight: 44)
                        if selected != nil {
                            Button("Cancel selection") { selected = nil }.frame(minHeight: 44)
                        }
                        if let hintMessage {
                            Text(hintMessage).font(.subheadline).foregroundStyle(Theme.mint)
                                .accessibilityIdentifier("hint-explanation")
                        }
                    }
                }.padding(16).frame(maxWidth: 510).frame(maxWidth: .infinity)
            }
        }
        .background(Theme.ink)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let puzzle = store.puzzle(daily: daily) { targetBar(puzzle) }
        }
        .navigationTitle(daily ? "Today's puzzle" : "Free play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                .accessibilityLabel("How to play")
        }
        .sheet(isPresented: $showHelp) { HelpView() }
        .sheet(isPresented: $showTarget) {
            if let puzzle = store.puzzle(daily: daily) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Numbers run left to right, top to bottom.").font(.headline)
                            TileGrid(board: Array(0..<(puzzle.size * puzzle.size)), size: puzzle.size,
                                     palette: palette, numbers: numbers).accessibilityHidden(true)
                        }.padding(22).frame(maxWidth: 510).frame(maxWidth: .infinity)
                    }.background(Theme.ink).navigationTitle("Your destination")
                        .toolbar { Button("Done") { showTarget = false } }
                }
            }
        }
        .confirmationDialog("Start this puzzle over?", isPresented: $restart, titleVisibility: .visible) {
            Button("Restart puzzle", role: .destructive) {
                selected = nil; hintMessage = nil; change { $0.restart() }
            }
        }
    }

    // This stays visible as the play area scrolls, including on compact iPhones.
    private func targetBar(_ puzzle: Puzzle) -> some View {
        Button { showTarget = true } label: {
            HStack(spacing: 14) {
                TileGrid(board: Array(0..<(puzzle.size * puzzle.size)), size: puzzle.size,
                         palette: palette, numbers: false)
                    .frame(width: 78, height: 78).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your destination").font(.headline)
                    Text("1–\(puzzle.size * puzzle.size), left to right").font(.subheadline)
                    Text("Tap to enlarge").font(.caption).foregroundStyle(Theme.mint)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.left.and.arrow.down.right").accessibilityHidden(true)
            }.padding(.horizontal, 16).padding(.vertical, 10)
                .frame(maxWidth: 510).frame(maxWidth: .infinity)
                .background(Theme.panel)
        }.buttonStyle(.plain).accessibilityIdentifier("target-preview")
            .accessibilityLabel("View target pattern. Numbers 1 through \(puzzle.size * puzzle.size), left to right, top to bottom.")
    }

    private func choose(_ index: Int, puzzle: Puzzle) {
        guard !puzzle.solved else { return }
        guard let source = selected else { selected = index; hintMessage = nil; return }
        selected = nil
        guard source != index else { return }
        hintMessage = nil
        change { $0.swap(source, index) }
        feedback()
    }

    private func useHint(_ puzzle: Puzzle) {
        guard let suggestion = puzzle.suggestedSwap else { return }
        selected = nil
        change { _ = $0.hint() }
        hintMessage = "Placed tile \(suggestion.destination + 1) home. Tiles already home stayed in place."
        feedback()
    }

    private func feedback() {
        if haptics {
            if store.puzzle(daily: daily)?.solved == true {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        }
    }

    private func change(_ action: (inout Puzzle) -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { store.update(daily: daily, action) }
    }

    private func completion(_ puzzle: Puzzle) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Theme.mint)
            Text("Nicely restored.").font(.title.bold()).accessibilityIdentifier("puzzle-complete")
            Text((showMoveCount ? "\(puzzle.moves) moves · " : "") + (puzzle.hints == 0 ? "At your own pace" : "With a little help"))
                .foregroundStyle(.secondary)
            ShareLink(item: "I restored \(daily ? "the daily LumaLilt \(String(puzzle.id.dropFirst(6)))" : "a \(puzzle.size)×\(puzzle.size) LumaLilt puzzle")\(showMoveCount ? " in \(puzzle.moves) moves" : "")\(puzzle.hints > 0 ? " with hints" : " without hints"). A little color. A quieter mind.") {
                Label("Share your moment", systemImage: "square.and.arrow.up")
            }.padding(10)
            if !daily {
                Button("One more puzzle") {
                    store.startFree(puzzle.difficulty); selected = nil; hintMessage = nil
                }.buttonStyle(PrimaryButton())
            } else { Text("A fresh puzzle arrives at midnight UTC.").font(.footnote).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity).padding(.vertical, 12)
    }
}
