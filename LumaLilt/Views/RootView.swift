import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("swapTutorialCompleted") private var onboarded = false
    @State private var showHelp = false

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Play", systemImage: "square.grid.3x3.fill") }
            NavigationStack { CollectionView() }
                .tabItem { Label("Collection", systemImage: "sparkles") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .onAppear { showHelp = !onboarded }
        .sheet(isPresented: $showHelp, onDismiss: { onboarded = true }) { HelpView() }
        .alert("Saved progress", isPresented: Binding(
            get: { store.storageMessage != nil },
            set: { if !$0 { store.storageMessage = nil } }
        )) { Button("OK", role: .cancel) { store.storageMessage = nil } }
        message: { Text(store.storageMessage ?? "") }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var difficulty: Difficulty = .gentle
    @State private var showFree = false
    @State private var confirmNew = false
    @State private var showHelp = false
    @AppStorage("palette") private var palette = "Tide"
    @AppStorage("showMoveCount") private var showMoveCount = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Label("LUMALILT", systemImage: "circle.hexagongrid.fill")
                        .font(.caption.weight(.bold)).tracking(3).foregroundStyle(Theme.mint)
                    Spacer()
                    Button { showHelp = true } label: { Image(systemName: "questionmark.circle").frame(width: 44, height: 44) }
                        .accessibilityLabel("How to play")
                }
                VStack(alignment: .leading, spacing: 9) {
                    Text("A little color.\nA quieter mind.").font(.system(size: 38, weight: .semibold, design: .rounded))
                    Text("Find the pattern. Enjoy the moment.").foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    TileGrid(board: [0, 1, 2, 6, 4, 5, 3, 7, 8], size: 3, palette: palette, numbers: false)
                        .frame(width: 190, height: 190).rotationEffect(.degrees(-8))
                        .padding(22).accessibilityHidden(true)
                    Spacer()
                }
                Panel {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Label("THE DAILY LILT", systemImage: "sun.max").font(.caption.weight(.bold)).tracking(1)
                            Spacer()
                            Text("4 × 4").font(.caption.monospaced())
                        }.foregroundStyle(Theme.mint)
                        Text(store.progress.daily?.solved == true ? "Today's colors, restored." : "One small daily ritual.")
                            .font(.title2.weight(.semibold))
                        Text("A shared puzzle, played your way. Refreshes at midnight UTC.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        NavigationLink { GameView(daily: true) } label: {
                            ZStack {
                                Text(store.progress.daily?.solved == true ? "View today's puzzle" : "Play today's puzzle")
                                    .padding(.horizontal, 28).frame(maxWidth: .infinity)
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.up.right").accessibilityHidden(true)
                                }
                            }
                        }.buttonStyle(PrimaryButton())
                    }
                }
                VStack(alignment: .leading, spacing: 14) {
                    Text("Go at your own pace").font(.title2.weight(.semibold))
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { item in Text("\(item.title) \(item.size)×\(item.size)").tag(item) }
                    }.pickerStyle(.segmented)
                    Button("Start a fresh puzzle") {
                        if let free = store.progress.free, !free.solved { confirmNew = true }
                        else { start() }
                    }.buttonStyle(PrimaryButton())
                    if let free = store.progress.free, !free.solved {
                        Button("Continue \(free.difficulty.title.lowercased())" + (showMoveCount ? " · \(free.moves) moves" : "")) { showFree = true }
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    Text("No clock. No pressure. One pair at a time.")
                        .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }.padding(24).frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
        }
        .background(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showFree) { GameView(daily: false) }
        .sheet(isPresented: $showHelp) { HelpView() }
        .confirmationDialog("Replace your unfinished free-play puzzle?", isPresented: $confirmNew, titleVisibility: .visible) {
            Button("Start fresh", role: .destructive) { start() }
            Button("Keep playing", role: .cancel) {}
        }
    }
    private func start() { store.startFree(difficulty); showFree = true }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("palette") private var palette = "Tide"
    @State private var board = [1, 0, 2, 3, 4, 5, 6, 8, 7]
    @State private var selected: Int? = nil
    @State private var pairs = 0

    private var first: Int { pairs == 0 ? 0 : 7 }
    private var second: Int { pairs == 0 ? 1 : 8 }
    private var instruction: String {
        if pairs == 2 { return "You did it. Every other tile stayed put." }
        if selected == nil { return pairs == 0 ? "Tap tile 2, then tile 1 to swap them." : "Now tap tile 9, then tile 8." }
        return pairs == 0 ? "Now tap tile 1. Only this pair will move." : "Tap tile 8 to finish the pattern."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Two tiles. One swap.").font(.title.bold())
                    Text(instruction).font(.headline).accessibilityIdentifier("practice-instruction")
                    TileGrid(board: board, size: 3, palette: palette, numbers: true,
                             selected: selected, select: practice)
                        .allowsHitTesting(pairs < 2)
                    Text("Arrange numbers left to right, top to bottom. In a real puzzle, you can swap any two tiles, even diagonally.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if pairs == 2 {
                        Label("Practice complete", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Theme.mint).accessibilityIdentifier("practice-complete")
                        Button("Let's play") { dismiss() }.buttonStyle(PrimaryButton())
                    }
                    Text("Undo reverses one swap. Hint places a tile home without disturbing tiles already home. The target stays above your puzzle; tap it for a larger view.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("No timer or move penalties. Number labels and stronger colors are on by default. You can change them in Settings.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: 440).frame(maxWidth: .infinity)
            }.background(Theme.ink).navigationTitle("Try a quick swap")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Skip") { dismiss() }.accessibilityLabel("Skip practice").accessibilityIdentifier("skip-practice") }
        }
    }

    private func practice(_ index: Int) {
        guard pairs < 2 else { return }
        if selected == nil {
            if index == first { selected = index }
        } else if index == first { selected = nil }
        else if index == second {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                board.swapAt(first, second)
                selected = nil
                pairs += 1
            }
        }
    }
}
