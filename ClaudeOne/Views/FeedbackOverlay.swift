import SwiftUI

struct FeedbackOverlay: View {
    @ObservedObject var feedbackManager: FeedbackManager
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            // Delivery Success Feedbacks
            ForEach(feedbackManager.deliveryFeedbacks, id: \.id) { feedback in
                DeliverySuccessView(feedback: feedback)
                    .position(
                        x: feedback.location.x * geometry.size.width,
                        y: feedback.location.y * geometry.size.height
                    )
            }
            
            // Score Increase Feedbacks (positioned in top area)
            VStack {
                ForEach(feedbackManager.scoreFeedbacks, id: \.id) { feedback in
                    ScoreIncreaseView(feedback: feedback)
                }
                Spacer()
            }
        }
    }
}

struct DeliverySuccessView: View {
    let feedback: DeliveryFeedback
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0
    
    var priorityColor: Color {
        switch feedback.order.priority {
        case .standard: return .green
        case .express: return .orange
        case .urgent: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle with glow effect
                Circle()
                    .fill(priorityColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .blur(radius: 2)
                
                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(priorityColor)
                    .font(.system(size: 32, weight: .bold))
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                    )
            }
            
            // Value display
            Text("$\(Int(feedback.order.value))")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(priorityColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .stroke(priorityColor, lineWidth: 1)
                )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                offset = -20
                opacity = 0.0
            }
        }
    }
}

struct ScoreIncreaseView: View {
    let feedback: ScoreFeedback
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(feedback.scoreIncrease) points")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Total: \(feedback.totalScore)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.2))
                .stroke(Color.yellow, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 2.0).delay(1.0)) {
                offset = -30
                opacity = 0.0
            }
        }
    }
}