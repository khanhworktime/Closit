import SwiftUI

struct MenuContentView: View {
    @ObservedObject var appState: ClositAppState
    @State private var searchText = ""
    @State private var isConfirmingQuit = false
    @State private var isConfirmingAppQuit = false

    var body: some View {
        Group {
            if !appState.settings.hasSeenOnboarding {
                OnboardingView(appState: appState)
            } else {
                mainContentView
            }
        }
        // Removed `.background(.ultraThinMaterial)` because NSPopover handles the frosted glass beautifully.
        .onAppear {
            appState.refresh()
            isConfirmingQuit = false
            isConfirmingAppQuit = false
        }
        .overlay {
            if isConfirmingAppQuit {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        HStack(alignment: .top, spacing: 16) {
                            Image(nsImage: NSApplication.shared.applicationIconImage)
                                .resizable()
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quit Closit?")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Are you sure you want to completely quit Closit? Auto-quit rules and background app management will be disabled.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Spacer()
                            Button("Cancel") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isConfirmingAppQuit = false }
                            }
                            .keyboardShortcut(.cancelAction)
                            .controlSize(.regular)
                            
                            Button("Quit") {
                                NSApplication.shared.terminate(nil)
                            }
                            .keyboardShortcut(.defaultAction)
                            .controlSize(.regular)
                        }
                    }
                    .padding(20)
                    .frame(width: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .transition(.opacity)
                .zIndex(100)
            }
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
            return $0.cpu > $1.cpu
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
                    
                    Button {
                        withAnimation { isConfirmingAppQuit = true }
                    } label: {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .help("Quit Closit")
                }
                
                HStack(spacing: 8) {
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
                    
                    Button {
                        appState.settings.showBackgroundApps.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: appState.settings.showBackgroundApps ? "eye.fill" : "eye.slash")
                            Text("Background")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(appState.settings.showBackgroundApps ? .blue : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(appState.settings.showBackgroundApps ? "Hide background apps" : "Show background apps")
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
    
                    Button {
                        AppDelegate.shared?.openSettings()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 320)
    }
}
