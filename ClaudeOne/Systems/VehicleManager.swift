import Foundation
import Combine

class VehicleManager: ObservableObject {
    @Published private(set) var vehicles: [Vehicle] = []
    
    private let eventBus: EventBus
    private var cancellables = Set<AnyCancellable>()
    private var routeTimers: [UUID: Timer] = [:]
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        setupEventHandling()
    }
    
    private func setupEventHandling() {
        eventBus.subscribe(to: LogisticsEvent.self) { [weak self] event in
            self?.handleEvent(event)
        }
        .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: LogisticsEvent) {
        switch event {
        case .vehicleDispatched(let vehicle, let route):
            dispatchVehicle(vehicle, on: route)
            
        case .vehicleArrived(let vehicle, let location):
            handleVehicleArrival(vehicle, at: location)
            
        case .vehicleDelayed(let vehicle):
            handleVehicleDelay(vehicle)
            
        default:
            break
        }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func removeVehicle(_ vehicleId: UUID) {
        vehicles.removeAll { $0.id == vehicleId }
        routeTimers[vehicleId]?.invalidate()
        routeTimers.removeValue(forKey: vehicleId)
    }
    
    func getAvailableVehicles() -> [Vehicle] {
        vehicles.filter { $0.isAvailable }
    }
    
    func findNearestAvailableVehicle(to location: Location) -> Vehicle? {
        getAvailableVehicles().min { vehicle1, vehicle2 in
            vehicle1.location.distance(to: location) < vehicle2.location.distance(to: location)
        }
    }
    
    private func dispatchVehicle(_ vehicle: Vehicle, on route: Route) {
        guard let vehicleIndex = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        
        vehicles[vehicleIndex].status = .enRoute(route)
        vehicles[vehicleIndex].currentLoad = Int(route.totalWeight)
        
        let travelTime = route.estimatedDuration
        
        routeTimers[vehicle.id] = Timer.scheduledTimer(withTimeInterval: travelTime, repeats: false) { [weak self] _ in
            guard let destination = route.waypoints.last else { return }
            self?.eventBus.publish(LogisticsEvent.vehicleArrived(vehicle, at: destination))
        }
    }
    
    private func handleVehicleArrival(_ vehicle: Vehicle, at location: Location) {
        guard let vehicleIndex = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        
        vehicles[vehicleIndex].location = location
        vehicles[vehicleIndex].status = .idle
        vehicles[vehicleIndex].currentLoad = 0
        
        routeTimers[vehicle.id]?.invalidate()
        routeTimers.removeValue(forKey: vehicle.id)
        
        if case .enRoute(let route) = vehicle.status {
            for order in route.orders {
                eventBus.publish(LogisticsEvent.orderFulfilled(order))
            }
        }
    }
    
    private func handleVehicleDelay(_ vehicle: Vehicle) {
        
    }
    
    func getVehicleUtilization() -> Double {
        let totalCapacity = vehicles.reduce(0) { $0 + $1.capacity }
        let totalUsed = vehicles.reduce(0) { $0 + $1.currentLoad }
        
        guard totalCapacity > 0 else { return 0 }
        return Double(totalUsed) / Double(totalCapacity)
    }
    
    deinit {
        routeTimers.values.forEach { $0.invalidate() }
        routeTimers.removeAll()
    }
}