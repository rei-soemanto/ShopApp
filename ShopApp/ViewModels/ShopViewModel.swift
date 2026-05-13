//
//  ShopViewModel.swift
//  ShopApp
//
//  Created by Rei Soemanto on 13/05/26.
//

import Foundation
import Combine

@MainActor
class ShopViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var products: [Product] = []
    @Published var cart: [CartItem] = []
    
    private let service: CheckoutService
    
    init(service: CheckoutService) {
        self.service = service
    }
    
    func loadProducts() async {
        isLoading = true
        do {
            let fetchedProducts = try await service.getProducts()
            self.products = fetchedProducts
        } catch {
            self.error = "Failed to load"
        }
        isLoading = false
    }
    
    func addToCart(product: Product) {
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1))
        }
    }
    
    func checkout() async {
        do {
            _ = try await service.checkout(cart: cart)
            cart.removeAll()
        } catch {
            self.error = "Checkout failed"
        }
    }
}
