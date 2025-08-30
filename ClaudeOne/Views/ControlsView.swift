import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var eventBus: EventBus
    
    var body: some View {
        HStack(spacing: 20) {
            Button("Add Order") {
                let newOrder = Order.random()
                eventBus.publish(LogisticsEvent.orderPlaced(newOrder))
            }
            .buttonStyle(.bordered)
            
            Button("Pause Game") {
                eventBus.publish(LogisticsEvent.gamePaused)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Auto Assign") {
                autoAssignOrders()
            }
            .buttonStyle(.borderedProminent)
            .disabled(gameState.orders.isEmpty || !hasAvailableVehicles)
        }
        .padding()
        .background(Color.systemBackground)
    }
    
    private var hasAvailableVehicles: Bool {
        gameState.vehicles.contains { $0.isAvailable }
    }
    
    private func autoAssignOrders() {
        let availableVehicles = gameState.vehicles.filter { $0.isAvailable }
        let pendingOrders = gameState.orders.prefix(availableVehicles.count)
        
        for (vehicle, order) in zip(availableVehicles, pendingOrders) {
            let route = Route(
                from: vehicle.location,
                to: [order.destination],
                orders: [order]
            )
            eventBus.publish(LogisticsEvent.vehicleDispatched(vehicle, route: route))
        }
    }
}
