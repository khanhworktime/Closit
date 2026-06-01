import SwiftUI

enum SortMode: String, CaseIterable, Identifiable {
    case name = "Name"
    case cpu = "CPU"
    case ram = "RAM"
    var id: Self { self }
}

struct MenuContentView: View {
    @ObservedObject var appState: ClositAppState
    @State private var searchText = ""
    @State private var sortMode: SortMode = .cpu
    @State private var isConfirmingQuit = false

    var body: some View {
        Group {
            if !appState.settings.hasSeenOnboarding {
                OnboardingView(appState: appState)
            } else {
                mainContentView
            }
        }
        .background(.ultraThinMaterial)
        .onAppear {
            appState.refresh()
            isConfirmingQuit = false
        }
    }

    private var displayApps: [AppInfo] {
        let filtered = appState.apps.filter { app in
            let matchesVisibility = appState.settings.showBackgroundApps
                ? (!app.name.isEmpty && !AppRules.protectedBundleIdentifiers.contains(app.bundleIdentifier))
                : AppRules.isUserFacing(app)
            
            if searchText.isEmpty {
                return matchesVisibility
            } else {
                return matchesVisibility && (app.name.localizedCaseInsensitiveContains(searchText) || app.bundleIdentifier.localizedCaseInsensitiveContains(searchText))
            }
        }
        
        return filtered.sorted {
            switch sortMode {
            case .name: return $0.name.lowercased() < $1.name.lowercased()
            case .cpu: return $0.cpu > $1.cpu
            case .ram: return $0.ram > $1.ram
            }
        }
    }

    private var scrollViewHeight: CGFloat {
        if appState.apps.isEmpty {
            return 150
        }
        let count = CGFloat(displayApps.count)
        if count == 0 { return 50 } // Minimum height if there are no displayable apps
        
        let rowHeight: CGFloat = 40 // 28 icon + 12 padding
        let spacing: CGFloat = 4
        let verticalPadding: CGFloat = 12 // 6 top + 6 bottom
        
        let totalHeight = (count * rowHeight) + (max(0, count - 1) * spacing) + verticalPadding
        return min(totalHeight, 400)
    }

    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("Closit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    let regularCount = appState.apps.filter { AppRules.isUserFacing($0) }.count
                    let bgCount = appState.apps.filter { !AppRules.isUserFacing($0) && !AppRules.protectedBundleIdentifiers.contains($0.bundleIdentifier) }.count
                    Text("\(regularCount) apps • \(bgCount) background apps")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        appState.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .help("Refresh")
                }
                
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search apps...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    
                    Picker("", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.5)

            // Content
            ScrollView {
                if appState.apps.isEmpty {
                    ContentUnavailableView("No Apps", systemImage: "app.dashed")
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    VStack(spacing: 4) {
                        ForEach(displayApps) { app in
                            AppRowView(
                                app: app,
                                isPinned: appState.isPinned(app),
                                isSelected: appState.isSelected(app),
                                onTogglePinned: {
                                    appState.togglePinned(app)
                                },
                                onSelect: {
                                    appState.toggleSelection(app)
                                },
                                onQuit: { force in
                                    appState.quitApp(app, force: force)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .animation(.default, value: displayApps)
                }
            }
            .frame(height: scrollViewHeight)

            Divider().opacity(0.5)

            // Footer
            HStack {
                let quitCandidates = AppRules.quitCandidates(from: appState.apps, pinnedBundleIdentifiers: appState.settings.pinnedBundleIdentifiers)
                let hasSelection = !appState.selectedAppIDs.isEmpty
                
                if isConfirmingQuit {
                    Text("Are you sure?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        withAnimation { isConfirmingQuit = false }
                    }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                    
                    Button {
                        if hasSelection {
                            appState.quitSelected()
                        } else {
                            appState.quitAll()
                        }
                        isConfirmingQuit = false
                    } label: {
                        Text("Confirm")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    let isQuitAllDisabled = quitCandidates.isEmpty || appState.settings.showBackgroundApps
                    let shouldDisable = !hasSelection && isQuitAllDisabled
                    
                    Button {
                        withAnimation { isConfirmingQuit = true }
                    } label: {
                        Text(hasSelection ? "Quit Selected (\(appState.selectedAppIDs.count))" : (appState.settings.showBackgroundApps ? "Select to Quit" : "Quit All"))
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(hasSelection ? Color.red.opacity(0.8) : (shouldDisable ? Color.secondary.opacity(0.1) : Color.blue))
                            .foregroundColor(shouldDisable ? .secondary : .white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(shouldDisable)
    
                    Spacer()
    
                    SettingsLink {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        NSApp.activate(ignoringOtherApps: true)
                    })
                    .help("Settings")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 320)
    }
}
