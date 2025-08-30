import Foundation

struct Product: Codable, Hashable, Identifiable {
    let id = UUID()
    let name: String
    let weight: Double
    let value: Double
    
    static let electronics = Product(name: "Electronics", weight: 2.0, value: 100.0)
    static let furniture = Product(name: "Furniture", weight: 50.0, value: 500.0)
    static let clothing = Product(name: "Clothing", weight: 1.0, value: 50.0)
    static let books = Product(name: "Books", weight: 0.5, value: 20.0)
    
    static let allProducts = [electronics, furniture, clothing, books]
}