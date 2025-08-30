import Foundation
import Combine

enum GameStatus {
    case menu
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
    
    private var cancellables = Set<AnyCancellable>()
    private let eventBus: EventBus
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        setupEventHandling()
        initializeStartingState()
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
            status = .playing
            
        case .gamePaused:
            status = .paused
            
        case .gameEnded:
            status = .gameOver
            
        case .orderPlaced(let order):
            orders.append(order)
            
        case .orderFulfilled(let order):
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders.remove(at: index)
                completedOrders.append(order)
                budget += order.value
                score += Int(order.value / 10)
            }
            
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
    }
}