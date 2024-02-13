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
		String(describing: type(of: view)).contains("TextLayoutCanvasView")
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
