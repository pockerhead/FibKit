//
//  File.swift
//  
//
//  Created by Артём Балашов on 18.10.2023.
//

import UIKit
import SwiftUI

public class HeaderObserver: ObservableObject {
	@Published public var size: CGSize
	@Published public var initialHeight: CGFloat
	@Published public var maxHeight: CGFloat?
	@Published public var minHeight: CGFloat?
	
	public init(size: CGSize = .init(width: 1, height: 1), initialHeight: CGFloat = 1) {
		self.size = size
		self.initialHeight = initialHeight
	}
}

public class ShutterView: UIView {}

internal class RootGridViewBackground: UIView {
	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard FibGridPassthroughHelper.nestedInteractiveViews(in: self, contain: point, convertView: self) else {
			return false
		}
		return super.point(inside: point, with: event)
	}
}

extension UIViewController {
	
	func setNavbarTitle(_ title: String?, animated: Bool = true) {
		guard navigationItem.title != title else { return }
		if animated {
			let fadeTextAnimation = CATransition()
			fadeTextAnimation.duration = 0.1
			fadeTextAnimation.type = .fade
			navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
		}
		navigationItem.title = title
		navigationController?.navigationBar.setNeedsLayout()
	}
}
