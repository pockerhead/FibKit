//
//  UIView + IQKeyboardManagerDistance.swift
//  SmartStaff
//
//  Created by Артём Балашов on 09.04.2021.
//  Copyright © 2021 DIT. All rights reserved.
//

import UIKit

public extension UIView {
    private struct AssociatedKeys {
      static var _needToFixSwiftUIWrapperInFormView = "com.SmartStaff._needToFixSwiftUIWrapperInFormView"
    }

    var needToFixSwiftUIWrapperInFormView: Bool? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys._needToFixSwiftUIWrapperInFormView) as? Bool }
        set { objc_setAssociatedObject(self, &AssociatedKeys._needToFixSwiftUIWrapperInFormView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}


@objc public extension UIView {
    
    /// Костыль который заставляет IQKeyboardManager игнорировать UIHostingController при обработке текстфилда внутри SwiftUIWrapper
    static func swizzleViewContainingController() {
        let originalSelector = #selector(UIView.viewContainingController)
        let swizzledSelector = #selector(UIView.swizzledViewContainingController)
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
    }
    
    @objc func swizzledViewContainingController()->UIViewController? {
        
        var nextResponder: UIResponder? = self
        
        repeat {
            nextResponder = nextResponder?.next
            
            if let viewController = nextResponder as? UIViewController,
               (needToFixSwiftUIWrapperInFormView ?? false) ? !String(reflecting: viewController).contains("UIHostingController") : true {
                return viewController
            }
            
        } while nextResponder != nil
        
        return nil
    }
}
