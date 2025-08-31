import Foundation
import Combine

class VehicleManager: ObservableObject {
    private let eventBus: EventBus
    private var cancellables = Set<AnyCancellable>()
    private var routeTimers: [UUID: Timer] = [:]
    
    // Reference to shared game state vehicles
    private weak var gameState: GameState?
    
    init(eventBus: EventBus, gameState: GameState) {
        self.eventBus = eventBus
        self.gameState = gameState
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
        gameState?.vehicles.append(vehicle)
    }
    
    func removeVehicle(_ vehicleId: UUID) {
        gameState?.vehicles.removeAll { $0.id == vehicleId }
        routeTimers[vehicleId]?.invalidate()
        routeTimers.removeValue(forKey: vehicleId)
    }
    
    func getAvailableVehicles() -> [Vehicle] {
        gameState?.vehicles.filter { $0.isAvailable } ?? []
    }
    
    func findNearestAvailableVehicle(to location: Location) -> Vehicle? {
        getAvailableVehicles().min { vehicle1, vehicle2 in
            vehicle1.location.distance(to: location) < vehicle2.location.distance(to: location)
        }
    }
    
    private func dispatchVehicle(_ vehicle: Vehicle, on route: Route) {
        guard gameState?.vehicles.firstIndex(where: { $0.id == vehicle.id }) != nil else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let gameState = self?.gameState,
                  let vehicleIndex = gameState.vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
            gameState.vehicles[vehicleIndex].status = .enRoute(route)
            gameState.vehicles[vehicleIndex].currentLoad = Int(route.totalWeight)
            gameState.objectWillChange.send()
        }
        
        let travelTime = route.estimatedDuration
        let startLocation = vehicle.location
        guard let destination = route.waypoints.last else { return }
        
        let updateInterval: TimeInterval = 0.5
        let startTime = Date()
        
        routeTimers[vehicle.id] = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = min(elapsedTime / travelTime, 1.0)
            
            if progress >= 1.0 {
                timer.invalidate()
                self?.eventBus.publish(LogisticsEvent.vehicleArrived(vehicle, at: destination))
            } else {
                self?.updateVehiclePosition(vehicle.id, from: startLocation, to: destination, progress: progress)
            }
        }
    }
    
    private func handleVehicleArrival(_ vehicle: Vehicle, at location: Location) {
        guard let vehicleIndex = gameState?.vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        
        // Get route BEFORE changing status to idle
        if case .enRoute(let route) = gameState?.vehicles[vehicleIndex].status {
            for order in route.orders {
                eventBus.publish(LogisticsEvent.orderFulfilled(order))
            }
        }
        
        // Now update vehicle state
        DispatchQueue.main.async { [weak self] in
            guard let gameState = self?.gameState,
                  let vehicleIndex = gameState.vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
            gameState.vehicles[vehicleIndex].location = location
            gameState.vehicles[vehicleIndex].status = .idle
            gameState.vehicles[vehicleIndex].currentLoad = 0
            gameState.objectWillChange.send()
        }
        
        routeTimers[vehicle.id]?.invalidate()
        routeTimers.removeValue(forKey: vehicle.id)
    }
    
    private func updateVehiclePosition(_ vehicleId: UUID, from start: Location, to end: Location, progress: Double) {
        let interpolatedX = start.x + (end.x - start.x) * progress
        let interpolatedY = start.y + (end.y - start.y) * progress
        
        DispatchQueue.main.async { [weak self] in
            guard let gameState = self?.gameState,
                  let vehicleIndex = gameState.vehicles.firstIndex(where: { $0.id == vehicleId }) else { return }
            gameState.vehicles[vehicleIndex].location = Location(x: interpolatedX, y: interpolatedY)
            gameState.objectWillChange.send()
        }
    }
    
    private func handleVehicleDelay(_ vehicle: Vehicle) {
        
    }
    
    func getVehicleUtilization() -> Double {
        guard let vehicles = gameState?.vehicles else { return 0 }
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