//
//  LayoutElement.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

public protocol FibLayoutViewable: FibLayoutElement {
    var view: UIView { get }
    /// Must be called on MainThread Only!!
    func updateView()
}

public protocol FibLayoutElement {
    var id: String { get }
    
    @discardableResult
    func layoutThatFits(size: CGSize) -> FibLayout
    var sublayouts: [FibLayoutElement] { get set }
}

public struct FibLayout {
    
    var size: CGSize
    var insets: UIEdgeInsets
}


extension FibLayoutElement {
    
    public var id: String {
        UUID().uuidString
    }
    
    func findFirstView() -> UIView? {
        if let view = (self as? FibLayoutViewable)?.view {
            return view
        } else {
            var view: UIView?
            for element in sublayouts {
                if let layoutView = element.findFirstView() {
                    view = layoutView
                    break
                }
            }
            return view
        }
    }
    
    func recursiveUpdateViews() {
        mainOrAsync {
            (self as? FibLayoutViewable)?.updateView()
        }
        sublayouts.forEach({ $0.recursiveUpdateViews() })
    }
    
    public func inset(by insets: UIEdgeInsets) -> FibLayoutElement {
        FibInsetLayout(insets: insets, child: self)
    }
    
    public func size(_ size: CGSize) -> FibLayoutElement {
        FibSizeLayout(width: size.width, height: size.height, child: self)
    }
    
    public func size(width: CGFloat? = nil, height: CGFloat? = nil) -> FibLayoutElement {
        FibSizeLayout(width: width, height: height, child: self)
    }
    
    public func size(_ single: CGFloat) -> FibLayoutElement {
        FibSizeLayout(width: single, height: single, child: self)
    }
    
    public func offset(_ offset: CGPoint) -> FibLayoutElement {
        FibInsetLayout(insets: .init(top: offset.y, left: offset.x, bottom: 0, right: 0), child: self)
    }
}
