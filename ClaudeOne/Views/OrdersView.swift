import SwiftUI

struct OrdersView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Orders")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(gameState.orders.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(gameState.orders) { order in
                        OrderRow(order: order)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.systemBackground)
    }
}

struct OrderRow: View {
    let order: Order
    
    var priorityColor: Color {
        switch order.priority {
        case .standard: return .gray
        case .express: return .orange
        case .urgent: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(order.product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("$\(Int(order.value))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Qty: \(order.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(order.priority.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(priorityColor.opacity(0.15))
                    )
            }
            
            if order.isOverdue {
                Text("OVERDUE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondarySystemBackground)
        )
    }
}

extension OrderPriority {
    var description: String {
        switch self {
        case .standard: return "Standard"
        case .express: return "Express"
        case .urgent: return "Urgent"
        }
    }
}