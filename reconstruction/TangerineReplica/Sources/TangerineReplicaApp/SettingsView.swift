import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsView(model: model)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 390)
        .padding(20)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Sounds and haptics", isOn: Binding(
                    get: { model.soundsEnabled },
                    set: { model.setSoundsEnabled($0) }
                ))

                Toggle("Launch at login", isOn: $model.launchAtLogin)
                    .help("The original app integrates with macOS Login Items. This reconstruction stores the preference only.")
            }

            Section("File access") {
                Label("Results are intended to be saved beside the originals.", systemImage: "folder")
                    .foregroundStyle(.secondary)
                Label("This reconstruction accepts local file URLs and does not upload documents.", systemImage: "lock.shield")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var model: ReplicaModel

    var body: some View {
        Form {
            Section("Conversion fan theme") {
                Picker("Theme", selection: Binding(
                    get: { model.fanTheme },
                    set: { model.setTheme($0) }
                )) {
                    ForEach(FanTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Modifier shortcuts") {
                Text("The observed app uses modifier-key shortcuts for wheel actions. This reconstruction exposes the shortcuts on each petal but does not remap them yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 44))
                .foregroundStyle(Color(red: 0.95, green: 0.36, blue: 0.12))
            Text("TangerineReplica")
                .font(.title2.bold())
            Text("A clean-room SwiftUI reconstruction of the observed Tangerine menu-bar shell.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("macOS 13+ · free/open-source reconstruction")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
