import SwiftUI

struct MapView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.systemGray6)
                
                ForEach(gameState.warehouses) { warehouse in
                    WarehouseMarker(warehouse: warehouse)
                        .position(
                            x: warehouse.location.x * geometry.size.width,
                            y: warehouse.location.y * geometry.size.height
                        )
                }
                
                ForEach(gameState.vehicles) { vehicle in
                    VehicleMarker(vehicle: vehicle)
                        .position(
                            x: vehicle.location.x * geometry.size.width,
                            y: vehicle.location.y * geometry.size.height
                        )
                }
                
                ForEach(gameState.orders) { order in
                    OrderMarker(order: order)
                        .position(
                            x: order.destination.x * geometry.size.width,
                            y: order.destination.y * geometry.size.height
                        )
                }
            }
        }
        .background(Color.systemGray6)
        .cornerRadius(8)
        .padding()
    }
}

struct WarehouseMarker: View {
    let warehouse: Warehouse
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "building.2.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            Text(warehouse.name)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .padding(4)
        .background(
            Circle()
                .fill(Color.white)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 40, height: 40)
        )
    }
}

struct VehicleMarker: View {
    let vehicle: Vehicle
    
    var vehicleIcon: String {
        switch vehicle.type {
        case .van: return "car.fill"
        case .truck: return "truck.box.fill"
        case .drone: return "airplane"
        }
    }
    
    var vehicleColor: Color {
        switch vehicle.status {
        case .idle: return .green
        case .enRoute: return .orange
        case .loading: return .yellow
        case .maintenance: return .red
        }
    }
    
    var body: some View {
        Image(systemName: vehicleIcon)
            .foregroundColor(vehicleColor)
            .font(.title3)
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
            )
    }
}

struct OrderMarker: View {
    let order: Order
    
    var priorityColor: Color {
        switch order.priority {
        case .standard: return .gray
        case .express: return .orange
        case .urgent: return .red
        }
    }
    
    var body: some View {
        Image(systemName: "location.fill")
            .foregroundColor(priorityColor)
            .font(.caption)
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
            )
    }
}