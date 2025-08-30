import Foundation

enum OrderPriority: CaseIterable, Codable {
    case standard
    case express
    case urgent
    
    var multiplier: Double {
        switch self {
        case .standard: return 1.0
        case .express: return 1.5
        case .urgent: return 2.0
        }
    }
}

struct Order: Codable, Identifiable {
    let id = UUID()
    let product: Product
    let quantity: Int
    let destination: Location
    let priority: OrderPriority
    let placedAt: Date
    let deadline: Date
    
    var value: Double {
        Double(quantity) * product.value * priority.multiplier
    }
    
    var totalWeight: Double {
        Double(quantity) * product.weight
    }
    
    var isOverdue: Bool {
        Date() > deadline
    }
    
    static func random() -> Order {
        let product = Product.allProducts.randomElement()!
        let priority = OrderPriority.allCases.randomElement()!
        let quantity = Int.random(in: 1...10)
        let placedAt = Date()
        let deadline = placedAt.addingTimeInterval(TimeInterval.random(in: 300...3600))
        
        return Order(
            product: product,
            quantity: quantity,
            destination: Location.random(),
            priority: priority,
            placedAt: placedAt,
            deadline: deadline
        )
    }
}