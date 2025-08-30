import Foundation
import Combine

class OrderManager: ObservableObject {
    @Published private(set) var activeOrders: [Order] = []
    @Published private(set) var completedOrders: [Order] = []
    
    private let eventBus: EventBus
    private var cancellables = Set<AnyCancellable>()
    private var orderGenerationTimer: Timer?
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        setupEventHandling()
        startOrderGeneration()
    }
    
    private func setupEventHandling() {
        eventBus.subscribe(to: LogisticsEvent.self) { [weak self] event in
            self?.handleEvent(event)
        }
        .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: LogisticsEvent) {
        switch event {
        case .orderPlaced(let order):
            activeOrders.append(order)
            
        case .orderFulfilled(let order):
            if let index = activeOrders.firstIndex(where: { $0.id == order.id }) {
                activeOrders.remove(at: index)
                completedOrders.append(order)
            }
            
        case .orderDelayed(let order):
            handleDelayedOrder(order)
            
        case .gameStarted:
            startOrderGeneration()
            
        case .gamePaused, .gameEnded:
            stopOrderGeneration()
            
        default:
            break
        }
    }
    
    private func startOrderGeneration() {
        stopOrderGeneration()
        
        orderGenerationTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 5...15), repeats: true) { [weak self] _ in
            self?.generateRandomOrder()
        }
    }
    
    private func stopOrderGeneration() {
        orderGenerationTimer?.invalidate()
        orderGenerationTimer = nil
    }
    
    private func generateRandomOrder() {
        let newOrder = Order.random()
        eventBus.publish(LogisticsEvent.orderPlaced(newOrder))
    }
    
    private func handleDelayedOrder(_ order: Order) {
        
    }
    
    func getOverdueOrders() -> [Order] {
        activeOrders.filter { $0.isOverdue }
    }
    
    func getHighPriorityOrders() -> [Order] {
        activeOrders.filter { $0.priority == .urgent || $0.priority == .express }
    }
    
    func calculateTotalValue() -> Double {
        activeOrders.reduce(0) { $0 + $1.value }
    }
    
    func getOrdersByPriority() -> [Order] {
        activeOrders.sorted { order1, order2 in
            if order1.priority != order2.priority {
                return order1.priority.multiplier > order2.priority.multiplier
            }
            return order1.deadline < order2.deadline
        }
    }
    
    deinit {
        stopOrderGeneration()
    }
}