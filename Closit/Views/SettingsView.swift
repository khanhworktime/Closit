import SwiftUI
import ServiceManagement

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case developer = "Developer"
    case credit = "Credit"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .developer: return "hammer"
        case .credit: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var appState: ClositAppState
    @State private var selectedTab: SettingsTab? = .general
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: SettingsTab.general) {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                
                if appState.settings.isDeveloperModeEnabled {
                    NavigationLink(value: SettingsTab.developer) {
                        Label(SettingsTab.developer.rawValue, systemImage: SettingsTab.developer.icon)
                    }
                }
                
                NavigationLink(value: SettingsTab.credit) {
                    Label(SettingsTab.credit.rawValue, systemImage: SettingsTab.credit.icon)
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 200)
            // Transparent background for sidebar to let material show
            .scrollContentBackground(.hidden) 
        } detail: {
            ZStack {
                // Glass background
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                
                Group {
                    if let selectedTab = selectedTab {
                        switch selectedTab {
                        case .general:
                            GeneralSettingsTab(appState: appState)
                        case .developer:
                            if appState.settings.isDeveloperModeEnabled {
                                DeveloperSettingsTab(appState: appState)
                            } else {
                                Text("Select a category")
                                    .foregroundStyle(.secondary)
                            }
                        case .credit:
                            CreditSettingsTab()
                        }
                    } else {
                        Text("Select a category")
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .id(selectedTab)
            }
        }
        .frame(width: 600, height: 450)
        // Set the window background to use material for premium glassmorphism
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow).ignoresSafeArea())
    }
}

// MARK: - General Tab
struct GeneralSettingsTab: View {
    @ObservedObject var appState: ClositAppState
    @EnvironmentObject var updaterManager: UpdaterManager
    
    var body: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        Form {
            // App Info Section
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Closit")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Version \(appVersion) (\(appBuild))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        updaterManager.checkForUpdates()
                    }) {
                        Text("Check for Updates...")
                    }
                    .controlSize(.small)
                    .padding(.top, 4)
                }
                Spacer()
            }
            .padding(.bottom, 10)
            
            Section(header: Text("Startup & Behavior")) {
                Toggle(isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update Launch at Login: \(error)")
                        }
                    }
                )) {
                    Text("Launch at login")
                }
                
                Toggle("Show Background Apps", isOn: $appState.settings.showBackgroundApps)
                
                Toggle("Advanced Mode", isOn: $appState.settings.isAdvancedModeEnabled.animation())
            }
            
            if appState.settings.isAdvancedModeEnabled {
                Section(header: Text("Developer")) {
                    Toggle("Developer Mode", isOn: $appState.settings.isDeveloperModeEnabled.animation())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Developer Tab
struct DeveloperSettingsTab: View {
    @ObservedObject var appState: ClositAppState
    
    var body: some View {
        Form {
            Section(header: Text("Developer Flags")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("These settings are for debugging and development purposes.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Divider().opacity(0.5)
                    
                    Button("Reset Onboarding State") {
                        appState.settings.hasSeenOnboarding = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Text("Clicking this will show the Welcome screen again on the next launch.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Credit Tab
struct CreditSettingsTab: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        VStack(spacing: 16) {
            Spacer()
            
            // App Icon
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: .blue.opacity(0.4), radius: 30, x: 0, y: 0) // Glow effect
                .padding(.bottom, 8)
            
            // App Name & Version
            VStack(spacing: 4) {
                Text("Closit")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Version \(appVersion)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
            
            // Developed with ❤️
            Text("Designed and developed with ❤️")
                .font(.headline)
            
            // Links
            HStack(spacing: 24) {
                Link(destination: URL(string: "https://github.com/khanhworktime")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("GitHub")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
                
                Link(destination: URL(string: "mailto:krist.dev.vn@gmail.com")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                        Text("Email")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
            
            // Ko-Fi Button
            Link(destination: URL(string: "https://ko-fi.com/kristhoang")!) {
                AsyncImage(url: URL(string: "https://storage.ko-fi.com/cdn/brandasset/v2/support_me_on_kofi_badge_beige.png")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 40)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - VisualEffectView
import AppKit

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
