import Foundation
import Combine

class GameEngine: ObservableObject {
    @Published var isRunning = false
    
    private let eventBus: EventBus
    private let gameState: GameState
    private let orderManager: OrderManager
    private let warehouseManager: WarehouseManager
    private let vehicleManager: VehicleManager
    
    private var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    
    init(eventBus: EventBus, gameState: GameState) {
        self.eventBus = eventBus
        self.gameState = gameState
        self.orderManager = OrderManager(eventBus: eventBus)
        self.warehouseManager = WarehouseManager(eventBus: eventBus)
        self.vehicleManager = VehicleManager(eventBus: eventBus)
        
        setupEventHandling()
        initializeGame()
    }
    
    private func setupEventHandling() {
        eventBus.subscribe(to: LogisticsEvent.self) { [weak self] event in
            self?.handleEvent(event)
        }
        .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: LogisticsEvent) {
        switch event {
        case .gameStarted:
            startGame()
            
        case .gamePaused:
            pauseGame()
            
        case .gameEnded:
            endGame()
            
        case .orderPlaced(let order):
            tryAutoAssignOrder(order)
            
        case .vehicleDispatched(let vehicle, let route):
            handleVehicleDispatch(vehicle: vehicle, route: route)
            
        case .orderFulfilled(let order):
            updatePerformanceMetrics(for: order)
            
        default:
            break
        }
    }
    
    private func startGame() {
        isRunning = true
        startGameLoop()
    }
    
    private func pauseGame() {
        isRunning = false
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func endGame() {
        isRunning = false
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.gameLoop()
        }
    }
    
    private func gameLoop() {
        guard isRunning else { return }
        
        checkForOverdueOrders()
        updateBudgetAndCosts()
        updatePerformanceMetrics()
    }
    
    private func checkForOverdueOrders() {
        let overdueOrders = orderManager.getOverdueOrders()
        for order in overdueOrders {
            eventBus.publish(LogisticsEvent.orderDelayed(order))
            gameState.budget -= order.value * 0.1
        }
    }
    
    private func updateBudgetAndCosts() {
        let operatingCosts = calculateOperatingCosts()
        gameState.budget -= operatingCosts
        
        if gameState.budget <= 0 {
            eventBus.publish(LogisticsEvent.gameEnded)
        }
        
        eventBus.publish(LogisticsEvent.budgetChanged(gameState.budget))
    }
    
    private func calculateOperatingCosts() -> Double {
        let warehouseCosts = warehouseManager.warehouses.reduce(0) { $0 + $1.operatingCost }
        let vehicleCosts = vehicleManager.vehicles.reduce(0) { total, vehicle in
            total + vehicle.type.operatingCost
        }
        
        return (warehouseCosts + vehicleCosts) / 3600.0
    }
    
    private func tryAutoAssignOrder(_ order: Order) {
        guard let sourceWarehouse = warehouseManager.allocateInventory(for: order) else {
            return
        }
        
        guard let vehicle = vehicleManager.findNearestAvailableVehicle(to: sourceWarehouse.location) else {
            return
        }
        
        let route = Route(
            from: sourceWarehouse.location,
            to: [order.destination],
            orders: [order]
        )
        
        if route.totalWeight <= Double(vehicle.availableCapacity) {
            eventBus.publish(LogisticsEvent.vehicleDispatched(vehicle, route: route))
        }
    }
    
    private func handleVehicleDispatch(vehicle: Vehicle, route: Route) {
        let totalCost = route.totalDistance * 0.1
        gameState.budget -= totalCost
        gameState.performanceMetrics.addCost(totalCost)
    }
    
    private func updatePerformanceMetrics(for order: Order) {
        let deliveryTime = Date().timeIntervalSince(order.placedAt)
        let wasOnTime = !order.isOverdue
        
        gameState.performanceMetrics.updateDeliveryMetrics(
            deliveryTime: deliveryTime,
            wasOnTime: wasOnTime
        )
        
        gameState.performanceMetrics.addRevenue(order.value)
        
        let vehicleUtilization = vehicleManager.getVehicleUtilization()
        let warehouseUtilization = warehouseManager.warehouses.reduce(0.0) { total, warehouse in
            total + warehouse.utilizationRate
        } / Double(warehouseManager.warehouses.count)
        
        gameState.performanceMetrics.updateEfficiency(
            vehicleUtilization: vehicleUtilization,
            warehouseUtilization: warehouseUtilization
        )
        
        eventBus.publish(LogisticsEvent.performanceUpdated(gameState.performanceMetrics))
    }
    
    private func updatePerformanceMetrics() {
        let overdueCount = orderManager.getOverdueOrders().count
        let totalOrders = orderManager.activeOrders.count + orderManager.completedOrders.count
        
        if totalOrders > 0 {
            gameState.performanceMetrics.onTimeDeliveryRate = 
                Double(totalOrders - overdueCount) / Double(totalOrders)
        }
        
        eventBus.publish(LogisticsEvent.performanceUpdated(gameState.performanceMetrics))
    }
    
    private func initializeGame() {
        for warehouse in gameState.warehouses {
            warehouseManager.addWarehouse(warehouse)
            
            for product in Product.allProducts {
                let initialStock = Int.random(in: 20...50)
                if var updatedWarehouse = warehouseManager.warehouses.first(where: { $0.id == warehouse.id }) {
                    _ = updatedWarehouse.addStock(product, quantity: initialStock)
                }
            }
        }
        
        for vehicle in gameState.vehicles {
            vehicleManager.addVehicle(vehicle)
        }
    }
    
    deinit {
        gameTimer?.invalidate()
    }
}