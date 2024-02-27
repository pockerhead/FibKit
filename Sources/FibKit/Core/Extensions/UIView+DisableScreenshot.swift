//
//  File.swift
//  
//
//  Created by Артём Балашов on 13.02.2024.
//

import UIKit

private let textField: UITextField = UITextField()
private let secureView: UIView? = {
	textField.subviews.first { view in
		if #available(iOS 15, *) {
			return String(describing: type(of: view)).contains("TextLayoutCanvasView")
		}
		
		if #available(iOS 14, *) {
			return String(describing: type(of: view)).contains("TextFieldCanvasView")
		}
		
		if #available(iOS 13, *) {
			return String(describing: type(of: view)).contains("TextFieldCanvasView")
		}
		
		if #available(iOS 12, *) {
			return String(describing: type(of: view)).contains("TextFieldContentView")
		}
		return false
	}
}()

public func setLayerDisableScreenshots(_ layer: CALayer, _ disableScreenshots: Bool) {
	guard let secureView = secureView else { return }
	
	let previousLayer: CALayer = secureView.layer
	secureView.setValue(layer, forKey: "layer")
	if disableScreenshots {
		textField.isSecureTextEntry = false
		textField.isSecureTextEntry = true
	} else {
		textField.isSecureTextEntry = true
		textField.isSecureTextEntry = false
	}
	secureView.setValue(previousLayer, forKey: "layer")
}
