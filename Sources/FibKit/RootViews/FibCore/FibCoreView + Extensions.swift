//
//  File.swift
//  
//
//  Created by Денис Садаков on 23.08.2023.
//

import Foundation

extension PopoverServiceInstance {
	
	public struct TopSpacer {
		public var color: UIColor
		public var height: CGFloat
		
		public init(color: UIColor, height: CGFloat) {
			self.color = color
			self.height = height
		}
	}
	
	public struct Action {
		public var title: String
		public var image: UIImage?
		public var textColor: UIColor = .darkText
		public var isImageOnLeft = false
		public var topSpacer: TopSpacer?
		public var handler: (() -> Void)?
		
		public init(title: String, image: UIImage? = nil, textColor: UIColor = .darkText, isImageOnLeft: Bool = false, topSpacer: PopoverServiceInstance.TopSpacer? = nil, handler: (() -> Void)? = nil) {
			self.title = title
			self.image = image
			self.textColor = textColor
			self.isImageOnLeft = isImageOnLeft
			self.topSpacer = topSpacer
			self.handler = handler
		}
		
	}
}

extension CALayer {
	
	func applyShadow(with descriptor: ShadowDescriptor) {
		applySketchShadow(style: descriptor.style,
						  color: descriptor.color,
						  alpha: descriptor.alpha,
						  x: descriptor.x,
						  y: descriptor.y,
						  blur: descriptor.blur,
						  spread: descriptor.spread,
						  useShadowPath: descriptor.useShadowPath)
	}
	
	func getShadowDescriptor() -> ShadowDescriptor {
		return .init(style: UIScreen.main.traitCollection.userInterfaceStyle,
					 color: UIColor(cgColor: shadowColor ?? CGColor(gray: 0, alpha: 0)),
					 alpha: shadowOpacity,
					 x: shadowOffset.width,
					 y: shadowOffset.height,
					 blur: shadowRadius,
					 spread: 0,
					 useShadowPath: false)
	}
	
	func applySketchShadow(
		style: UIUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle,
		color: UIColor = withStyle(light: .black, dark: .clear),
		alpha: Float = withStyle(light: 0.12, dark: 0.32),
		x: CGFloat = 0,
		y: CGFloat = 2,
		blur: CGFloat = 4,
		spread: CGFloat = 0,
		useShadowPath: Bool = false) {
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
	
	func applySketchHighlightedShadow(
		style: UIUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle,
		color: UIColor = withStyle(light: .black, dark: .clear),
		alpha: Float = 0.55,
		x: CGFloat = 0,
		y: CGFloat = 1,
		blur: CGFloat = 2,
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
		color: UIColor = .systemFill,
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
		color: UIColor = .systemFill,
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
		color: UIColor = .systemBlue,
		alpha: Float = 0.32,
		x: CGFloat = 0,
		y: CGFloat = 4,
		blur: CGFloat = 4,
		spread: CGFloat = -16
	) {
		shadowColor = color.cgColor
		shadowOpacity = alpha
		shadowOffset = CGSize(width: x, height: y)
		shadowRadius = blur // 2.0
		if spread == 0 {
			shadowPath = nil
		} else {
			let dx = -spread
			let rect = bounds.insetBy(dx: dx, dy: 0)
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


extension Optional {
	
	var isNil: Bool {
		switch self {
			case .none:
				return true
			default:
				return false
		}
	}
}
