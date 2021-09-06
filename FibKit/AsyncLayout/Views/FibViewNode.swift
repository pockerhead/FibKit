//
//  FibViewNode.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

open class FibViewNode: FibLayoutViewable {
    public var frame: CGRect = .zero
    private var backgroundColor: UIColor = .clear
    public var viewSize: CGSize?
    
    open var body: FibLayoutElement {
        FibSizeLayout(width: 0, height: 0, child: self)
    }
    
    private var _id: String?
    
    public var id: String {
        _id ?? UUID().uuidString
    }
    
    var identifiedSubviews: [String: UIView] = [:]
    
    public var sublayouts: [FibLayoutElement] = []
    
    open var viewType: UIView.Type {
        UIView.self
    }
    
    var radius: CGFloat = 0
    
    private var _view: UIView?
    public var view: UIView {
        if let loadedView = _view {
            return loadedView
        } else {
            return mainOrSync {[self] in
                _view = viewType.init(frame: .zero)
                return _view!
            }
        }
    }
    var subnodes: [FibViewNode] = []
    private let syncQueue = ThreadPool.getSerialQueue()
    
    open func updateView() {
        mainOrAsync {[self] in
            view.layer.cornerRadius = radius
            view.backgroundColor = backgroundColor
        }
    }
    
    open func addSubview(_ view: UIView, relatedLayout: FibLayoutElement) {
        mainOrAsync {[self] in
            identifiedSubviews[relatedLayout.id] = view
            self.view.addSubview(view)
        }
    }
    
    @discardableResult
    public func layoutThatFits(size: CGSize) -> FibLayout {
        if !(body is FibSizeLayout) {
            let body = self.body
            sublayouts.append(body)
            let layout = body.layoutThatFits(size: size)
            mainOrAsync {[self] in
                if let view = body.findFirstView() {
                    self.view.addSubview(view)
                    view.frame = .init(x: layout.insets.left,
                                       y: layout.insets.top,
                                       width: layout.size.width,
                                       height: layout.size.height)
                }
            }
            return .init(size: layout.size, insets: layout.insets)
        } else {
            return .init(size: size, insets: .zero)
        }
    }
    
    public init() {
    }
    
    // MARK: - Modifiers
    
    public func backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }
    
    public func radius(_ radius: CGFloat) -> Self {
        self.radius = radius
        return self
    }
}
