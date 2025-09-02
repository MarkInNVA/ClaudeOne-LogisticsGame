import Foundation
import Combine

struct LevelRequirements {
    let level: Int
    let experienceRequired: Int
    let title: String
    let description: String
    let unlocks: [LevelUnlock]
    
    static let allLevels: [LevelRequirements] = [
        LevelRequirements(
            level: 1,
            experienceRequired: 0,
            title: "Logistics Apprentice",
            description: "Starting your logistics journey",
            unlocks: [.vehicleType(.van), .basicFeatures]
        ),
        LevelRequirements(
            level: 2,
            experienceRequired: 500,
            title: "Route Manager",
            description: "Learning efficient delivery routes",
            unlocks: [.vehicleType(.truck), .multiStopRoutes]
        ),
        LevelRequirements(
            level: 3,
            experienceRequired: 1200,
            title: "Fleet Coordinator",
            description: "Managing multiple vehicles",
            unlocks: [.vehicleType(.drone), .advancedAnalytics]
        ),
        LevelRequirements(
            level: 4,
            experienceRequired: 2000,
            title: "Operations Specialist",
            description: "Optimizing warehouse operations",
            unlocks: [.warehouseUpgrades, .contractSystem]
        ),
        LevelRequirements(
            level: 5,
            experienceRequired: 3000,
            title: "Supply Chain Expert",
            description: "Mastering complex logistics networks",
            unlocks: [.emergencyOrders, .weatherPrediction]
        ),
        LevelRequirements(
            level: 6,
            experienceRequired: 4500,
            title: "Logistics Director",
            description: "Leading large-scale operations",
            unlocks: [.automatedDispatching, .crossDocking]
        ),
        LevelRequirements(
            level: 7,
            experienceRequired: 6500,
            title: "Industry Pioneer",
            description: "Innovation in logistics technology",
            unlocks: [.aiOptimization, .dynamicPricing]
        ),
        LevelRequirements(
            level: 8,
            experienceRequired: 9000,
            title: "Global Operations Chief",
            description: "Managing worldwide supply chains",
            unlocks: [.multiRegionalOperations, .advancedContracts]
        ),
        LevelRequirements(
            level: 9,
            experienceRequired: 12500,
            title: "Logistics Visionary",
            description: "Shaping the future of logistics",
            unlocks: [.quantumOptimization, .predictiveAnalytics]
        ),
        LevelRequirements(
            level: 10,
            experienceRequired: 17000,
            title: "Supply Chain Master",
            description: "Ultimate logistics mastery achieved",
            unlocks: [.allFeatures, .masterMode]
        )
    ]
}

enum LevelUnlock: Hashable {
    case vehicleType(VehicleType)
    case basicFeatures
    case multiStopRoutes
    case advancedAnalytics
    case warehouseUpgrades
    case contractSystem
    case emergencyOrders
    case weatherPrediction
    case automatedDispatching
    case crossDocking
    case aiOptimization
    case dynamicPricing
    case multiRegionalOperations
    case advancedContracts
    case quantumOptimization
    case predictiveAnalytics
    case allFeatures
    case masterMode
    
    var displayName: String {
        switch self {
        case .vehicleType(let type):
            return "\(type.displayName) Vehicles"
        case .basicFeatures:
            return "Basic Features"
        case .multiStopRoutes:
            return "Multi-Stop Routes"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .warehouseUpgrades:
            return "Warehouse Upgrades"
        case .contractSystem:
            return "Contract System"
        case .emergencyOrders:
            return "Emergency Orders"
        case .weatherPrediction:
            return "Weather Prediction"
        case .automatedDispatching:
            return "Auto-Dispatching"
        case .crossDocking:
            return "Cross-Docking"
        case .aiOptimization:
            return "AI Route Optimization"
        case .dynamicPricing:
            return "Dynamic Pricing"
        case .multiRegionalOperations:
            return "Multi-Regional Ops"
        case .advancedContracts:
            return "Advanced Contracts"
        case .quantumOptimization:
            return "Quantum Optimization"
        case .predictiveAnalytics:
            return "Predictive Analytics"
        case .allFeatures:
            return "All Features"
        case .masterMode:
            return "Master Mode"
        }
    }
    
    var description: String {
        switch self {
        case .vehicleType(let type):
            return "Unlock \(type.displayName) vehicles for your fleet"
        case .basicFeatures:
            return "Access to core logistics features"
        case .multiStopRoutes:
            return "Vehicles can handle multiple deliveries per trip"
        case .advancedAnalytics:
            return "Detailed performance metrics and insights"
        case .warehouseUpgrades:
            return "Upgrade warehouse capacity and efficiency"
        case .contractSystem:
            return "Long-term customer contracts with bonuses"
        case .emergencyOrders:
            return "High-value, time-critical deliveries"
        case .weatherPrediction:
            return "Predict weather impacts on operations"
        case .automatedDispatching:
            return "AI automatically assigns optimal routes"
        case .crossDocking:
            return "Transfer goods efficiently between warehouses"
        case .aiOptimization:
            return "Advanced AI route and resource optimization"
        case .dynamicPricing:
            return "Orders with variable pricing based on demand"
        case .multiRegionalOperations:
            return "Expand operations across multiple regions"
        case .advancedContracts:
            return "Complex multi-tier customer agreements"
        case .quantumOptimization:
            return "Quantum computing for ultimate optimization"
        case .predictiveAnalytics:
            return "Predict market trends and demand patterns"
        case .allFeatures:
            return "Access to all game features and modes"
        case .masterMode:
            return "Ultimate challenge mode for experts"
        }
    }
}

struct PlayerLevel {
    let level: Int
    let experience: Int
    let requirements: LevelRequirements
    let unlockedFeatures: Set<LevelUnlock>
    
    var progressToNext: Double {
        guard let nextLevel = LevelRequirements.allLevels.first(where: { $0.level == level + 1 }) else {
            return 1.0
        }
        
        let currentReq = requirements.experienceRequired
        let nextReq = nextLevel.experienceRequired
        let progress = Double(experience - currentReq) / Double(nextReq - currentReq)
        
        return max(0, min(1, progress))
    }
    
    var experienceToNext: Int {
        guard let nextLevel = LevelRequirements.allLevels.first(where: { $0.level == level + 1 }) else {
            return 0
        }
        
        return max(0, nextLevel.experienceRequired - experience)
    }
    
    var isMaxLevel: Bool {
        return level >= LevelRequirements.allLevels.count
    }
}

class LevelSystem: ObservableObject {
    @Published var currentLevel: PlayerLevel
    @Published var showLevelUpNotification: LevelRequirements?
    
    private var cancellables = Set<AnyCancellable>()
    private let eventBus: EventBus
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        
        let savedLevel = UserDefaults.standard.integer(forKey: "player_level")
        let savedExperience = UserDefaults.standard.integer(forKey: "player_experience")
        
        let levelReq = LevelRequirements.allLevels.first { $0.level == max(1, savedLevel) } ?? LevelRequirements.allLevels[0]
        let unlockedFeatures = Self.calculateUnlockedFeatures(for: max(1, savedLevel))
        
        self.currentLevel = PlayerLevel(
            level: max(1, savedLevel),
            experience: savedExperience,
            requirements: levelReq,
            unlockedFeatures: unlockedFeatures
        )
        
        setupEventHandling()
    }
    
    private static func calculateUnlockedFeatures(for level: Int) -> Set<LevelUnlock> {
        var unlocked = Set<LevelUnlock>()
        
        for levelReq in LevelRequirements.allLevels {
            if levelReq.level <= level {
                unlocked.formUnion(levelReq.unlocks)
            }
        }
        
        return unlocked
    }
    
    private func setupEventHandling() {
        eventBus.subscribe(to: LogisticsEvent.self) { [weak self] event in
            self?.handleEvent(event)
        }
        .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: LogisticsEvent) {
        switch event {
        case .orderFulfilled(let order):
            addExperience(Int(order.value / 10))
            
        case .scoreIncreased(let increase, _):
            addExperience(increase / 10)
            
        case .performanceUpdated(let metrics):
            if metrics.onTimeDeliveryRate >= 0.95 {
                addExperience(5)
            }
            
        default:
            break
        }
    }
    
    private func addExperience(_ amount: Int) {
        let newExperience = currentLevel.experience + amount
        
        checkForLevelUp(newExperience: newExperience)
        saveProgress()
    }
    
    private func checkForLevelUp(newExperience: Int) {
        var newLevel = currentLevel.level
        
        while let nextLevelReq = LevelRequirements.allLevels.first(where: { $0.level == newLevel + 1 }) {
            if newExperience >= nextLevelReq.experienceRequired {
                newLevel += 1
                
                DispatchQueue.main.async {
                    self.showLevelUpNotification = nextLevelReq
                    self.eventBus.publish(LevelEvent.levelUp(newLevel))
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    if self.showLevelUpNotification?.level == newLevel {
                        self.showLevelUpNotification = nil
                    }
                }
            } else {
                break
            }
        }
        
        if newLevel != currentLevel.level {
            let levelReq = LevelRequirements.allLevels.first { $0.level == newLevel } ?? LevelRequirements.allLevels[0]
            let unlockedFeatures = Self.calculateUnlockedFeatures(for: newLevel)
            
            currentLevel = PlayerLevel(
                level: newLevel,
                experience: newExperience,
                requirements: levelReq,
                unlockedFeatures: unlockedFeatures
            )
        } else {
            let levelReq = currentLevel.requirements
            currentLevel = PlayerLevel(
                level: currentLevel.level,
                experience: newExperience,
                requirements: levelReq,
                unlockedFeatures: currentLevel.unlockedFeatures
            )
        }
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(currentLevel.level, forKey: "player_level")
        UserDefaults.standard.set(currentLevel.experience, forKey: "player_experience")
    }
    
    func isFeatureUnlocked(_ unlock: LevelUnlock) -> Bool {
        return currentLevel.unlockedFeatures.contains(unlock)
    }
    
    func resetProgress() {
        UserDefaults.standard.set(1, forKey: "player_level")
        UserDefaults.standard.set(0, forKey: "player_experience")
        
        let levelReq = LevelRequirements.allLevels[0]
        let unlockedFeatures = Self.calculateUnlockedFeatures(for: 1)
        
        currentLevel = PlayerLevel(
            level: 1,
            experience: 0,
            requirements: levelReq,
            unlockedFeatures: unlockedFeatures
        )
    }
}

enum LevelEvent: GameEvent {
    case experienceGained(Int)
    case levelUp(Int)
    
    var timestamp: Date {
        Date()
    }
}