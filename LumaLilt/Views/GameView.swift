import SwiftUI
import UIKit

struct TileGrid: View {
    let board: [Int]
    let size: Int
    let palette: String
    let numbers: Bool
    var selected: Int? = nil
    var select: ((Int) -> Void)? = nil
    var shift: ((Int, CGSize) -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: size), spacing: 6) {
            ForEach(board.indices, id: \.self) { index in
                Button { select?(index) } label: {
                    RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                        .fill(Theme.tile(board[index], size: size, palette: palette))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if numbers {
                                Text("\(board[index] + 1)").font(.system(.body, design: .rounded, weight: .bold))
                                    .minimumScaleFactor(0.6).foregroundStyle(Theme.ink).padding(3)
                            }
                        }
                        .overlay {
                            if selected == index {
                                RoundedRectangle(cornerRadius: size == 5 ? 10 : 14)
                                    .strokeBorder(Theme.ink, lineWidth: 3).padding(3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tile \(board[index] + 1), row \(index / size + 1), column \(index % size + 1)")
                .accessibilityHint(select == nil ? "" : "Selects this row and column for the arrow controls")
                .accessibilityAddTraits(selected == index ? .isSelected : [])
                .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in shift?(index, value.translation) })
                .allowsHitTesting(select != nil)
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
    @State private var selected = 0
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
                        VStack(alignment: .trailing) {
                            Text("\(puzzle.moves)").font(.title.monospacedDigit().bold())
                            Text("moves").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    TileGrid(board: puzzle.board, size: puzzle.size, palette: palette, numbers: numbers,
                             selected: puzzle.solved ? nil : selected,
                             select: { selected = $0 }, shift: { index, translation in
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
                            Text("Row \(selected / puzzle.size + 1) · Column \(selected % puzzle.size + 1)")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                arrow("arrow.left", label: "Shift selected row left", axis: .row, direction: -1, size: puzzle.size)
                                arrow("arrow.right", label: "Shift selected row right", axis: .row, direction: 1, size: puzzle.size)
                                Divider().frame(height: 32)
                                arrow("arrow.up", label: "Shift selected column up", axis: .column, direction: -1, size: puzzle.size)
                                arrow("arrow.down", label: "Shift selected column down", axis: .column, direction: 1, size: puzzle.size)
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
                            TileGrid(board: Array(0..<(puzzle.size * puzzle.size)), size: puzzle.size, palette: palette, numbers: false)
                                .frame(width: 92).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Your destination").font(.headline)
                                Text("Match this pattern. Numbers go from 1 to \(puzzle.size * puzzle.size), left to right, top to bottom.")
                                    .font(.caption).foregroundStyle(.secondary)
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

    private func arrow(_ symbol: String, label: String, axis: Axis, direction: Int, size: Int) -> some View {
        Button { play(Move(axis: axis, index: axis == .row ? selected / size : selected % size, direction: direction)) } label: {
            Image(systemName: symbol).font(.title3.bold()).frame(maxWidth: .infinity).frame(height: 52)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
        }.accessibilityLabel(label)
    }

    private func play(_ move: Move) {
        change { $0.play(move) }
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
            Text("\(puzzle.moves) moves · \(puzzle.hints == 0 ? "Unassisted" : "With a little help")")
                .foregroundStyle(.secondary)
            ShareLink(item: "I restored \(daily ? "the daily LumaLilt \(String(puzzle.id.dropFirst(6)))" : "a \(puzzle.size)×\(puzzle.size) LumaLilt puzzle") in \(puzzle.moves) moves\(puzzle.hints > 0 ? " with hints" : " without hints"). A little shift. A quieter mind.") {
                Label("Share your moment", systemImage: "square.and.arrow.up")
            }.padding(10)
            if !daily {
                Button("One more puzzle") { store.startFree(puzzle.difficulty); selected = 0 }.buttonStyle(PrimaryButton())
            } else { Text("A fresh puzzle arrives at midnight UTC.").font(.footnote).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity).padding(.vertical, 12)
    }
}
