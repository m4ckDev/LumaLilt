import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Small moments,\nbeautifully collected.")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                HStack(spacing: 12) {
                    metric("Restored", value: store.progress.wins.count, symbol: "square.grid.3x3.fill")
                    metric("Unassisted", value: store.progress.unassisted, symbol: "sparkles")
                }
                Panel {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Little milestones").font(.headline)
                        milestone("First light", detail: "Restore your first puzzle", achieved: !store.progress.wins.isEmpty)
                        milestone("Finding flow", detail: "Restore 10 puzzles", achieved: store.progress.wins.count >= 10)
                        milestone("Your own rhythm", detail: "Solve 5 without hints", achieved: store.progress.unassisted >= 5)
                        milestone("Daily glow", detail: "Complete 7 daily puzzles", achieved: store.progress.wins.filter(\.daily).count >= 7)
                    }
                }
                Text("Your latest moments").font(.title2.bold())
                if store.progress.wins.isEmpty {
                    Text("Your first restored puzzle will appear here. Take your time.")
                        .foregroundStyle(.secondary).padding(.vertical)
                }
                ForEach(Array(store.progress.wins.suffix(20).reversed())) { win in
                    HStack(spacing: 14) {
                        Image(systemName: win.daily ? "sun.max.fill" : "square.grid.3x3.fill")
                            .foregroundStyle(Theme.mint).frame(width: 32)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(win.daily ? "Daily Lilt" : "\(win.difficulty.title) puzzle").font(.headline)
                            Text(win.finishedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(win.moves) moves").font(.subheadline.monospacedDigit())
                            Text(win.hints == 0 ? "Unassisted" : "Assisted").font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
            }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }.background(Theme.ink).navigationTitle("Collection")
    }
    private func metric(_ title: String, value: Int, symbol: String) -> some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol).foregroundStyle(Theme.mint)
                Text("\(value)").font(.largeTitle.bold().monospacedDigit())
                Text(title).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
    private func milestone(_ title: String, detail: String, achieved: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: achieved ? "checkmark.seal.fill" : "circle.dotted")
                .foregroundStyle(achieved ? Theme.mint : .gray).font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine).accessibilityValue(achieved ? "Achieved" : "Not yet achieved")
    }
}
