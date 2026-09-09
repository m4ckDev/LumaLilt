import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("onboarded") private var onboarded = false
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
                    Text("A little shift.\nA quieter mind.").font(.system(size: 38, weight: .semibold, design: .rounded))
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
                            HStack {
                                Text(store.progress.daily?.solved == true ? "View today's puzzle" : "Play today's puzzle")
                                Spacer(); Image(systemName: "arrow.up.right")
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
                        Button("Continue \(free.difficulty.title.lowercased()) · \(free.moves) moves") { showFree = true }
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    Text("No clock. No pressure. Just one more shift.")
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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Image(systemName: "square.grid.3x3.fill").font(.system(size: 48)).foregroundStyle(Theme.mint)
                    Text("Bring the colors home.").font(.largeTitle.bold())
                    instruction("1", "Choose a tile", "Tap any tile to select its row and column.")
                    instruction("2", "Give it a shift", "Use the arrows to slide the selected row left or right, or column up or down. Tiles wrap around the edges. You can also swipe from a tile.")
                    instruction("3", "Restore the pattern", "Match the preview. Numbers run left to right, top to bottom, starting at 1.")
                    Text("Undo is always there while you play. A hint makes one move along a known path back to the solution; it may undo one of your moves. Using hints marks that puzzle as assisted.")
                        .foregroundStyle(.secondary)
                    Button("Let's play") { dismiss() }.buttonStyle(PrimaryButton())
                }.padding(28).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(Theme.ink).navigationTitle("How to play").navigationBarTitleDisplayMode(.inline)
        }
    }
    private func instruction(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number).font(.headline).foregroundStyle(Theme.mint).padding(12).background(Theme.panel, in: Circle())
            VStack(alignment: .leading, spacing: 5) { Text(title).font(.headline); Text(detail).foregroundStyle(.secondary) }
        }
    }
}
