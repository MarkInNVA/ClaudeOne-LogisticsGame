import Foundation

struct Location: Codable, Hashable {
    let x: Double
    let y: Double
    
    func distance(to other: Location) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
    
    static func random() -> Location {
        Location(x: Double.random(in: 0...1), y: Double.random(in: 0...1))
    }
}