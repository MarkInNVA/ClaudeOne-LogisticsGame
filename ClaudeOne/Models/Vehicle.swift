import Foundation

enum VehicleType: CaseIterable, Codable {
    case van
    case truck
    case drone
    
    var defaultCapacity: Int {
        switch self {
        case .van: return 200
        case .truck: return 500
        case .drone: return 10
        }
    }
    
    var defaultSpeed: Double {
        switch self {
        case .van: return 50.0
        case .truck: return 60.0
        case .drone: return 100.0
        }
    }
    
    var operatingCost: Double {
        switch self {
        case .van: return 0.5
        case .truck: return 1.0
        case .drone: return 2.0
        }
    }
}

enum VehicleStatus: Codable {
    case idle
    case enRoute(Route)
    case loading
    case maintenance
}

struct Vehicle: Codable, Identifiable {
    let id: UUID
    let type: VehicleType
    let capacity: Int
    let speed: Double
    var location: Location
    var status: VehicleStatus = .idle
    var currentLoad: Int = 0
    
    init(id: UUID = UUID(), type: VehicleType, capacity: Int? = nil, speed: Double? = nil, location: Location) {
        self.id = id
        self.type = type
        self.capacity = capacity ?? type.defaultCapacity
        self.speed = speed ?? type.defaultSpeed
        self.location = location
    }
    
    var availableCapacity: Int {
        capacity - currentLoad
    }
    
    var isAvailable: Bool {
        if case .idle = status {
            return true
        }
        return false
    }
}