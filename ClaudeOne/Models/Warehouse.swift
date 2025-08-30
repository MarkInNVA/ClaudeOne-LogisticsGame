import Foundation

struct Warehouse: Codable, Identifiable {
    let id = UUID()
    let name: String
    let location: Location
    let capacity: Int
    var inventory: [Product: Int]
    var operatingCost: Double = 1000.0
    
    var totalStored: Int {
        inventory.values.reduce(0, +)
    }
    
    var availableCapacity: Int {
        capacity - totalStored
    }
    
    var utilizationRate: Double {
        Double(totalStored) / Double(capacity)
    }
    
    func hasStock(for product: Product, quantity: Int) -> Bool {
        (inventory[product] ?? 0) >= quantity
    }
    
    mutating func addStock(_ product: Product, quantity: Int) -> Bool {
        guard availableCapacity >= quantity else { return false }
        inventory[product, default: 0] += quantity
        return true
    }
    
    mutating func removeStock(_ product: Product, quantity: Int) -> Bool {
        guard hasStock(for: product, quantity: quantity) else { return false }
        inventory[product]! -= quantity
        if inventory[product] == 0 {
            inventory.removeValue(forKey: product)
        }
        return true
    }
}