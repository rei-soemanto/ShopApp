//
//  Order.swift
//  ShopApp
//
//  Created by Rei Soemanto on 13/05/26.
//

import Foundation

struct Order: Equatable {
    let items: [CartItem]
    let total: Double
}
