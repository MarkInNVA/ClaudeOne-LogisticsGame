import SwiftUI

struct OrdersView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var eventBus: EventBus
    
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
                        OrderRow(order: order, gameState: gameState, eventBus: eventBus)
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
    let gameState: GameState
    let eventBus: EventBus
    
    @State private var showingVehicleSelection = false
    @State private var selectedVehicle: Vehicle?
    
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
            
            HStack {
                Button(action: {
                    showingVehicleSelection = true
                }) {
                    Text("Assign Vehicle")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .disabled(availableVehicles.isEmpty)
                
                Spacer()
                
                if !availableVehicles.isEmpty {
                    Text("\(availableVehicles.count) available")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No vehicles available")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondarySystemBackground)
        )
        .sheet(isPresented: $showingVehicleSelection) {
            VehicleSelectionSheet(
                order: order,
                availableVehicles: availableVehicles,
                eventBus: eventBus,
                onDismiss: { showingVehicleSelection = false }
            )
        }
    }
    
    private var availableVehicles: [Vehicle] {
        gameState.vehicles.filter { $0.isAvailable }
    }
}

struct VehicleSelectionSheet: View {
    let order: Order
    let availableVehicles: [Vehicle]
    let eventBus: EventBus
    let onDismiss: () -> Void
    
    @State private var selectedVehicle: Vehicle?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Order Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assign Vehicle to Order")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Product:")
                        Text(order.product.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Value:")
                        Text("$\(Int(order.value))")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Text("Quantity:")
                        Text("\(order.quantity)")
                            .fontWeight(.medium)
                        Spacer()
                        Text("Priority:")
                        Text(order.priority.description)
                            .fontWeight(.medium)
                            .foregroundColor(priorityColor)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color.secondarySystemBackground)
                .cornerRadius(12)
                
                // Vehicle Selection
                Text("Select Vehicle:")
                    .font(.headline)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(availableVehicles) { vehicle in
                            VehicleSelectionRow(
                                vehicle: vehicle,
                                isSelected: selectedVehicle?.id == vehicle.id,
                                onSelect: { selectedVehicle = vehicle }
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Assign") {
                        assignVehicleToOrder()
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedVehicle == nil)
                }
            }
            .padding()
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
    
    private var priorityColor: Color {
        switch order.priority {
        case .standard: return .gray
        case .express: return .orange
        case .urgent: return .red
        }
    }
    
    private func assignVehicleToOrder() {
        guard let vehicle = selectedVehicle else { return }
        
        let route = Route(
            from: vehicle.location,
            to: [order.destination],
            orders: [order]
        )
        
        eventBus.publish(LogisticsEvent.vehicleDispatched(vehicle, route: route))
    }
}

struct VehicleSelectionRow: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let onSelect: () -> Void
    
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
    
    var body: some View {
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
                
                Text("Available Capacity: \(vehicle.availableCapacity)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondarySystemBackground)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
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