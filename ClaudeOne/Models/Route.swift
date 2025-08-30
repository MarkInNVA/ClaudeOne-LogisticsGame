import Foundation

struct Route: Codable, Identifiable {
    let id = UUID()
    let waypoints: [Location]
    let orders: [Order]
    
    var totalDistance: Double {
        guard waypoints.count > 1 else { return 0 }
        var distance = 0.0
        for i in 0..<(waypoints.count - 1) {
            distance += waypoints[i].distance(to: waypoints[i + 1])
        }
        return distance
    }
    
    var estimatedDuration: TimeInterval {
        totalDistance * 60.0
    }
    
    var totalWeight: Double {
        orders.reduce(0) { $0 + $1.totalWeight }
    }
    
    var totalValue: Double {
        orders.reduce(0) { $0 + $1.value }
    }
    
    init(from start: Location, to destinations: [Location], orders: [Order]) {
        var waypoints = [start]
        waypoints.append(contentsOf: destinations)
        
        self.waypoints = waypoints
        self.orders = orders
    }
}