//
//  ShopAppTests.swift
//  ShopAppTests
//
//  Created by Rei Soemanto on 13/05/26.
//

import Testing
import XCTest
@testable import ShopApp

final class ShopAppTests: XCTestCase {

    class MockProductRepository: ProductRepository {
        var shouldFail = false
        var submittedOrder: Order?
        
        func fetchProducts() async throws -> [Product] {
            return [
                Product(id: "P-1", name: "Earbuds", price: 200),
                Product(id: "P-2", name: "Charger", price: 300)
            ]
        }
        
        func submitOrder(order: Order) async throws -> Bool {
            if shouldFail {
                throw NSError(domain: "MockError", code: 500)
            }
            submittedOrder = order
            return true
        }
    }
    
    var mockRepo: MockProductRepository!
    var service: CheckoutService!
    var viewModel: ShopViewModel!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockRepo = MockProductRepository()
        service = CheckoutService(repository: mockRepo)
        viewModel = ShopViewModel(service: service)
    }

    override func tearDown() {
        mockRepo = nil
        service = nil
        viewModel = nil
        super.tearDown()
    }

    @MainActor
    func testCheckoutFullFlow() async {
        let product = Product(id: "P-1", name: "Earbuds", price: 200)
        viewModel.addToCart(product: product)
        
        await viewModel.checkout()
        
        XCTAssertTrue(viewModel.cart.isEmpty, "Cart should be empty after successful checkout.")
        XCTAssertNotNil(mockRepo.submittedOrder, "Repository should have received the order.")
    }
    
    @MainActor
    func testLoadProductSuccessfully() async {
        await viewModel.loadProducts()
        XCTAssertEqual(viewModel.products.count, 2, "ViewModel should load products from repository.")
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after fetch.")
    }
    
    @MainActor
    func testAddToCartQuantityIncreased() {
        let product = Product(id: "P-1", name: "Earbuds", price: 200)
        
        viewModel.addToCart(product: product)
        viewModel.addToCart(product: product)
        
        XCTAssertEqual(viewModel.cart.count, 1, "Should not duplicate items in cart.")
        XCTAssertEqual(viewModel.cart.first?.quantity, 2, "Quantity should increase to 2.")
    }
    
    @MainActor
    func testClearsCartAfterCheckout() async {
        let product = Product(id: "P-1", name: "Earbuds", price: 200)
        viewModel.addToCart(product: product)
        
        await viewModel.checkout()
        
        XCTAssertTrue(viewModel.cart.isEmpty, "Cart should be emptied after checkout.")
    }

    func testCalculateTotal() {
        let cart = [
            CartItem(product: Product(id: "1", name: "A", price: 100), quantity: 2),
            CartItem(product: Product(id: "2", name: "B", price: 300), quantity: 1)
        ]
        let total = service.calculateTotal(cart: cart)
        XCTAssertEqual(total, 500, "Total should be strictly based on price * quantity.")
    }
    
    func testApplyDiscountAboveThreshold() {
        let discounted = service.applyDiscount(total: 1200)
        XCTAssertEqual(discounted, 1080, "Should apply 10% discount for totals > 1000.")
    }
    
    func testApplyDiscountBelowThreshold() {
        let total = service.applyDiscount(total: 800)
        XCTAssertEqual(total, 800, "Should not apply discount for totals <= 1000.")
    }
    
    func testCheckoutSuccessfully() async throws {
        let cart = [CartItem(product: Product(id: "1", name: "A", price: 100), quantity: 1)]
        let result = try await service.checkout(cart: cart)
        XCTAssertTrue(result, "Checkout should succeed with valid cart.")
    }
    
    func testCheckoutFailsEmptyCart() async {
        do {
            _ = try await service.checkout(cart: [])
            XCTFail("Checkout should throw error with empty cart.")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "CheckoutError")
            XCTAssertEqual(error.code, 400)
        }
    }
    
    func testCheckoutFailsRepositoryFails() async {
        mockRepo.shouldFail = true
        let cart = [CartItem(product: Product(id: "1", name: "A", price: 100), quantity: 1)]
        
        do {
            _ = try await service.checkout(cart: cart)
            XCTFail("Checkout should throw if repository fails.")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "MockError")
            XCTAssertEqual(error.code, 500)
        }
    }
    
    func testCalculateShippingFeeStandard() {
        let fee = service.calculateShippingFee(type: .standard)
        XCTAssertEqual(fee, 50, "Standard shipping should be 50.")
    }
    
    func testCalculateShippingFeeExpress() {
        let fee = service.calculateShippingFee(type: .express)
        XCTAssertEqual(fee, 150, "Express shipping should be 150.")
    }
    
    func testCheckoutWithShippingIncludesShippingFee() async throws {
        let cart = [CartItem(product: Product(id: "1", name: "A", price: 200), quantity: 1)]
        _ = try await service.checkout(cart: cart, shippingType: .standard)
        
        XCTAssertEqual(mockRepo.submittedOrder?.total, 250, "Total should be 200 (base) + 50 (shipping).")
    }
    
    func testCheckoutWithShippingDiscountAppliedBeforeShipping() async throws {
        let cart = [CartItem(product: Product(id: "1", name: "Macbook", price: 1200), quantity: 1)]
        _ = try await service.checkout(cart: cart, shippingType: .express)
        
        XCTAssertEqual(mockRepo.submittedOrder?.total, 1230, "Discount should apply before shipping fee.")
    }
    
    func testCheckoutWithShippingCallsRepository() async throws {
        let cart = [CartItem(product: Product(id: "1", name: "A", price: 100), quantity: 1)]
        _ = try await service.checkout(cart: cart, shippingType: .standard)
        
        XCTAssertNotNil(mockRepo.submittedOrder, "Checkout extension must call repository submission.")
    }

    func testFetchProduct() async throws {
        let products = try await mockRepo.fetchProducts()
        XCTAssertFalse(products.isEmpty, "Mock repository should return list of available products.")
    }
    
    func testSubmitOrder() async throws { 
        let order = Order(items: [], total: 100)
        let result = try await mockRepo.submitOrder(order: order)
        
        XCTAssertTrue(result, "Mock repository should return true upon successful order submission.")
    }
}
