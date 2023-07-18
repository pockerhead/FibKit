//
//  RootTransparentStyleViewController.swift
//  FibKit
//
//  Created by Danil Pestov on 16.09.2022.
//  Copyright © 2022 DIT Moscow. All rights reserved.
//


import UIKit


/// View Controller который нужно использовать как rootViewController в дополнительных UIWindow для того, чтобы был корректный стиль у статус бара
open class RootTransparentStyleViewController: UIViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        let style = withStyle(light: UIStatusBarStyle.darkContent, dark: .lightContent)
        return style
    }
}

public func withStyle<T>(light: T, dark: T) -> T {
	guard let window = UIApplication.shared.delegate?.window else { return light }
	guard let style = window?.overrideUserInterfaceStyle else { return light }
	switch style {
	case .dark: return dark
	case .light: return light
	case .unspecified: return light
	@unknown default:
		return light
	}
}
