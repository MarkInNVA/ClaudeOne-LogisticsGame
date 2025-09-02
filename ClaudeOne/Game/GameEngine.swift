import Foundation
import Combine

class GameEngine: ObservableObject {
    @Published var isRunning = false
    
    private let eventBus: EventBus
    private let gameState: GameState
    private let orderManager: OrderManager
    private let warehouseManager: WarehouseManager
    private let vehicleManager: VehicleManager
    private let feedbackManager: FeedbackManager
    private let achievementManager: AchievementManager
    private let weatherManager: WeatherManager
    
    private var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    
    init(eventBus: EventBus, gameState: GameState) {
        self.eventBus = eventBus
        self.gameState = gameState
        self.orderManager = OrderManager(eventBus: eventBus)
        self.warehouseManager = WarehouseManager(eventBus: eventBus)
        self.weatherManager = WeatherManager()
        self.vehicleManager = VehicleManager(eventBus: eventBus, gameState: gameState, weatherManager: weatherManager)
        self.feedbackManager = FeedbackManager(eventBus: eventBus)
        self.achievementManager = AchievementManager(eventBus: eventBus, gameState: gameState)
        
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
        weatherManager.startWeatherSystem()
        startGameLoop()
    }
    
    private func pauseGame() {
        isRunning = false
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func endGame() {
        isRunning = false
        weatherManager.stopWeatherSystem()
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
        let vehicleCosts = gameState.vehicles.reduce(0) { total, vehicle in
            total + vehicle.type.operatingCost
        }
        
        return (warehouseCosts + vehicleCosts) / 3600.0
    }
    
    private func tryAutoAssignOrder(_ order: Order) {
        // Check if order is still available (not already assigned)
        guard gameState.orders.contains(where: { $0.id == order.id }) else {
            return // Order already assigned
        }
        
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
        
        // Vehicles are already initialized in GameState, no need to add them again
        
        // Create initial tutorial order if tutorial is active
        if gameState.status == .tutorial && !UserDefaults.standard.bool(forKey: "tutorial_completed") {
            createTutorialOrder()
        }
    }
    
    private func createTutorialOrder() {
        let tutorialOrder = Order(
            product: Product.electronics,
            quantity: 1,
            destination: Location(x: 0.8, y: 0.2),
            priority: .standard,
            placedAt: Date(),
            deadline: Date().addingTimeInterval(300) // 5 minutes
        )
        
        eventBus.publish(LogisticsEvent.orderPlaced(tutorialOrder))
    }
    
    var feedback: FeedbackManager {
        return feedbackManager
    }
    
    var achievements: AchievementManager {
        return achievementManager
    }
    
    var weather: WeatherManager {
        return weatherManager
    }
    
    func tryAutoAssign(_ order: Order) {
        tryAutoAssignOrder(order)
    }
    
    deinit {
        gameTimer?.invalidate()
    }
}