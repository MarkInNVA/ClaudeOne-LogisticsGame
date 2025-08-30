import Foundation
import Combine

class WarehouseManager: ObservableObject {
    @Published private(set) var warehouses: [Warehouse] = []
    
    private let eventBus: EventBus
    private var cancellables = Set<AnyCancellable>()
    
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
        case .inventoryLow(let product, let warehouse):
            handleLowInventory(product: product, at: warehouse)
            
        case .inventoryReplenished(let product, let warehouse, let quantity):
            replenishInventory(product: product, at: warehouse, quantity: quantity)
            
        default:
            break
        }
    }
    
    func addWarehouse(_ warehouse: Warehouse) {
        warehouses.append(warehouse)
    }
    
    func removeWarehouse(_ warehouseId: UUID) {
        warehouses.removeAll { $0.id == warehouseId }
    }
    
    func findNearestWarehouse(to location: Location) -> Warehouse? {
        warehouses.min { warehouse1, warehouse2 in
            warehouse1.location.distance(to: location) < warehouse2.location.distance(to: location)
        }
    }
    
    func findWarehouseWithStock(for product: Product, quantity: Int) -> Warehouse? {
        warehouses.first { $0.hasStock(for: product, quantity: quantity) }
    }
    
    private func handleLowInventory(product: Product, at warehouse: Warehouse) {
        guard let warehouseIndex = warehouses.firstIndex(where: { $0.id == warehouse.id }) else { return }
        
        let reorderQuantity = max(50, warehouse.capacity / 10)
        if warehouses[warehouseIndex].addStock(product, quantity: reorderQuantity) {
            eventBus.publish(LogisticsEvent.inventoryReplenished(product, at: warehouse, quantity: reorderQuantity))
        }
    }
    
    private func replenishInventory(product: Product, at warehouse: Warehouse, quantity: Int) {
        guard let warehouseIndex = warehouses.firstIndex(where: { $0.id == warehouse.id }) else { return }
        warehouses[warehouseIndex].addStock(product, quantity: quantity)
    }
    
    func allocateInventory(for order: Order) -> Warehouse? {
        guard let warehouse = findWarehouseWithStock(for: order.product, quantity: order.quantity) else {
            return nil
        }
        
        guard let warehouseIndex = warehouses.firstIndex(where: { $0.id == warehouse.id }) else { return nil }
        
        if warehouses[warehouseIndex].removeStock(order.product, quantity: order.quantity) {
            let remainingStock = warehouses[warehouseIndex].inventory[order.product] ?? 0
            if remainingStock < 10 {
                eventBus.publish(LogisticsEvent.inventoryLow(order.product, at: warehouses[warehouseIndex]))
            }
            return warehouses[warehouseIndex]
        }
        
        return nil
    }
}