import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        HStack {
            MetricCard(title: "Budget", value: String(format: "$%.0f", gameState.budget), color: .green)
            MetricCard(title: "Score", value: "\(gameState.score)", color: .blue)
            MetricCard(title: "Active Orders", value: "\(gameState.orders.count)", color: .orange)
            MetricCard(title: "Completed", value: "\(gameState.completedOrders.count)", color: .purple)
            MetricCard(title: "On Time Rate", value: String(format: "%.0f%%", gameState.performanceMetrics.onTimeDeliveryRate * 100), color: .cyan)
        }
        .padding()
        .background(Color.systemBackground)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}