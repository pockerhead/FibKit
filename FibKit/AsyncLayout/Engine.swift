//
//  Engine.swift
//  FibKit
//
//  Created by Артём Балашов on 30.08.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit
import Combine

public struct ThreadPool {
    
    private static let concurrentQueues: [DispatchQueue] = (0...3).map({
        DispatchQueue.init(label: "com.FibKit.ConsurrentQueue_\($0)", qos: .userInteractive, attributes: .concurrent)
    })
    
    private static let syncQueues: [DispatchQueue] = (0...3).map({
        DispatchQueue.init(label: "com.FibKit.SerialQueue_\($0)", qos: .userInteractive)
    })
    
    public static func getSerialQueue() -> DispatchQueue {
        syncQueues.randomElement()!
    }
    
    public static func getConcurrentQueue() -> DispatchQueue {
        concurrentQueues.randomElement()!
    }
}

public protocol FibLayoutViewable: FibLayoutElement {
    var view: UIView { get }
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
            return mainOrAsync {[self] in
                _view = viewType.init(frame: .zero)
                return _view!
            }
        }
    }
    var subnodes: [FibViewNode] = []
    private let syncQueue = ThreadPool.getSerialQueue()
    
    @discardableResult
    public func layoutThatFits(size: CGSize) -> FibLayout {
        mainOrAsync {[self] in
            view.layer.cornerRadius = radius
            view.backgroundColor = backgroundColor
        }
        return .init(size: size, insets: .zero)
    }
    
    public init() {
    }
    
    func addSubnode(_ node: FibViewNode) {
        sublayouts.append(node)
        mainOrAsync {
            self.view.addSubview(node.view)
        }
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

public class FibInsetLayout: FibLayoutElement {
    
    public func layoutThatFits(size: CGSize) -> FibLayout {
        let insetRect = CGRect(origin: .zero, size: size).inset(by: insets)
        let layout = sublayouts.first!.layoutThatFits(size: insetRect.size)
        return .init(size: layout.size, insets: layout.insets.applying(self.insets))
    }
    
    public var sublayouts: [FibLayoutElement] = []
    
    public var insets: UIEdgeInsets
    
    init(insets: UIEdgeInsets, child: FibLayoutElement) {
        sublayouts.append(child)
        self.insets = insets
    }
}

public class FibSizeLayout: FibLayoutElement {
    public func layoutThatFits(size: CGSize) -> FibLayout {
        let layout = sublayouts.first!.layoutThatFits(size: size)
        return .init(size: .init(width: width ?? layout.size.width,
                                 height: height ?? layout.size.height),
                     insets: .zero)
    }
    
    var height: CGFloat?
    var width: CGFloat?
    
    public var sublayouts: [FibLayoutElement] = []
    init(width: CGFloat?, height: CGFloat?, child: FibLayoutElement) {
        self.sublayouts.append(child)
        self.width = width
        self.height = height
    }
}

extension FibLayoutElement {
    
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
}

final public class FibTextNode: FibViewNode {
    
    public override var viewType: UIView.Type {
        UILabel.self
    }
    
    var numberOfLines: Int = 0
    var textAlignment: NSTextAlignment = .natural
    
    var label: UILabel {
        (view as! UILabel)
    }
    
    public override func layoutThatFits(size: CGSize) -> FibLayout {
        super.layoutThatFits(size: size)
        mainOrAsync {[self] in
            updateView()
        }
        return .init(size: attributedString.boundingRect(with: size,
                                                         options: .usesLineFragmentOrigin,
                                                         context: nil).size,
                     insets: .zero)
    }
    
    /// Must be called on main thread ONLY!!!
    public func updateView() {
        label.numberOfLines = numberOfLines
        label.textAlignment = textAlignment
        label.attributedText = attributedString
        label.layer.masksToBounds = false
        label.clipsToBounds = false
    }
    
    var attributedString: NSMutableAttributedString
    
    public init(attributedString: NSMutableAttributedString) {
        self.attributedString = attributedString
    }
    
    public convenience init(_ text: String) {
        self.init(attributedString: .init(string: text))
    }
    
    public func font(_ font: UIFont) -> Self {
        attributedString.addAttributes([.font: font],
                                       range: .init(location: 0, length: attributedString.string.count))
        return self
    }
    
    public func foregroundColor(_ color: UIColor) -> Self {
        attributedString.addAttributes([.foregroundColor: color],
                                       range: .init(location: 0, length: attributedString.string.count))
        return self
    }
    
    public func textAlignment(_ textAlignment: NSTextAlignment) -> Self {
        self.textAlignment = textAlignment
        return self
    }
}

public struct AsyncLayoutEngine {
    
    public static func processLayout(queue: DispatchQueue = ThreadPool.getSerialQueue(),
                                     _ layout: FibLayoutElement,
                                     view: UIView) {
        mainOrAsync {
            let safeArea = view.safeAreaInsets
            let size = view.bounds.inset(by: safeArea).size
            queue.async {
                let element = layout.layoutThatFits(size: size)
                var insets = element.insets
                insets = insets.applying(safeArea)
                mainOrAsync {
                    if let subView = layout.findFirstView() {
                        view.addSubview(subView)
                        subView.frame = .init(origin: .init(x: safeArea.left + element.insets.left,
                                                            y: safeArea.top + element.insets.top),
                                              size: element.size)
                    }
                }
            }
        }
    }
}

@resultBuilder
public struct FibViewBuilder {
    
    public static func buildBlock(_ components: FibLayoutElement...) -> [FibLayoutElement] {
        return components
    }
    
    public static func buildOptional(_ component: [FibLayoutElement]?) -> [FibLayoutElement] {
        component ?? []
    }
    
    public static func buildEither(first component: [FibLayoutElement]) -> [FibLayoutElement] {
        component
    }
    
    public static func buildEither(second component: [FibLayoutElement]) -> [FibLayoutElement] {
        component
    }
    
    public static func buildArray(_ components: [[FibLayoutElement]]) -> [FibLayoutElement] {
        components.flatMap({ $0 })
    }
}

final public class FibHStack: FibViewNode {
    
    public enum Alignment {
        case center
        case top
        case bottom
    }
    
    public override func layoutThatFits(size: CGSize) -> FibLayout {
        super.layoutThatFits(size: size)
        var startOrigin = CGPoint.zero
        var stackSize = size
        var finalFrames: [CGRect] = []
        sublayouts.forEach { element in
            let layout = element.layoutThatFits(size: stackSize)
            let frame = CGRect(origin: .init(x: startOrigin.x + layout.insets.left, y: startOrigin.y + layout.insets.top), size: layout.size)
            let unionFrame = CGRect(x: frame.origin.x, y: frame.origin.y,
                                    width: frame.width + layout.insets.right,
                                    height: frame.height + layout.insets.bottom)
            self.frame = self.frame.union(unionFrame)
            finalFrames.append(frame)
            startOrigin.x += frame.width + layout.insets.left + spacing
            stackSize.width -= frame.width + layout.insets.left + spacing
        }
        
        mainOrAsync {[self, finalFrames] in
            sublayouts.enumerated().forEach({ index, element in
                if let subView = element.findFirstView() {
                    view.addSubview(subView)
                    subView.frame = finalFrames.get(index) ?? .zero
                    if alignment == .center {
                        subView.frame.setCenterY(to: self.frame)
                    }
                }
            })
        }
        return .init(size: frame.size, insets: .zero)
    }
    
    var spacing: CGFloat
    var alignment: Alignment
    
    public init(spacing: CGFloat = 0, alignment: Alignment = .center, @FibViewBuilder _ views: (() -> [FibLayoutElement])) {
        self.spacing = spacing
        self.alignment = alignment
        super.init()
        self.sublayouts = views()
    }
}

final public class FibVStack: FibViewNode {
    
    public enum Alignment {
        case center
        case leading
        case trailing
    }
    
    public override func layoutThatFits(size: CGSize) -> FibLayout {
        super.layoutThatFits(size: size)
        let stackFrame = CGRect(origin: .zero, size: size)
        var startOriginY: CGFloat?
        sublayouts.forEach { element in
            let layout = element.layoutThatFits(size: size)
            var itemFrame = CGRect(origin: .init(x: 0 + layout.insets.left,
                                                 y: (startOriginY ?? 0) + layout.insets.top),
                                   size: layout.size)
            if alignment == .center {
                itemFrame.setCenterX(to: stackFrame)
            }
            if startOriginY == nil {
                startOriginY = itemFrame.origin.y
            }
            if spacing + itemFrame.height + startOriginY! > size.height {
                itemFrame.size.height = size.height - spacing - startOriginY!
            }
            let unionFrame = CGRect(origin: itemFrame.origin,
                                    size: .init(width: itemFrame.width + layout.insets.right,
                                                height: itemFrame.height + layout.insets.bottom))
            self.frame = self.frame.union(unionFrame)
            mainOrAsync {[self] in
                if let subView = element.findFirstView() {
                    view.addSubview(subView)
                    subView.frame = itemFrame
                }
            }
            startOriginY = (frame.maxY + spacing)
        }
        return .init(size: .init(width: size.width, height: frame.height), insets: .zero)
    }
    
    var spacing: CGFloat
    var alignment: Alignment
    
    public init(spacing: CGFloat = 0, alignment: Alignment = .center, @FibViewBuilder _ views: (() -> [FibLayoutElement])) {
        self.spacing = spacing
        self.alignment = alignment
        super.init()
        self.sublayouts = views()
    }
}

open class FibAsyncViewController: UIViewController {
    
    private let queue = ThreadPool.getSerialQueue()
    open var body: FibLayoutElement {
        fatalError("Override this!")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        asyncLayoutViews()
    }
    
    public func asyncLayoutViews() {
        delay {[self] in
            view.subviews.forEach({ v in
                guard !(v is UIButton) else { return }
                v.removeFromSuperview()
            })
            let size = view.bounds
            let view = view!
            let body = body
            queue.async {
                AsyncLayoutEngine.processLayout(body, view: view)
            }
        }
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
