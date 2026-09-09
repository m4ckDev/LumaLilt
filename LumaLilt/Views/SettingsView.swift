import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("palette") private var palette = "Tide"
    @AppStorage("numbers") private var numbers = true
    @AppStorage("haptics") private var haptics = true
    @State private var confirmReset = false
    @State private var help = false

    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "2"
        return "\(version) (\(build))"
    }

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
                LabeledContent("Version", value: versionLabel)
                Text("A small solo puzzle by MacKinnonTech.").foregroundStyle(.secondary)
            }
            Section("Your privacy") {
                if let privacyURL = URL(string: "https://github.com/m4ckDev/LumaLilt/blob/main/docs/PRIVACY.md") {
                    Link("Privacy Policy", destination: privacyURL)
                }
                Text("Your puzzles and settings stay on this device. LumaLilt has no accounts, ads, or analytics. Gameplay works offline. Sharing and opening the privacy policy only happen when you choose.")
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
