//
//  Extensions.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import Foundation
import Threading

public extension CGRect {
    
    func offset(by insets: UIEdgeInsets) -> CGRect {
        let offsetOrigin = self.offsetBy(dx: insets.left, dy: insets.top)
        return .init(origin: offsetOrigin.origin,
                     size: .init(width: offsetOrigin.width + insets.right,
                                 height: offsetOrigin.height + insets.bottom))
    }
}

extension UIEdgeInsets {
    
    public func applying(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        return .init(top: top + insets.top,
                     left: left + insets.left,
                     bottom: bottom + insets.bottom,
                     right: right + insets.right)
    }
}

public extension CGRect {
    
    mutating func setCenterY(to rect: CGRect) {
        origin.y = rect.height / 2 - height / 2
    }
    
    mutating func setCenterX(to rect: CGRect) {
        origin.x = rect.width / 2 - width / 2
    }
    
    func getCenteringOrigin(to rect: CGRect) -> CGPoint {
        return .init(x: rect.width / 2 - width / 2, y: rect.height / 2 - height / 2)
    }
}

extension ThreadedArray {
    
    public subscript(s index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
