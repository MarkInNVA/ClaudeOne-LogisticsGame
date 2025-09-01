import SwiftUI

struct AchievementPopup: View {
    let achievement: Achievement
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = -15
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement Icon
            ZStack {
                Circle()
                    .fill(achievement.type.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(achievement.type.color, lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.type.icon)
                    .foregroundColor(achievement.type.color)
                    .font(.system(size: 24, weight: .bold))
            }
            .rotationEffect(.degrees(rotation))
            
            // Achievement Details
            VStack(alignment: .leading, spacing: 4) {
                Text("🏆 Achievement Unlocked!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(achievement.type.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(achievement.type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(achievement.type.color.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: achievement.type.color.opacity(0.3), radius: 10, x: 0, y: 5)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                scale = 1.0
                opacity = 1.0
                rotation = 0
            }
        }
    }
}

struct AchievementOverlay: View {
    @ObservedObject var achievementManager: AchievementManager
    
    var body: some View {
        VStack {
            if let achievement = achievementManager.showAchievementPopup {
                AchievementPopup(achievement: achievement)
                    .padding(.horizontal, 20)
                    .padding(.top, 60) // Account for status bar and nav
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale)
                    ))
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5), value: achievementManager.showAchievementPopup != nil)
    }
}