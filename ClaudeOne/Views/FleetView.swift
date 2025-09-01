import SwiftUI

struct FleetView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Fleet")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(gameState.vehicles.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(gameState.vehicles) { vehicle in
                        VehicleRow(vehicle: vehicle)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.systemBackground)
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    
    var vehicleIcon: String {
        switch vehicle.type {
        case .van: return "car.fill"
        case .truck: return "truck.box.fill"
        case .drone: return "airplane"
        }
    }
    
    var statusColor: Color {
        switch vehicle.status {
        case .idle: return .green
        case .enRoute: return .orange
        case .loading: return .yellow
        case .maintenance: return .red
        }
    }
    
    var statusText: String {
        switch vehicle.status {
        case .idle: return "Idle"
        case .enRoute: return "En Route"
        case .loading: return "Loading"
        case .maintenance: return "Maintenance"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: vehicleIcon)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.type.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Capacity: \(vehicle.currentLoad)/\(vehicle.capacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
            }
            
            if vehicle.currentLoad > 0 && vehicle.capacity > 0 {
                let progressValue = min(max(Double(vehicle.currentLoad), 0), Double(vehicle.capacity))
                let isOverCapacity = vehicle.currentLoad > vehicle.capacity
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Load:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(vehicle.currentLoad)/\(vehicle.capacity)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: progressValue, total: Double(vehicle.capacity))
                        .tint(isOverCapacity ? .red : statusColor)
                }
            }
            
            // Route Progress for en route vehicles
            if case .enRoute(let route) = vehicle.status {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Route Progress:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("In Transit")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Distance:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f km", route.totalDistance))
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Orders:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(route.orders.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Est. Duration:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f min", route.estimatedDuration / 60))
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Value:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("$\(Int(route.totalValue))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    // Route progress bar (simulated progress)
                    ProgressView(value: 0.3, total: 1.0)
                        .tint(.orange)
                }
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

extension VehicleType {
    var description: String {
        switch self {
        case .van: return "Van"
        case .truck: return "Truck"
        case .drone: return "Drone"
        }
    }
}