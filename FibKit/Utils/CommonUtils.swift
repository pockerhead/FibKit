//
//  Utils.swift
//  DITCore
//
//  Created by artem on 03.08.2020.
//  Copyright © 2020 DIT Moscow. All rights reserved.
//

import Foundation

func delay(_ delay: Double, closure:@escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func delay(cyclesCount: Int = 1, closure:@escaping () -> Void) {
    if cyclesCount == 0 {
        closure()
    } else {
        DispatchQueue.main.async {
            delay(cyclesCount: cyclesCount - 1, closure: closure)
        }
    }
}
func delay(_ delay: Double, workItem: DispatchWorkItem) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: workItem)
}

func printCodeExecutionTime(comment: String = "Block", closure: (() -> Void)?) {
    #if DEBUG
    let start = DispatchTime.now()
    closure?()
    let end = DispatchTime.now()

    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = Double(nanoTime) / 1_000_000_000
    log.warning("[The execution of \(comment) is \(timeInterval)]")
    #endif
}

extension Comparable {

    func isBeetween(_ lhs: Self, _ rhs: Self) -> Bool {
        self >= lhs && self <= rhs
    }
}

extension Comparable {

    func isOutside(_ lhs: Self, _ rhs: Self) -> Bool {
        self <= lhs || self >= rhs
    }
}


let log = Logger()
class Logger {
    
    func warning(_ arg: Any...) {
        #if DEBUG
        print(arg)
        #endif
    }
    
    func debug(_ arg: Any...) {
        #if DEBUG
        print(arg)
        #endif
    }
}

//
//  Util.swift
//  SmartStaff
//
//  Created by artem on 20.02.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import UIKit

// swiftlint:disable all


 extension CGFloat {
    func clamp(_ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
        return self < minValue ? minValue : (self > maxValue ? maxValue : self)
    }

    func softClamp(_ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
        self <= minValue ? minValue : (self >= maxValue ? maxValue : self)
    }
}

 extension Double {
    func clamp(_ minValue: Double, _ maxValue: Double) -> Double {
        return self < minValue ? minValue : (self > maxValue ? maxValue : self)
    }

    func softClamp(_ minValue: Double, _ maxValue: Double) -> Double {
        self <= minValue ? minValue : (self >= maxValue ? maxValue : self)
    }
}

 extension Int {
    func clamp(_ minValue: Int, _ maxValue: Int) -> Int {
        return self < minValue ? minValue : (self > maxValue ? maxValue : self)
    }

    func softClamp(_ minValue: Int, _ maxValue: Int) -> Int {
        self <= minValue ? minValue : (self >= maxValue ? maxValue : self)
    }
}

 extension CGPoint {
    func translate(_ dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x+dx, y: self.y+dy)
    }

    func transform(_ trans: CGAffineTransform) -> CGPoint {
        return self.applying(trans)
    }

    func distance(_ point: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - point.x, 2)+pow(self.y - point.y, 2))
    }

    var transposed: CGPoint {
        return CGPoint(x: y, y: x)
    }
}

 extension CGSize {
    func insets(by insets: UIEdgeInsets) -> CGSize {
        return CGSize(width: width - insets.left - insets.right, height: height - insets.top - insets.bottom)
    }
    var transposed: CGSize {
        return CGSize(width: height, height: width)
    }
}

 func abs(_ left: CGPoint) -> CGPoint {
    return CGPoint(x: abs(left.x), y: abs(left.y))
}
 func min(_ left: CGPoint, _ right: CGPoint) -> CGPoint {
    return CGPoint(x: min(left.x, right.x), y: min(left.y, right.y))
}
 func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
 func += (left: inout CGPoint, right: CGPoint) {
    left.x += right.x
    left.y += right.y
}
 func + (left: CGRect, right: CGPoint) -> CGRect {
    return CGRect(origin: left.origin + right, size: left.size)
}
 func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
 func - (left: CGRect, right: CGPoint) -> CGRect {
    return CGRect(origin: left.origin - right, size: left.size)
}
 func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x/right, y: left.y/right)
}
 func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x*right, y: left.y*right)
}
 func * (left: CGFloat, right: CGPoint) -> CGPoint {
    return right * left
}
 func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x*right.x, y: left.y*right.y)
}
 prefix func - (point: CGPoint) -> CGPoint {
    return CGPoint.zero - point
}
 func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width/right, height: left.height/right)
}
 func - (left: CGPoint, right: CGSize) -> CGPoint {
    return CGPoint(x: left.x - right.width, y: left.y - right.height)
}

 prefix func - (inset: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: -inset.top, left: -inset.left, bottom: -inset.bottom, right: -inset.right)
}

 extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    var bounds: CGRect {
        return CGRect(origin: .zero, size: size)
    }
    init(center: CGPoint, size: CGSize) {
        self.init(origin: center - size / 2, size: size)
    }
    var transposed: CGRect {
        return CGRect(origin: origin.transposed, size: size.transposed)
    }
}

//
//  Array.swift
//  DITCore
//
//  Created by artem on 03.08.2020.
//  Copyright © 2020 DIT Moscow. All rights reserved.
//

import Foundation

 extension Array where Element: Comparable {
    func insertionIndex(of element: Element) -> Int {
        var lower = 0
        var upper = count - 1
        while lower <= upper {
            let middle = (lower + upper) / 2
            if self[middle] < element {
                lower = middle + 1
            } else if element < self[middle] {
                upper = middle - 1
            } else {
                return middle
            }
        }
        return lower
    }
}

 extension Array {

    /// Return immutable element of array or nil
    /// - Parameter index: index
    func get(_ index: Int) -> Element? {
        if have(index) {
            return self[index]
        }
        return nil
    }

    func have(_ index: Int) -> Bool {
        return (index >= 0 && count > index)
    }

}

 extension Array where Element : Equatable {

    mutating func mergeElements<C : Collection>(newElements: C) where C.Iterator.Element == Element{
        let filteredList = newElements.filter({!self.contains($0)})
        self.append(contentsOf: filteredList)
    }
    
    func mergingElements<C : Collection>(newElements: C) -> Array<Element> where C.Iterator.Element == Element {
        let filteredList = newElements.filter({!self.contains($0)})
        var mutSelf = self
        mutSelf.append(contentsOf: filteredList)
        return mutSelf
    }

}

//
//  Collection.swift
//  DITCore
//
//  Created by artem on 03.08.2020.
//  Copyright © 2020 DIT Moscow. All rights reserved.
//

import Foundation


 extension Collection {
  /// Finds such index N that predicate is true for all elements up to
  /// but not including the index N, and is false for all elements
  /// starting with index N.
  /// Behavior is undefined if there is no such N.
  func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
    var low = startIndex
    var high = endIndex
    while low != high {
      let mid = index(low, offsetBy: distance(from: low, to: high)/2)
      if predicate(self[mid]) {
        low = index(after: mid)
      } else {
        high = mid
      }
    }
    return low
  }
    
    func optBinarySearch(predicate: (Iterator.Element) -> Bool) -> Index? {
      var low = startIndex
      var isFinded = false
      var high = endIndex
      while low != high {
        let mid = index(low, offsetBy: distance(from: low, to: high)/2)
        if predicate(self[mid]) {
          low = index(after: mid)
          isFinded = true
        } else {
          high = mid
        }
      }
      guard isFinded else { return nil }
      return low
    }
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Return collection mapped with keypath
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
    
    /// Return collection compact mapped with keypath
    func compactMap<T>(_ keyPath: KeyPath<Element, T?>) -> [T] {
        return compactMap { $0[keyPath: keyPath] }
    }
    
    /// Return collection sorted by keypath
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
    
    /// Return maximum element in collection by keypath
    func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        return self.max { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
    
    /// Return minimum element in collection by keypath
    func min<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        return self.min { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}

 extension CALayer {
    
    func applySketchShadow(
        style: UIUserInterfaceStyle = .unspecified,
        color: UIColor = .black,
        alpha: Float = 0.12,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0,
        useShadowPath: Bool = false) {
        var alpha = alpha
        if style == .light {
            alpha = 0.12
        } else {
            alpha = 0.32
        }
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur // 2.0
        if spread == 0 {
            if useShadowPath {
                let extendedRect = CGRect(x: -blur,
                                          y: -blur,
                                          width: bounds.width + blur,
                                          height: bounds.width + blur)
                shadowPath = UIBezierPath(rect: extendedRect).cgPath
            } else {
                shadowPath = nil
            }
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }

    func applySketchShadowStepOne(
        color: UIColor = .black,
        alpha: Float = 0.12,
        x: CGFloat = 0,
        y: CGFloat = 4,
        blur: CGFloat = 16,
        spread: CGFloat = 0) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur // 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }

    func applySketchShadowStepTwo(
        color: UIColor = .black,
        alpha: Float = 0.02,
        x: CGFloat = 0,
        y: CGFloat = 1,
        blur: CGFloat = 4,
        spread: CGFloat = 0) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur // 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }

    func applySketchButtonShadow(
        color: UIColor = .blue,
        alpha: Float = 0.32,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur // 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }

    func clearShadow() {
        shadowColor = UIColor.clear.cgColor
        shadowOpacity = 0
        shadowOffset = .zero
        shadowRadius = 0
        shadowPath = nil
    }
}

// MARK: - WithStyle

 extension UIColor {
    
    func fade(toColor: UIColor, withPercentage: CGFloat) -> UIColor {
        var fromRed: CGFloat = 0.0
        var fromGreen: CGFloat = 0.0
        var fromBlue: CGFloat = 0.0
        var fromAlpha: CGFloat = 0.0

        self.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)

        var toRed: CGFloat = 0.0
        var toGreen: CGFloat = 0.0
        var toBlue: CGFloat = 0.0
        var toAlpha: CGFloat = 0.0

        toColor.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)

        //calculate the actual RGBA values of the fade colour
        let red = (toRed - fromRed) * withPercentage + fromRed
        let green = (toGreen - fromGreen) * withPercentage + fromGreen
        let blue = (toBlue - fromBlue) * withPercentage + fromBlue
        let alpha = (toAlpha - fromAlpha) * withPercentage + fromAlpha

        // return the fade colour
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        let divisor = CGFloat(255)
        let red = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green = CGFloat((hex6 & 0x00FF00) >> 8) / divisor
        let blue = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func hexStringToUIColor(hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count != 6 {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    static func hexNilToUIColor(hex: String?) -> UIColor? {
        guard let hex = hex else { return nil }
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count != 6 {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    // swiftlint:disable line_length
    func toHexString() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }

    var coreImageColor: CIColor {
        CIColor(color: self)
    }

    var hexInt: UInt32 {
        let red = UInt32(coreImageColor.red * 255 + 0.5)
        let green = UInt32(coreImageColor.green * 255 + 0.5)
        let blue = UInt32(coreImageColor.blue * 255 + 0.5)
        return (red << 16) | (green << 8) | blue
    }
    
    static var random: UIColor {
        return .init(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 1)
    }
}

extension UINavigationController {

     func addLightBlurEffect() {
        var blurEffectView = UIVisualEffectView()
        // Find size for blur effect.
        let statusBarHeight = UIApplication.DITStatusBarFrame.size.height
        let bounds = navigationBar.bounds.insetBy(dx: 0, dy: -statusBarHeight).offsetBy(dx: 0, dy: -statusBarHeight)
        // Create blur effect.
        blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Set navigation bar up.
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.addSubview(blurEffectView)
        navigationBar.sendSubviewToBack(blurEffectView)
    }

     func addDarkBlurEffect() {
        var blurEffectView = UIVisualEffectView()
        // Find size for blur effect.
        let statusBarHeight = UIApplication.DITStatusBarFrame.size.height
        let bounds = navigationBar.bounds.insetBy(dx: 0, dy: -statusBarHeight).offsetBy(dx: 0, dy: -statusBarHeight)
        // Create blur effect.
        blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Set navigation bar up.
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.addSubview(blurEffectView)
        navigationBar.sendSubviewToBack(blurEffectView)
    }

     func pushViewController(_ viewController: UIViewController,
                                   animated: Bool,
                                   completion: (() -> Void)?) {
        pushViewController(viewController, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            completion?()
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
    }

     func setViewControllers(_ viewControllers: [UIViewController],
                                   animated: Bool,
                                   completion: (() -> Void)?) {
        setViewControllers(viewControllers, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            completion?()
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
    }

    @available(iOS 13.0, *)
     func applyStandart() {
        navigationBar.standardAppearance.configureWithDefaultBackground()
    }

    @available(iOS 13.0, *)
     func killAppearance() {
        navigationBar.standardAppearance.configureWithTransparentBackground()
    }

     func clear() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        toolbar.setBackgroundImage(UIImage().withRenderingMode(.alwaysTemplate), forToolbarPosition: .any, barMetrics: .default)
        toolbar.backgroundColor = .clear
        navigationBar.backgroundColor = .clear
    }
}

/// Passes through all touch events to views behind it, except when the
/// touch occurs in a contained UIControl or view with a gesture
/// recognizer attached
 final class PassThroughNavigationBar: UINavigationBar {

    override  func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard nestedInteractiveViews(in: self, contain: point) else { return false }
        return super.point(inside: point, with: event)
    }

    private func nestedInteractiveViews(in view: UIView, contain point: CGPoint) -> Bool {

        if view.isPotentiallyInteractive, view.bounds.contains(convert(point, to: view)) {
            return true
        }

        for subview in view.subviews {
            if nestedInteractiveViews(in: subview, contain: point) {
                return true
            }
        }

        return false
    }
}

 extension UIView {
    var isPotentiallyInteractive: Bool {
        guard isUserInteractionEnabled else { return false }
        return (isControl || doesContainGestureRecognizer)
    }

    var isControl: Bool {
        self is UIControl
    }

    var doesContainGestureRecognizer: Bool {
        !(gestureRecognizers?.isEmpty ?? true)
    }
}

extension UIApplication {
    // MARK: - Find Top View Controller

    static func topViewController() -> UIViewController? {
        findTopViewController(UIApplication.shared.delegate?.window??.rootViewController)
    }

    static private func findTopViewController(_ controller: UIViewController? =
        UIApplication.DITKeyWindow?.rootViewController) -> UIViewController? {

        if let navigationController = controller as? UINavigationController {
            return findTopViewController(navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return findTopViewController(selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return findTopViewController(presented)
        }
        return controller
    }

    /// #crutch to avoid deprecation warnings
    static var DITStatusBarFrame: CGRect {
        UIApplication.shared.statusBarFrame
    }

    /// #crutch to avoid deprecation warnings
    static var DITKeyWindow: UIWindow? {
        UIApplication.shared.keyWindow
    }
    
    /// #crutch to avoid deprecation warnings
    static var DITStatusBarOrientation: UIInterfaceOrientation {
        UIApplication.shared.statusBarOrientation
    }
        
    /// OS-safe MacBook M1 check, returns true if app running on M1/Apple Silicon chipset
    static var isOnMacM1: Bool {
        if #available(iOS 14.0, *),
           ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        } else {
            return false
        }
    }
}

import UIKit

protocol ViewFromNibLoadable: AnyObject {

}

extension ViewFromNibLoadable where Self: UIView {
    func loadFromNib(using aDecoder: NSCoder) -> Any? {
        if !subviews.isEmpty {
            return self
        }

        let bundle = Bundle(for: type(of: self))
        guard let view = bundle.loadNibNamed(String(describing: type(of: self)), owner: nil, options: nil)?.first as? UIView
            else {
                return nil
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        let contraints = constraints
        removeConstraints(contraints)
        view.addConstraints(contraints)

        return view
    }
}

 extension UIView {

    @discardableResult
    static func fromNib<T: UIView>(owner: Any? = self, bundle: Bundle? = .main) -> T? {
        guard let view = bundle?.loadNibNamed(self.className, owner: owner, options: nil)?[0] as? T else {
            return nil
        }

        return view
    }

    @discardableResult
    func fromNib<T: UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self))
            .loadNibNamed(self.className, owner: self, options: nil)?.first as? T else {
            return nil
        }
        addSubview(contentView)
        contentView.fillSuperview()
        return contentView
    }
}

 extension UIView {
    
    var isAnimating: Bool {
        (layer.animationKeys() ?? []).isEmpty == false || recursiveSubviews.reduce(true, { $0 || ($1.layer.animationKeys() ?? []).isEmpty == false })
    }
    
    var recursiveSubviews: [UIView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}

//
//  UIView+Anchors.swift
//
//


import UIKit

extension UIView {
     func addConstraintsWithFormat(_ format: String, views: UIView...) {

        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format,
                                                      options: NSLayoutConstraint.FormatOptions(),
                                                      metrics: nil,
                                                      views: viewsDictionary))
    }

     func safeFillSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let superview = superview {
            leftAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leftAnchor).isActive = true
            rightAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.rightAnchor).isActive = true
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
    }

     func fillSuperview(_ insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        if let superview = superview {
            leftAnchor.constraint(equalTo: superview.leftAnchor, constant: insets.left).isActive = true
            rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -insets.right).isActive = true
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom).isActive = true
        }
    }

     func anchor(_ top: NSLayoutYAxisAnchor? = nil,
                       left: NSLayoutXAxisAnchor? = nil,
                       bottom: NSLayoutYAxisAnchor? = nil,
                       right: NSLayoutXAxisAnchor? = nil,
                       width: NSLayoutDimension? = nil,
                       height: NSLayoutDimension? = nil,
                       topConstant: CGFloat = 0,
                       leftConstant: CGFloat = 0,
                       bottomConstant: CGFloat = 0,
                       rightConstant: CGFloat = 0,
                       widthConstant: CGFloat = 0,
                       heightConstant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false

        _ = anchorWithReturnAnchors(top,
                                    left: left,
                                    bottom: bottom,
                                    right: right,
                                    width: width,
                                    height: height,
                                    topConstant: topConstant,
                                    leftConstant: leftConstant,
                                    bottomConstant: bottomConstant,
                                    rightConstant: rightConstant,
                                    widthConstant: widthConstant,
                                    heightConstant: heightConstant)
    }

     func anchor(top: NSLayoutYAxisAnchor? = nil,
                       left: NSLayoutXAxisAnchor? = nil,
                       bottom: NSLayoutYAxisAnchor? = nil,
                       right: NSLayoutXAxisAnchor? = nil,
                       width: NSLayoutDimension? = nil,
                       height: NSLayoutDimension? = nil,
                       insets: UIEdgeInsets? = .init(top: 0, left: 0, bottom: 0, right: 0),
                       size: CGSize? = .init(width: 0, height: 0)) {
        translatesAutoresizingMaskIntoConstraints = false
        anchor(top,
               left: left,
               bottom: bottom,
               right: right,
               width: width,
               height: height,
               topConstant: insets?.top ?? 0,
               leftConstant: insets?.left ?? 0,
               bottomConstant: insets?.bottom ?? 0,
               rightConstant: insets?.right ?? 0,
               widthConstant: size?.width ?? 0,
               heightConstant: size?.height ?? 0)
    }

     func anchorWithReturnAnchors(_ top: NSLayoutYAxisAnchor? = nil,
                                        left: NSLayoutXAxisAnchor? = nil,
                                        bottom: NSLayoutYAxisAnchor? = nil,
                                        right: NSLayoutXAxisAnchor? = nil,
                                        width: NSLayoutDimension? = nil,
                                        height: NSLayoutDimension? = nil,
                                        topConstant: CGFloat = 0,
                                        leftConstant: CGFloat = 0,
                                        bottomConstant: CGFloat = 0,
                                        rightConstant: CGFloat = 0,
                                        widthConstant: CGFloat = 0,
                                        heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false

        var anchors = [NSLayoutConstraint]()

        if let top = top {
            anchors.append(topAnchor.constraint(equalTo: top, constant: topConstant))
        }

        if let left = left {
            anchors.append(leftAnchor.constraint(equalTo: left, constant: leftConstant))
        }

        if let bottom = bottom {
            anchors.append(bottomAnchor.constraint(equalTo: bottom, constant: -bottomConstant))
        }

        if let right = right {
            anchors.append(rightAnchor.constraint(equalTo: right, constant: -rightConstant))
        }

        if let width = width {
            anchors.append(widthAnchor.constraint(equalTo: width, constant: widthConstant))
        } else if widthConstant > 0 {
            anchors.append(widthAnchor.constraint(equalToConstant: widthConstant))
        }

        if let height = height {
            anchors.append(heightAnchor.constraint(equalTo: height, constant: heightConstant))
        } else if heightConstant > 0 {
            anchors.append(heightAnchor.constraint(equalToConstant: heightConstant))
        }

        anchors.forEach({ $0.isActive = true })

        return anchors
    }

     func anchorCenterXToSuperview(constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }

    @discardableResult
     func anchorCenterYToSuperview(constant: CGFloat = 0) -> NSLayoutConstraint? {
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerYAnchor {
            let constraint = centerYAnchor.constraint(equalTo: anchor, constant: constant)
            constraint.isActive = true
            return constraint
        }
        return nil
    }

     func anchorCenterSuperview() {
        anchorCenterXToSuperview()
        anchorCenterYToSuperview()
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner = [.allCorners],
                      radius: CGFloat) {
        let size = CGSize(width: radius, height: radius)
        let path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: corners,
                                cornerRadii: size)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.backgroundColor = backgroundColor?.cgColor
        self.layer.mask = mask
    }
}

extension UIEdgeInsets {

     init(singleValue: CGFloat) {
        self.init(top: singleValue,
                  left: singleValue,
                  bottom: singleValue,
                  right: singleValue)
    }

     var horizontalSum: CGFloat {
        left + right
    }

     var verticalSum: CGFloat {
        bottom + top
    }
}

 extension UIView {
    func addTopRoundCorners(radius: CGFloat = 30) {
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
        layer.masksToBounds = true
        layer.name = "CorneredCornerView"
    }

    func dropShadow(color: UIColor) {
        layer.cornerRadius = 14
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.masksToBounds = false
    }

    func makeOval(clipsBounds: Bool = false, animated: Bool = false) {
        if clipsBounds {
            clipsToBounds = true
            layer.masksToBounds = true
        }
        let isVerticalShape = bounds.height >= bounds.width
        if animated {
            UIView.animate(withDuration: 0.3) {[weak self] in
                guard let self = self else { return }
                self.layer.cornerRadius = (isVerticalShape ? self.bounds.width : self.bounds.height) / 2
            }
        } else {
            UIView.performWithoutAnimation {[weak self] in
                guard let self = self else { return }
                self.layer.cornerRadius = (isVerticalShape ? self.bounds.width : self.bounds.height) / 2
            }
        }

    }
}

import UIKit

extension UIView {
    convenience init(height: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: 0, height: height)
        self.init(frame: frame)
    }

    func fm_addToParentView(_ view: UIView) {
        view.addSubview(self)
    }

    func fm_removeViewWithTag(tag: Int) {

        for view in subviews where view.tag == tag {
            view.removeFromSuperview()
        }
    }
}

extension UIStackView {
    @discardableResult func removeAllArrangedSubviews() -> [UIView] {
        let removedSubviews = arrangedSubviews.reduce([]) { removedSubviews, subview -> [UIView] in
            self.removeArrangedSubview(subview)
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
            return removedSubviews + [subview]
        }
        return removedSubviews
    }
}

 extension UIView {
    func makeSkeletonable(excluding: [UIView?] = []) {
        if let self = self as? UILabel {
            self.linesCornerRadius = 4
        }
        switch self {
        case is UIButton:
            isSkeletonable = false
        default:
            isSkeletonable = true
        }
        if excluding.contains(self) {
            isSkeletonable = false
        }
        subviews.forEach { $0.makeSkeletonable(excluding: excluding) }
    }
}

public struct ShimmersAppearance {
    public static var shimmerGradientBaseColor: UIColor = .hexStringToUIColor(hex: "F0F0F0")
    public static var shimmerGradientSecondaryColor: UIColor = .hexStringToUIColor(hex: "FFFFFF")
}

import SkeletonView



 extension SkeletonGradient {

    static var mainGradient: SkeletonGradient {
        SkeletonGradient(baseColor: ShimmersAppearance.shimmerGradientBaseColor,
                         secondaryColor: ShimmersAppearance.shimmerGradientSecondaryColor)
    }
}


 extension UIViewController {

    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func alertWithTwoButtons(title: String,
                             message: String,
                             cancelText: String,
                             agreementText: String,
                             completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: cancelText, style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: agreementText, style: UIAlertAction.Style.default, handler: {_ in
            completion()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func showError(error: Error, completion: ((UIAlertAction) -> Void)? = nil) {
        let completionHandler: ((UIAlertAction) -> Void)
        if let completion = completion {
            completionHandler = completion
        } else {
            completionHandler = { _ in }
        }
        showAlert(title: "\(error.title)", message: error.message, handler: completionHandler)
    }
    
    func showDestructiveError(error: Error, completion: ((UIAlertAction) -> Void)? = nil, handlerTitle: String? = "Выход") {
        let completionHandler: ((UIAlertAction) -> Void)
        if let completion = completion {
            completionHandler = completion
        } else {
            completionHandler = { _ in }
        }
        endEditing()
        let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        let destructiveAction = UIAlertAction(title: handlerTitle, style: .destructive, handler: completionHandler)
        alert.addAction(destructiveAction)
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String? = nil, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(close)
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String? = nil, message: String?, handler: @escaping ((UIAlertAction) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "OK", style: .cancel, handler: handler)
        alert.addAction(close)
        present(alert, animated: true, completion: nil)
    }

    func showSelfDestructionAlert(title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        delay(1) {
            alert.dismiss(animated: true)
        }
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String? = nil,
                   textFieldPlaceholder: String? = nil,
                   keyboardType: UIKeyboardType = .default,
                   contentType: UITextContentType? = nil,
                   message: String?,
                   closeHandler: ((UIAlertAction) -> Void)? = nil,
                   submitHandler: @escaping ((String?) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "Отмена", style: .cancel, handler: closeHandler)
        var textField: UITextField!
        alert.addTextField { CLTextField in
            CLTextField.placeholder = textFieldPlaceholder
            textField = CLTextField
            textField.keyboardType = keyboardType
            if #available(iOS 10.0, *), let contentType = contentType {
                textField.textContentType = contentType
            }
        }
        let submit = UIAlertAction(title: "OK", style: .default) { _ in
            submitHandler(textField.text)
        }
        alert.addAction(close)
        alert.addAction(submit)
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String? = nil,
                   textFieldPlaceholder: String? = nil,
                   textFieldText: String? = nil,
                   keyboardType: UIKeyboardType = .default,
                   contentType: UITextContentType? = nil,
                   message: String?,
                   closeHandler: ((UIAlertAction) -> Void)? = nil,
                   submitButtonText: String = "OK",
                   submitHandler: @escaping ((String?) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "Отмена", style: .cancel, handler: closeHandler)
        var textField: UITextField!
        alert.addTextField { CLTextField in
            CLTextField.placeholder = textFieldPlaceholder
            CLTextField.text = textFieldText
            textField = CLTextField
            textField.keyboardType = keyboardType
            if #available(iOS 10.0, *), let contentType = contentType {
                textField.textContentType = contentType
            }
        }
        let submit = UIAlertAction(title: submitButtonText, style: .default) { _ in
            submitHandler(textField.text)
        }
        alert.addAction(close)
        alert.addAction(submit)
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String?, message: String?, closeHandler:(() -> Void)?, submitHandler: @escaping (() -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            closeHandler?()
        })
        alert.addAction(close)
        let submit = UIAlertAction(title: "OK", style: .default) { _ in
            submitHandler()
        }
        alert.addAction(submit)
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String?,
                   attributedMessage: NSAttributedString,
                   closeHandler: ((UIAlertAction) -> Void)?,
                   submitHandler: @escaping ((UIAlertAction) -> Void)) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        let close = UIAlertAction(title: "Отмена", style: .cancel, handler: closeHandler)
        let submit = UIAlertAction(title: "OK", style: .default, handler: submitHandler)
        alert.addAction(close)
        alert.addAction(submit)
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String? = nil,
                   message: String? = nil,
                   actions: [UIAlertAction],
                   closeHandler: ((UIAlertAction) -> Void)? = nil) {
        endEditing()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "Отмена", style: .default, handler: closeHandler)
        alert.addAction(close)
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true, completion: nil)
    }

    func showActionSheet(title: String? = nil,
                         message: String? = nil,
                         actions: [UIAlertAction],
                         closeHandler: ((UIAlertAction) -> Void)? = nil) {
        endEditing()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let close = UIAlertAction(title: "Отмена", style: .cancel, handler: closeHandler)
        alert.addAction(close)
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true, completion: nil)
    }

    func endEditing() {
        self.view.endEditing(true)
    }
}

import Foundation

 enum DITError: Error {

     enum ValidationFailureReason {
        case invalidLogin
        case invalidPassword
        case emptyEmail
        case emptyPassword
        case invalidPhoneNumber
        case invalidCode
    }

    case validationFailed(reason: ValidationFailureReason)
    case fatalError
    case networkError
    case invalidCurrentUser
    case invalidPathForFile(url: String)
    case incorrectDataFormat
    case customError(text: String)
    case customTitle(title: String, description: String)
}

 extension DITError {

    var isValidationError: Bool {
        if case .validationFailed = self {
            return true
        }
        return false
    }
}

extension DITError: LocalizedError {

     var errorDescription: String? {
        switch self {
        case .fatalError:
            return "Fatal error"
        case .networkError:
            return "Common.NoNetwork"
        case .invalidCurrentUser:
            return "No current user"
        case .invalidPathForFile(let url):
            return "Path for url is invalid URL: \(url)"
        case .incorrectDataFormat:
            return "Incorrect data format"
        case .customError(let text):
            return text
        case .customTitle(_, let desc):
            return desc
        default:
            return localizedDescription
        }
    }
}

 protocol Descriptionable {
    var title: String { get }
    var message: String { get }
    var code: Int { get }
}

 extension Error {

    var title: String {
        if let error = self as? Descriptionable {
            return error.title
        }
        switch self {
        case is DITError:
            let ditError = (self as! DITError)
            switch ditError {
            case .customTitle(let title, _):
                return title
            default:
                return "Ошибка"
            }
            return "Ошибка"
        case is NSError:
            let nsError = self as NSError
            return "Ошибка: \(nsError.code)"
        default:
            return "Ошибка"
        }
    }

    var message: String {
        if let error = self as? Descriptionable {
            return error.message
        }
        switch self {
        case is DITError:
            let ditError = (self as! DITError)
            switch ditError {
            case is NSError:
                var detail = ""
                if let detailFailure = (self as NSError).localizedFailureReason {
                    detail = "\n\(detailFailure)"
                }
                return "\(localizedDescription)\(detail)"
            default:
                return localizedDescription
            }
            return localizedDescription
        default:
            var detail = ""
            if let detailFailure = (self as NSError).localizedFailureReason {
                detail = "\n\(detailFailure)"
            }
            return "\(localizedDescription)\(detail)"
        }
    }
    
    var code: Int {
        if let error = self as? Descriptionable {
            return error.code
        }
        switch self {
        case is DITError:
            let ditError = (self as! DITError)
            switch ditError {
            default:
                return -1
            }
            return -1
        case is NSError:
            let nsError = self as NSError
            return nsError.code
        default:
            return -1
        }
    }
}

import UIKit

 extension UIView {

    var fullEdgesHeight: CGFloat {
        let safeArea = (UIApplication.DITStatusBarFrame.height + self.safeAreaInsets.bottom)
        return UIScreen.main.bounds.height - safeArea
    }

    func constrainCentered(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false

        let verticalContraint = NSLayoutConstraint(
            item: subview,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0)

        let horizontalContraint = NSLayoutConstraint(
            item: subview,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0)

        let heightContraint = NSLayoutConstraint(
            item: subview,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: subview.frame.height)

        let widthContraint = NSLayoutConstraint(
            item: subview,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: subview.frame.width)

        addConstraints([
            horizontalContraint,
            verticalContraint,
            heightContraint,
            widthContraint])

    }

    func constrainToEdgesWithTopInset(inset: CGFloat, subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false

        let topContraint = NSLayoutConstraint(
            item: subview,
            attribute: .top,
            relatedBy: .equal,
            toItem: self,
            attribute: .top,
            multiplier: 1.0,
            constant: inset)

        let bottomConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0)

        let leadingContraint = NSLayoutConstraint(
            item: subview,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self,
            attribute: .leading,
            multiplier: 1.0,
            constant: 0)

        let trailingContraint = NSLayoutConstraint(
            item: subview,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1.0,
            constant: 0)

        addConstraints([
            topContraint,
            bottomConstraint,
            leadingContraint,
            trailingContraint])
    }

}
