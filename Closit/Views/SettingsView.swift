import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var appState: ClositAppState
    @State private var selectedTab = "General"
    
    private var currentHeight: CGFloat {
        switch selectedTab {
        case "General":
            return appState.settings.isAdvancedModeEnabled ? 460 : 180
        case "Developer":
            return 250
        case "Credit":
            return 380
        default:
            return 380
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab(appState: appState)
                .tag("General")
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            if appState.settings.isDeveloperModeEnabled {
                DeveloperSettingsTab(appState: appState)
                    .tag("Developer")
                    .tabItem {
                        Label("Developer", systemImage: "hammer")
                    }
            }
            
            CreditSettingsTab()
                .tag("Credit")
                .tabItem {
                    Label("Credit", systemImage: "info.circle")
                }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .frame(width: 500, height: currentHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentHeight)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var appState: ClositAppState
    
    var body: some View {
        Form {
            Section {
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                            .font(.system(size: 14, weight: .medium))
                        Text("Automatically start Closit when you log in.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            
            Section {
                Toggle(isOn: $appState.settings.showBackgroundApps) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Background Apps")
                            .font(.system(size: 14, weight: .medium))
                        Text("Display hidden daemons and background tasks in the list.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

            Section {
                Toggle(isOn: $appState.settings.isAdvancedModeEnabled.animation()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Advanced Mode")
                            .font(.system(size: 14, weight: .medium))
                        Text("Unlock auto-quit features and advanced controls.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

            if appState.settings.isAdvancedModeEnabled {
/*
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $appState.settings.isAutoQuitEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto Quit Unused Apps")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Automatically quit applications that haven't been active.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)

                        HStack {
                            Text("Idle Threshold")
                                .font(.system(size: 13))
                                .foregroundColor(!appState.settings.isAutoQuitEnabled ? .secondary : .primary)
                            Spacer()
                            Picker("", selection: $appState.settings.autoQuitIdleMinutes) {
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                                Text("60 minutes").tag(60)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                            .disabled(!appState.settings.isAutoQuitEnabled)
                        }
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                } header: {
                    Text("Automation")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
*/

                Section {
                    Toggle(isOn: $appState.settings.isDeveloperModeEnabled.animation()) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Developer Mode")
                                .font(.system(size: 14, weight: .medium))
                            Text("Enable developer and debugging tools.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                } header: {
                    Text("Developer")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .formStyle(.grouped)
    }
}

struct DeveloperSettingsTab: View {
    @ObservedObject var appState: ClositAppState
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Developer Flags")
                        .font(.system(size: 14, weight: .bold))
                    
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
            }
        }
        .formStyle(.grouped)
    }
}

struct CreditSettingsTab: View {
    @Environment(\.openURL) var openURL
    @State private var isHoveringKofi = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 16)
            
            Text("Closit")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.primary, .primary.opacity(0.7)], startPoint: .top, endPoint: .bottom))
            
            Text("Version 1.0.0")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.top, 2)
            
            VStack(spacing: 6) {
                Text("Designed and developed with ❤️")
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 16) {
                    Link(destination: URL(string: "https://github.com/khanhworktime")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                            Text("GitHub")
                        }
                    }
                    .buttonStyle(.link)
                    
                    Link(destination: URL(string: "mailto:krist.dev.vn@gmail.com")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                            Text("Email")
                        }
                    }
                    .buttonStyle(.link)
                }
                .font(.system(size: 12, weight: .semibold))
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Ko-fi Button
            Button {
                if let url = URL(string: "https://ko-fi.com/kristhoang") {
                    openURL(url)
                }
            } label: {
                AsyncImage(url: URL(string: "https://storage.ko-fi.com/cdn/brandasset/v2/support_me_on_kofi_badge_beige.png")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 54)
                .shadow(color: Color.black.opacity(isHoveringKofi ? 0.2 : 0.1), radius: isHoveringKofi ? 6 : 2, x: 0, y: isHoveringKofi ? 4 : 2)
                .scaleEffect(isHoveringKofi ? 1.05 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isHoveringKofi = hovering
                }
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
