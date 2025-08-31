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
                
                ProgressView(value: progressValue, total: Double(vehicle.capacity))
                    .tint(isOverCapacity ? .red : statusColor)
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