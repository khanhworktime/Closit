import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: ClositAppState
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Icon / Logo
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            // Welcome Text
            VStack(spacing: 8) {
                Text("Welcome to Closit")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Keep your Mac fast and clean by effortlessly managing background applications.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Feature List
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "bolt.fill", color: .yellow, title: "Lightning Fast", description: "Quit multiple apps in just one click.")
                FeatureRow(icon: "pin.fill", color: .blue, title: "Pin Favorites", description: "Protect essential apps from being closed.")
                FeatureRow(icon: "timer", color: .green, title: "Auto Quit", description: "Automatically close apps when idle.")
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            // CTA Button
            Button {
                withAnimation(.spring()) {
                    appState.completeOnboarding()
                }
            } label: {
                Text("Get Started")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                            .shadow(color: Color.blue.opacity(isHovering ? 0.5 : 0.0), radius: 8, y: 4)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        // Background handles glassmorphism natively in MenuContentView
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
