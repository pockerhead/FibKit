//
//  ShadowDescriptor.swift
//  
//
//  Created by Денис Садаков on 23.08.2023.
//

public struct ShadowDescriptor {
	init(style: UIUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle, color: UIColor = withStyle(light: .black, dark: .clear), alpha: Float = 0.12, x: CGFloat = 0, y: CGFloat = 2, blur: CGFloat = 4, spread: CGFloat = 0, useShadowPath: Bool = false) {
		self.style = style
		self.color = color
		self.alpha = alpha
		self.x = x
		self.y = y
		self.blur = blur
		self.spread = spread
		self.useShadowPath = useShadowPath
	}

	public init (color: UIColor = withStyle(light: .black, dark: .clear), alpha: Float = 0.12, x: CGFloat = 0, y: CGFloat = 2, blur: CGFloat = 4, spread: CGFloat = 0, useShadowPath: Bool = false) {
		.init(style: UIScreen.main.traitCollection.userInterfaceStyle,
			  color: color,
			  alpha: alpha,
			  x: x,
			  y: y,
			  blur: blur,
			  spread: spread,
			  useShadowPath: useShadowPath)
	}

	
	static var `default` = ShadowDescriptor()
	
	var style: UIUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle,
			   color: UIColor = withStyle(light: .black, dark: .clear),
			   alpha: Float = 0.12,
			   x: CGFloat = 0,
			   y: CGFloat = 2,
			   blur: CGFloat = 4,
			   spread: CGFloat = 0,
			   useShadowPath: Bool = false
}
