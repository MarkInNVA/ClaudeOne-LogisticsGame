import Foundation

protocol GameEvent {
    var timestamp: Date { get }
}

enum LogisticsEvent: GameEvent {
    case gameStarted
    case gamePaused
    case gameEnded
    
    case orderPlaced(Order)
    case orderFulfilled(Order)
    case orderDelayed(Order)
    
    case vehicleDispatched(Vehicle, route: Route)
    case vehicleArrived(Vehicle, at: Location)
    case vehicleDelayed(Vehicle)
    
    case inventoryLow(Product, at: Warehouse)
    case inventoryReplenished(Product, at: Warehouse, quantity: Int)
    
    case budgetChanged(Double)
    case performanceUpdated(PerformanceMetrics)
    
    var timestamp: Date {
        Date()
    }
}