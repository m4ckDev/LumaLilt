import SwiftUI
import UIKit

struct TileGrid: View {
    let board: [Int]
    let size: Int
    let palette: String
    let numbers: Bool
    @AppStorage("enhancedColors") private var enhancedColors = true
    var selected: Int? = nil
    var tapToMove = false
    var select: ((Int) -> Void)? = nil
    var shift: ((Int, CGSize) -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: size), spacing: 6) {
            ForEach(board.indices, id: \.self) { index in
                Button { select?(index) } label: {
                    RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                        .fill(Theme.tile(board[index], size: size, palette: palette, enhanced: enhancedColors))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if numbers {
                                Text("\(board[index] + 1)").font(.system(.body, design: .rounded, weight: .bold))
                                    .minimumScaleFactor(0.6).foregroundStyle(.white)
                                    .padding(5).background(Theme.ink, in: RoundedRectangle(cornerRadius: 7))
                            }
                        }
                        .overlay {
                            if selected == index {
                                RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                                    .strokeBorder(.white, lineWidth: 3).padding(3)
                                    .background {
                                        RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                                            .strokeBorder(Theme.ink, lineWidth: 3)
                                    }
                            } else if isDestination(index) {
                                RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                                    .strokeBorder(Theme.ink, style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .padding(2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tile \(board[index] + 1), row \(index / size + 1), column \(index % size + 1)")
                .accessibilityHint(select == nil ? "" : isDestination(index)
                    ? "Moves the selected tile here by shifting its whole row or column"
                    : selected == index && tapToMove ? "Deselects this tile" : "Selects this tile for movement")
                .accessibilityAddTraits(selected == index ? .isSelected : [])
                .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in shift?(index, value.translation) })
                .allowsHitTesting(select != nil)
            }
        }
    }

    private func isDestination(_ index: Int) -> Bool {
        guard tapToMove, let selected else { return false }
        return !Puzzle.shifts(from: selected, to: index, size: size).isEmpty
    }
}

struct GameView: View {
    let daily: Bool
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("palette") private var palette = "Tide"
    @AppStorage("numbers") private var numbers = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("tapToMove") private var tapToMove = true
    @AppStorage("showMoveCount") private var showMoveCount = false
    @State private var selected: Int? = nil
    @State private var restart = false
    @State private var showHelp = false

    var body: some View {
        ScrollView {
            if let puzzle = store.puzzle(daily: daily) {
                VStack(spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(daily ? "DAILY LILT" : puzzle.difficulty.title.uppercased())
                                .font(.caption.weight(.bold)).tracking(2).foregroundStyle(Theme.mint)
                            Text(puzzle.solved ? "Everything in its place." : "Find your flow.").font(.title2.bold())
                        }
                        Spacer()
                        if showMoveCount {
                            VStack(alignment: .trailing) {
                                Text("\(puzzle.moves)").font(.title.monospacedDigit().bold())
                                Text("moves").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if !puzzle.solved {
                        Picker("Movement controls", selection: $tapToMove) {
                            Text("Tap to move").tag(true)
                            Text("Arrows & swipe").tag(false)
                        }.pickerStyle(.segmented)
                        Text(tapToMove
                             ? "Tap a tile, then a destination in its row or column. The whole line moves."
                             : "Tap a tile, then use Left, Right, Up or Down. You can also swipe a tile.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    TileGrid(board: puzzle.board, size: puzzle.size, palette: palette, numbers: numbers,
                             selected: puzzle.solved ? nil : selected,
                             tapToMove: tapToMove,
                             select: { choose($0, puzzle: puzzle) }, shift: { index, translation in
                        selected = index
                        let horizontal = abs(translation.width) > abs(translation.height)
                        let direction = (horizontal ? translation.width : translation.height) > 0 ? 1 : -1
                        play(Move(axis: horizontal ? .row : .column,
                                  index: horizontal ? index / puzzle.size : index % puzzle.size, direction: direction))
                    })
                    .disabled(puzzle.solved)
                    .padding(10).background(Theme.panel, in: RoundedRectangle(cornerRadius: 24))

                    if puzzle.solved {
                        completion(puzzle)
                    } else {
                        Text("\(puzzle.matched) of \(puzzle.size * puzzle.size) tiles home")
                            .font(.subheadline).foregroundStyle(.secondary)
                        VStack(spacing: 10) {
                            Text(selected.map { "Row \($0 / puzzle.size + 1) · Column \($0 % puzzle.size + 1)" } ?? "Select a tile to enable the arrows")
                                .font(.caption).foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                arrow("arrow.left", title: "Left", label: "Shift selected row left", axis: .row, direction: -1, size: puzzle.size)
                                arrow("arrow.right", title: "Right", label: "Shift selected row right", axis: .row, direction: 1, size: puzzle.size)
                                arrow("arrow.up", title: "Up", label: "Shift selected column up", axis: .column, direction: -1, size: puzzle.size)
                                arrow("arrow.down", title: "Down", label: "Shift selected column down", axis: .column, direction: 1, size: puzzle.size)
                            }
                            if selected != nil {
                                Button("Choose another tile") { selected = nil }.font(.caption)
                            }
                        }
                        HStack(spacing: 24) {
                            Button { change { $0.undo() } } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                                .disabled(puzzle.undoStack.isEmpty)
                            Button { change { $0.hint() } } label: { Label("Hint", systemImage: "lightbulb") }
                            Button { restart = true } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
                        }.font(.subheadline).buttonStyle(.borderless).padding(.vertical, 10)
                    }
                    Panel {
                        HStack(spacing: 22) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Your destination").font(.headline)
                                Text("Match this pattern. Numbers go from 1 to \(puzzle.size * puzzle.size), left to right, top to bottom.")
                                    .font(.caption).foregroundStyle(.secondary)
                                TileGrid(board: Array(0..<(puzzle.size * puzzle.size)), size: puzzle.size, palette: palette, numbers: numbers)
                                    .frame(maxWidth: 300).frame(maxWidth: .infinity).accessibilityHidden(true)
                            }
                        }
                    }
                    if puzzle.hints > 0 {
                        Text("\(puzzle.hints) hints used · Assisted puzzle").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(22).frame(maxWidth: 510).frame(maxWidth: .infinity)
            }
        }
        .background(Theme.ink)
        .navigationTitle(daily ? "Today's puzzle" : "Free play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }.accessibilityLabel("How to play") }
        .sheet(isPresented: $showHelp) { HelpView() }
        .confirmationDialog("Start this puzzle over?", isPresented: $restart, titleVisibility: .visible) {
            Button("Restart puzzle", role: .destructive) { change { $0.restart() } }
        }
    }

    private func arrow(_ symbol: String, title: String, label: String, axis: Axis, direction: Int, size: Int) -> some View {
        Button {
            guard let selected else { return }
            play(Move(axis: axis, index: axis == .row ? selected / size : selected % size, direction: direction))
        } label: {
            Label(title, systemImage: symbol).font(.headline).frame(maxWidth: .infinity).frame(minHeight: 52)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
        }.accessibilityLabel(label).disabled(selected == nil)
    }

    private func choose(_ index: Int, puzzle: Puzzle) {
        guard tapToMove, let source = selected else { selected = index; return }
        if source == index { selected = nil; return }
        let shifts = Puzzle.shifts(from: source, to: index, size: puzzle.size)
        guard !shifts.isEmpty else { selected = index; return }
        change { puzzle in
            for move in shifts { puzzle.play(move) }
        }
        selected = nil
        feedback()
    }

    private func play(_ move: Move) {
        change { $0.play(move) }
        feedback()
    }

    private func feedback() {
        if haptics {
            if store.puzzle(daily: daily)?.solved == true { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            else { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        }
    }

    private func change(_ action: (inout Puzzle) -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { store.update(daily: daily, action) }
    }

    private func completion(_ puzzle: Puzzle) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Theme.mint)
            Text("Nicely restored.").font(.title.bold())
            Text((showMoveCount ? "\(puzzle.moves) moves · " : "") + (puzzle.hints == 0 ? "Unassisted" : "With a little help"))
                .foregroundStyle(.secondary)
            ShareLink(item: "I restored \(daily ? "the daily LumaLilt \(String(puzzle.id.dropFirst(6)))" : "a \(puzzle.size)×\(puzzle.size) LumaLilt puzzle")\(showMoveCount ? " in \(puzzle.moves) moves" : "")\(puzzle.hints > 0 ? " with hints" : " without hints"). A little shift. A quieter mind.") {
                Label("Share your moment", systemImage: "square.and.arrow.up")
            }.padding(10)
            if !daily {
                Button("One more puzzle") { store.startFree(puzzle.difficulty); selected = nil }.buttonStyle(PrimaryButton())
            } else { Text("A fresh puzzle arrives at midnight UTC.").font(.footnote).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity).padding(.vertical, 12)
    }
}
