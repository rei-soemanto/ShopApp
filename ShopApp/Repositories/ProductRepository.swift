//
//  ProductRepository.swift
//  ShopApp
//
//  Created by Rei Soemanto on 13/05/26.
//

import Foundation

protocol ProductRepository {
    func fetchProducts() async throws -> [Product]
    func submitOrder(order: Order) async throws -> Bool
}

class ProductImplementation: ProductRepository {
    func fetchProducts() async throws -> [Product] {
        return [
            Product(id: "P-1", name: "Earbuds", price: 200),
            Product(id: "P-2", name: "Charger Macbook", price: 300)
        ]
    }
    
    func submitOrder(order: Order) async throws -> Bool {
        return true
    }
}
