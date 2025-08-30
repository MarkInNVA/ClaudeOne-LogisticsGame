import Foundation

struct PerformanceMetrics: Codable {
    var averageDeliveryTime: TimeInterval = 0
    var onTimeDeliveryRate: Double = 1.0
    var customerSatisfaction: Double = 1.0
    var totalCosts: Double = 0
    var totalRevenue: Double = 0
    var efficiency: Double = 1.0
    
    var profit: Double {
        totalRevenue - totalCosts
    }
    
    var profitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        return profit / totalRevenue
    }
    
    mutating func updateDeliveryMetrics(deliveryTime: TimeInterval, wasOnTime: Bool) {
        averageDeliveryTime = (averageDeliveryTime + deliveryTime) / 2
        onTimeDeliveryRate = (onTimeDeliveryRate + (wasOnTime ? 1.0 : 0.0)) / 2
        updateCustomerSatisfaction()
    }
    
    mutating func addCost(_ cost: Double) {
        totalCosts += cost
    }
    
    mutating func addRevenue(_ revenue: Double) {
        totalRevenue += revenue
    }
    
    private mutating func updateCustomerSatisfaction() {
        customerSatisfaction = min(1.0, onTimeDeliveryRate * 1.2 - 0.2)
    }
    
    mutating func updateEfficiency(vehicleUtilization: Double, warehouseUtilization: Double) {
        efficiency = (vehicleUtilization + warehouseUtilization) / 2
    }
}