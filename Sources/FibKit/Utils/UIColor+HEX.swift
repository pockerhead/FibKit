internal extension UIColor {
	
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
		if components?.count == 2 {
			let b: CGFloat = components?[0] ?? 0.0
			let a: CGFloat = components?[1] ?? 0.0
			let hexString = String(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(b * 255)), lroundf(Float(b * 255)), lroundf(Float(b * 255)), lroundf(Float(a * 255)))
			return hexString
		}
		let r: CGFloat = components?[0] ?? 0.0
		let g: CGFloat = components?[1] ?? 0.0
		let b: CGFloat = components?[2] ?? 0.0
		let a: CGFloat = components?[3] ?? 0.0
		
		let hexString = String(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)), lroundf(Float(a * 255)))
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
}
