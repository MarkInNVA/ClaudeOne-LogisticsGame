import SwiftUI
import Combine

struct DeliveryFeedback {
    let id = UUID()
    let location: Location
    let order: Order
    let timestamp: Date
    let fadeDelay: TimeInterval
    
    init(order: Order, location: Location, fadeDelay: TimeInterval = 2.0) {
        self.order = order
        self.location = location
        self.timestamp = Date()
        self.fadeDelay = fadeDelay
    }
}

struct ScoreFeedback {
    let id = UUID()
    let scoreIncrease: Int
    let totalScore: Int
    let timestamp: Date
    let fadeDelay: TimeInterval
    
    init(scoreIncrease: Int, totalScore: Int, fadeDelay: TimeInterval = 3.0) {
        self.scoreIncrease = scoreIncrease
        self.totalScore = totalScore
        self.timestamp = Date()
        self.fadeDelay = fadeDelay
    }
}

class FeedbackManager: ObservableObject {
    @Published var deliveryFeedbacks: [DeliveryFeedback] = []
    @Published var scoreFeedbacks: [ScoreFeedback] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let eventBus: EventBus
    
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
        case .deliverySuccessful(let order, let location):
            showDeliverySuccess(for: order, at: location)
            
        case .scoreIncreased(let increase, let total):
            showScoreIncrease(increase: increase, total: total)
            
        default:
            break
        }
    }
    
    private func showDeliverySuccess(for order: Order, at location: Location) {
        let feedback = DeliveryFeedback(order: order, location: location)
        
        DispatchQueue.main.async { [weak self] in
            self?.deliveryFeedbacks.append(feedback)
        }
        
        // Auto-remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + feedback.fadeDelay) { [weak self] in
            self?.deliveryFeedbacks.removeAll { $0.id == feedback.id }
        }
    }
    
    private func showScoreIncrease(increase: Int, total: Int) {
        let feedback = ScoreFeedback(scoreIncrease: increase, totalScore: total)
        
        DispatchQueue.main.async { [weak self] in
            self?.scoreFeedbacks.append(feedback)
        }
        
        // Auto-remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + feedback.fadeDelay) { [weak self] in
            self?.scoreFeedbacks.removeAll { $0.id == feedback.id }
        }
    }
}