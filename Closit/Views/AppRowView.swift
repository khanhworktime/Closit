import SwiftUI

struct AppRowView: View {
    let app: AppInfo
    let isPinned: Bool
    let isSelected: Bool
    let onTogglePinned: () -> Void
    let onSelect: () -> Void
    let onQuit: (Bool) -> Void // Bool is force quit flag

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let runningApp = NSRunningApplication(processIdentifier: app.processIdentifier),
                       let icon = runningApp.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                    } else {
                        // Fallback
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(app.name.prefix(1)))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white).padding(1))
                        .offset(x: 4, y: 4)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // App Name & Bundle ID
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(app.bundleIdentifier)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("•")
                    Text(String(format: "%.1f%%", app.cpu))
                    Text("•")
                    Text("\(app.ram / 1024) MB")
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Actions (only fully visible when hovering or pinned)
            HStack(spacing: 8) {
                Button {
                    onTogglePinned()
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundColor(isPinned ? .blue : .secondary)
                        .frame(width: 24, height: 24)
                        .background(isPinned ? Color.blue.opacity(0.1) : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(isPinned ? "Unpin" : "Pin")
                .opacity(isPinned || isHovering ? 1.0 : 0.0)

                Button {
                    onQuit(false)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Quit")
                .opacity(isHovering ? 1.0 : 0.0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : (isHovering ? Color.secondary.opacity(0.1) : Color.clear))
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onSelect()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("Force Quit") {
                onQuit(true)
            }
        }
    }
}
