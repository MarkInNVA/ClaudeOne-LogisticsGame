import SwiftUI
import Combine

enum AchievementType: String, CaseIterable, Codable {
    // Delivery Milestones
    case firstDelivery = "first_delivery"
    case speedDemon = "speed_demon"
    case efficiencyExpert = "efficiency_expert"
    case highValueHandler = "high_value_handler"
    
    // Fleet Management
    case fleetCommander = "fleet_commander"
    case multiTasker = "multi_tasker"
    case capacityMaster = "capacity_master"
    
    // Business Success
    case profitable = "profitable"
    case rapidGrowth = "rapid_growth"
    case consistentPerformer = "consistent_performer"
    
    var title: String {
        switch self {
        case .firstDelivery: return "First Delivery"
        case .speedDemon: return "Speed Demon"
        case .efficiencyExpert: return "Efficiency Expert"
        case .highValueHandler: return "High Value Handler"
        case .fleetCommander: return "Fleet Commander"
        case .multiTasker: return "Multi-tasker"
        case .capacityMaster: return "Capacity Master"
        case .profitable: return "Profitable"
        case .rapidGrowth: return "Rapid Growth"
        case .consistentPerformer: return "Consistent Performer"
        }
    }
    
    var description: String {
        switch self {
        case .firstDelivery: return "Complete your first order"
        case .speedDemon: return "Complete 10 deliveries in 5 minutes"
        case .efficiencyExpert: return "100% vehicle utilization for 10 minutes"
        case .highValueHandler: return "Complete $10,000+ order"
        case .fleetCommander: return "Own 5 vehicles simultaneously"
        case .multiTasker: return "Have all vehicles active at once"
        case .capacityMaster: return "Fill a vehicle to 100% capacity"
        case .profitable: return "Reach $100,000 budget"
        case .rapidGrowth: return "Double your score in 5 minutes"
        case .consistentPerformer: return "Complete 50 orders without failure"
        }
    }
    
    var icon: String {
        switch self {
        case .firstDelivery: return "checkmark.seal.fill"
        case .speedDemon: return "bolt.fill"
        case .efficiencyExpert: return "gauge.high"
        case .highValueHandler: return "dollarsign.circle.fill"
        case .fleetCommander: return "crown.fill"
        case .multiTasker: return "arrow.triangle.branch"
        case .capacityMaster: return "cube.box.fill"
        case .profitable: return "banknote.fill"
        case .rapidGrowth: return "chart.line.uptrend.xyaxis"
        case .consistentPerformer: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .firstDelivery: return .green
        case .speedDemon: return .orange
        case .efficiencyExpert: return .blue
        case .highValueHandler: return .yellow
        case .fleetCommander: return .purple
        case .multiTasker: return .red
        case .capacityMaster: return .cyan
        case .profitable: return .mint
        case .rapidGrowth: return .pink
        case .consistentPerformer: return .indigo
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id = UUID()
    let type: AchievementType
    let unlockedAt: Date
    
    init(type: AchievementType) {
        self.type = type
        self.unlockedAt = Date()
    }
}

struct AchievementProgress {
    let type: AchievementType
    var currentValue: Double
    let targetValue: Double
    
    var progress: Double {
        min(currentValue / targetValue, 1.0)
    }
    
    var isCompleted: Bool {
        currentValue >= targetValue
    }
}

class AchievementManager: ObservableObject {
    @Published var unlockedAchievements: Set<AchievementType> = []
    @Published var showAchievementPopup: Achievement?
    
    // Progress tracking
    private var deliveryCount = 0
    private var deliveriesInLast5Min: [Date] = []
    private var completedOrdersCount = 0
    private var gameStartTime: Date?
    private var initialScore = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let eventBus: EventBus
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
        case .gameStarted:
            gameStartTime = Date()
            initialScore = gameState?.score ?? 0
            
        case .deliverySuccessful(let order, _):
            handleDeliverySuccess(order)
            
        case .orderFulfilled(let order):
            handleOrderFulfilled(order)
            
        case .vehicleDispatched(_, _):
            checkMultiTaskerAchievement()
            
        case .budgetChanged(let newBudget):
            checkProfitableAchievement(budget: newBudget)
            
        case .scoreIncreased(_, let totalScore):
            checkRapidGrowthAchievement(currentScore: totalScore)
            
        default:
            break
        }
    }
    
    private func handleDeliverySuccess(_ order: Order) {
        deliveryCount += 1
        deliveriesInLast5Min.append(Date())
        
        // Remove deliveries older than 5 minutes
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        deliveriesInLast5Min.removeAll { $0 < fiveMinutesAgo }
        
        // Check achievements
        checkFirstDeliveryAchievement()
        checkSpeedDemonAchievement()
        checkHighValueHandlerAchievement(order: order)
        checkCapacityMasterAchievement()
    }
    
    private func handleOrderFulfilled(_ order: Order) {
        completedOrdersCount += 1
        checkConsistentPerformerAchievement()
    }
    
    // Achievement Checks
    private func checkFirstDeliveryAchievement() {
        if deliveryCount == 1 && !unlockedAchievements.contains(.firstDelivery) {
            unlockAchievement(.firstDelivery)
        }
    }
    
    private func checkSpeedDemonAchievement() {
        if deliveriesInLast5Min.count >= 10 && !unlockedAchievements.contains(.speedDemon) {
            unlockAchievement(.speedDemon)
        }
    }
    
    private func checkHighValueHandlerAchievement(order: Order) {
        if order.value >= 10000 && !unlockedAchievements.contains(.highValueHandler) {
            unlockAchievement(.highValueHandler)
        }
    }
    
    private func checkCapacityMasterAchievement() {
        guard let vehicles = gameState?.vehicles else { return }
        
        let hasFullCapacityVehicle = vehicles.contains { vehicle in
            vehicle.currentLoad >= vehicle.capacity && vehicle.capacity > 0
        }
        
        if hasFullCapacityVehicle && !unlockedAchievements.contains(.capacityMaster) {
            unlockAchievement(.capacityMaster)
        }
    }
    
    private func checkFleetCommanderAchievement() {
        guard let vehicles = gameState?.vehicles else { return }
        
        if vehicles.count >= 5 && !unlockedAchievements.contains(.fleetCommander) {
            unlockAchievement(.fleetCommander)
        }
    }
    
    private func checkMultiTaskerAchievement() {
        guard let vehicles = gameState?.vehicles else { return }
        
        let allVehiclesActive = vehicles.count > 1 && vehicles.allSatisfy { vehicle in
            if case .enRoute = vehicle.status {
                return true
            }
            return false
        }
        
        if allVehiclesActive && !unlockedAchievements.contains(.multiTasker) {
            unlockAchievement(.multiTasker)
        }
    }
    
    private func checkProfitableAchievement(budget: Double) {
        if budget >= 100000 && !unlockedAchievements.contains(.profitable) {
            unlockAchievement(.profitable)
        }
    }
    
    private func checkRapidGrowthAchievement(currentScore: Int) {
        guard let gameStartTime = gameStartTime else { return }
        
        let gameTime = Date().timeIntervalSince(gameStartTime)
        if gameTime >= 300 { // 5 minutes
            let scoreGrowth = currentScore - initialScore
            if scoreGrowth >= initialScore && initialScore > 0 && !unlockedAchievements.contains(.rapidGrowth) {
                unlockAchievement(.rapidGrowth)
            }
        }
    }
    
    private func checkConsistentPerformerAchievement() {
        if completedOrdersCount >= 50 && !unlockedAchievements.contains(.consistentPerformer) {
            unlockAchievement(.consistentPerformer)
        }
    }
    
    private func unlockAchievement(_ type: AchievementType) {
        let achievement = Achievement(type: type)
        
        DispatchQueue.main.async { [weak self] in
            self?.unlockedAchievements.insert(type)
            self?.showAchievementPopup = achievement
        }
        
        // Auto-hide popup after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            if self?.showAchievementPopup?.type == type {
                self?.showAchievementPopup = nil
            }
        }
    }
}