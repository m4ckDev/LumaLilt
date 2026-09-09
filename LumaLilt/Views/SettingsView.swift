import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("palette") private var palette = "Tide"
    @AppStorage("numbers") private var numbers = true
    @AppStorage("haptics") private var haptics = true
    @State private var confirmReset = false
    @State private var help = false

    var body: some View {
        Form {
            Section("Make it yours") {
                Picker("Color palette", selection: $palette) {
                    ForEach(["Tide", "Dusk", "Ember"], id: \.self) { Text($0).tag($0) }
                }
                Toggle("Show tile numbers", isOn: $numbers)
                Toggle("Gentle haptics", isOn: $haptics)
            }
            Section {
                Text("Number labels make every puzzle playable without distinguishing colors. VoiceOver can select tiles and use the labeled arrow controls. Animations follow your device's Reduce Motion setting.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("About LumaLilt") {
                Button("How to play") { help = true }
                LabeledContent("Version", value: "1.0 (1)")
                Text("A small solo puzzle by MacKinnonTech.").foregroundStyle(.secondary)
            }
            Section("Your privacy") {
                Text("Your puzzles and settings stay on this device. LumaLilt has no accounts, ads, analytics, or network requests. Sharing only happens when you choose Share and select a destination.")
                    .font(.subheadline)
                Text("Device backups may include saved progress according to your Apple backup settings.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button("Reset all puzzle progress", role: .destructive) { confirmReset = true }
            } footer: { Text("Clears saved puzzles, completed moments, and milestones. Appearance settings are kept.") }
        }
        .scrollContentBackground(.hidden).background(Theme.ink).navigationTitle("Settings")
        .sheet(isPresented: $help) { HelpView() }
        .confirmationDialog("Permanently clear all puzzle progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Clear all progress", role: .destructive) { store.reset() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
