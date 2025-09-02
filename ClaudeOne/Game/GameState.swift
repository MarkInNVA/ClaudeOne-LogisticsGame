import Foundation
import Combine

enum GameStatus {
    case menu
    case tutorial
    case playing
    case paused
    case gameOver
}

class GameState: ObservableObject {
    @Published var status: GameStatus = .menu
    @Published var budget: Double = 50000.0
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var gameTime: TimeInterval = 0
    
    @Published var warehouses: [Warehouse] = []
    @Published var vehicles: [Vehicle] = []
    @Published var orders: [Order] = []
    @Published var completedOrders: [Order] = []
    
    @Published var performanceMetrics = PerformanceMetrics()
    
    // Tutorial and Level Systems
    @Published var tutorialSystem: TutorialSystem!
    @Published var levelSystem: LevelSystem!
    
    private var cancellables = Set<AnyCancellable>()
    private let eventBus: EventBus
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        setupEventHandling()
        initializeStartingState()
        initializeSystems()
    }
    
    private func setupEventHandling() {
        eventBus.subscribe(to: LogisticsEvent.self) { [weak self] event in
            self?.handleEvent(event)
        }
        .store(in: &cancellables)
        
        eventBus.subscribe(to: TutorialEvent.self) { [weak self] event in
            self?.handleTutorialEvent(event)
        }
        .store(in: &cancellables)
        
        eventBus.subscribe(to: LevelEvent.self) { [weak self] event in
            self?.handleLevelEvent(event)
        }
        .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: LogisticsEvent) {
        switch event {
        case .gameStarted:
            if !UserDefaults.standard.bool(forKey: "tutorial_completed") {
                status = .tutorial
            } else {
                status = .playing
            }
            
        case .gamePaused:
            status = .paused
            
        case .gameEnded:
            status = .gameOver
            
        case .orderPlaced(let order):
            orders.append(order)
            
        case .vehicleDispatched(_, let route):
            // Remove assigned orders from available orders list
            for order in route.orders {
                if let index = orders.firstIndex(where: { $0.id == order.id }) {
                    orders.remove(at: index)
                }
            }
            
        case .orderFulfilled(let order):
            // Order should already be removed from orders list when vehicle was dispatched
            // Just add to completed orders and update budget/score
            completedOrders.append(order)
            budget += order.value
            let scoreIncrease = Int(order.value / 10)
            score += scoreIncrease
            // Publish score increase for feedback
            eventBus.publish(LogisticsEvent.scoreIncreased(by: scoreIncrease, total: score))
            
        case .budgetChanged(let newBudget):
            budget = newBudget
            
        case .performanceUpdated(let metrics):
            performanceMetrics = metrics
            
        default:
            break
        }
    }
    
    private func initializeStartingState() {
        let mainWarehouse = Warehouse(
            name: "Main Warehouse",
            location: Location(x: 0.5, y: 0.5),
            capacity: 1000,
            inventory: [:]
        )
        warehouses.append(mainWarehouse)
        
        let truck = Vehicle(
            type: .truck,
            capacity: 500,
            speed: 60.0,
            location: mainWarehouse.location
        )
        vehicles.append(truck)
        
        let van = Vehicle(
            type: .van,
            capacity: 200,
            speed: 80.0,
            location: Location(x: 0.3, y: 0.7)
        )
        vehicles.append(van)
        
        let drone = Vehicle(
            type: .drone,
            capacity: 50,
            speed: 120.0,
            location: Location(x: 0.7, y: 0.3)
        )
        vehicles.append(drone)
    }
    
    private func initializeSystems() {
        tutorialSystem = TutorialSystem(eventBus: eventBus, gameState: self)
        levelSystem = LevelSystem(eventBus: eventBus)
    }
    
    private func handleTutorialEvent(_ event: TutorialEvent) {
        switch event {
        case .started:
            status = .tutorial
            
        case .completed:
            status = .playing
            
        case .stepChanged(_):
            break
        }
    }
    
    private func handleLevelEvent(_ event: LevelEvent) {
        switch event {
        case .experienceGained(_):
            break
            
        case .levelUp(let newLevel):
            level = newLevel
        }
    }
}