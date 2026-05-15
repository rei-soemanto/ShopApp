//
//  CheckoutService.swift
//  ShopApp
//
//  Created by Rei Soemanto on 13/05/26.
//

import Foundation

class CheckoutService {
    let repository: ProductRepository
    
    init(repository: ProductRepository) {
        self.repository = repository
    }
    
    func calculateTotal(cart: [CartItem]) -> Double {
        cart.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    func applyDiscount(total: Double) -> Double {
        return total > 1000 ? total * 0.9 : total
    }
    
    func checkout(cart: [CartItem]) async throws -> Bool {
        let total = applyDiscount(total: calculateTotal(cart: cart))
        
        guard total > 0 else {
            throw NSError(domain: "CheckoutError", code: 400)
        }
        
        let order = Order(items: cart, total: total)
        return try await repository.submitOrder(order: order)
    }
    
    func getProducts() async throws -> [Product] {
        try await repository.fetchProducts()
    }
}

enum ShippingType {
    case standard
    case express
}

extension CheckoutService {
    func calculateShippingFee(type: ShippingType) -> Double {
        switch type {
        case .standard: return 50
        case .express: return 150
        }
    }
    
    func checkout(cart: [CartItem], shippingType: ShippingType) async throws -> Bool {
        let baseTotal = applyDiscount(total: calculateTotal(cart: cart))
        let finalTotal = baseTotal + calculateShippingFee(type: shippingType)
        
        guard finalTotal > 0 else {
            throw NSError(domain: "CheckoutError", code: 400)
        }
        
        let order = Order(items: cart, total: finalTotal)
        return try await repository.submitOrder(order: order)
    }
}
