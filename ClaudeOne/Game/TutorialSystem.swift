import Foundation
import SwiftUI
import Combine

enum TutorialStep: Int, CaseIterable {
    case welcome = 0
    case understandDashboard = 1
    case viewFirstOrder = 2
    case assignVehicle = 3
    case watchDelivery = 4
    case checkPerformance = 5
    case completed = 6
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Supply Chain Manager!"
        case .understandDashboard:
            return "Understanding Your Dashboard"
        case .viewFirstOrder:
            return "Your First Order"
        case .assignVehicle:
            return "Assign a Vehicle"
        case .watchDelivery:
            return "Watch the Delivery"
        case .checkPerformance:
            return "Check Your Performance"
        case .completed:
            return "Tutorial Complete!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Let's learn the basics of managing your logistics network. Tap anywhere to continue."
        case .understandDashboard:
            return "The dashboard shows your budget, score, and key metrics. Keep an eye on your budget - don't let it run out!"
        case .viewFirstOrder:
            return "Look at the Orders panel on the right. You should see your first customer order waiting to be fulfilled."
        case .assignVehicle:
            return "Click on an order, then select an available vehicle to assign it. The system will automatically create an optimal route."
        case .watchDelivery:
            return "Watch your vehicle travel on the map. It will collect goods from the warehouse and deliver to the customer."
        case .checkPerformance:
            return "Great! Check your updated score and performance metrics in the dashboard. Faster deliveries mean better performance!"
        case .completed:
            return "You've completed the tutorial! You can now manage multiple vehicles, handle complex orders, and grow your logistics empire."
        }
    }
    
    var highlightArea: TutorialHighlight? {
        switch self {
        case .welcome, .completed:
            return nil
        case .understandDashboard:
            return .dashboard
        case .viewFirstOrder:
            return .ordersPanel
        case .assignVehicle:
            return .ordersPanel
        case .watchDelivery:
            return .map
        case .checkPerformance:
            return .dashboard
        }
    }
    
    var canAutoAdvance: Bool {
        switch self {
        case .welcome, .understandDashboard, .viewFirstOrder, .completed:
            return true
        case .assignVehicle, .watchDelivery, .checkPerformance:
            return false
        }
    }
}

enum TutorialHighlight {
    case dashboard
    case map
    case ordersPanel
    case fleetPanel
    case controls
}

class TutorialSystem: ObservableObject {
    @Published var isActive = false
    @Published var currentStep: TutorialStep = .welcome
    @Published var showTutorialOverlay = false
    
    private var cancellables = Set<AnyCancellable>()
    private let eventBus: EventBus
    private weak var gameState: GameState?
    
    // Tutorial state tracking
    private var hasAssignedVehicle = false
    private var hasCompletedDelivery = false
    private var hasCheckedPerformance = false
    
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
        guard isActive else { return }
        
        switch event {
        case .gameStarted:
            if !hasCompletedTutorial() {
                startTutorial()
            }
            
        case .vehicleDispatched(_, _):
            if currentStep == .assignVehicle {
                hasAssignedVehicle = true
                advanceToStep(.watchDelivery)
            }
            
        case .orderFulfilled(_):
            if currentStep == .watchDelivery {
                hasCompletedDelivery = true
                advanceToStep(.checkPerformance)
            }
            
        case .performanceUpdated(_):
            if currentStep == .checkPerformance && hasCompletedDelivery {
                hasCheckedPerformance = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.advanceToStep(.completed)
                }
            }
            
        default:
            break
        }
    }
    
    func startTutorial() {
        isActive = true
        currentStep = .welcome
        showTutorialOverlay = true
        
        hasAssignedVehicle = false
        hasCompletedDelivery = false
        hasCheckedPerformance = false
        
        eventBus.publish(TutorialEvent.started)
    }
    
    func nextStep() {
        guard canAdvanceCurrentStep() else { return }
        
        let nextStepValue = currentStep.rawValue + 1
        if let nextStep = TutorialStep(rawValue: nextStepValue) {
            advanceToStep(nextStep)
        } else {
            completeTutorial()
        }
    }
    
    private func advanceToStep(_ step: TutorialStep) {
        currentStep = step
        eventBus.publish(TutorialEvent.stepChanged(step))
        
        if step == .completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.completeTutorial()
            }
        }
    }
    
    private func canAdvanceCurrentStep() -> Bool {
        switch currentStep {
        case .welcome, .understandDashboard, .viewFirstOrder, .completed:
            return true
        case .assignVehicle:
            return hasAssignedVehicle
        case .watchDelivery:
            return hasCompletedDelivery
        case .checkPerformance:
            return hasCheckedPerformance
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    private func completeTutorial() {
        isActive = false
        showTutorialOverlay = false
        saveTutorialCompletion()
        eventBus.publish(TutorialEvent.completed)
    }
    
    private func hasCompletedTutorial() -> Bool {
        return UserDefaults.standard.bool(forKey: "tutorial_completed")
    }
    
    private func saveTutorialCompletion() {
        UserDefaults.standard.set(true, forKey: "tutorial_completed")
    }
    
    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: "tutorial_completed")
        isActive = false
        showTutorialOverlay = false
        currentStep = .welcome
    }
}

enum TutorialEvent: GameEvent {
    case started
    case stepChanged(TutorialStep)
    case completed
    
    var timestamp: Date {
        Date()
    }
}