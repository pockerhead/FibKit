import UIKit

// swiftlint:disable all


internal extension CGFloat {
	func clamp(_ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
		return self < minValue ? minValue : (self > maxValue ? maxValue : self)
	}

	func softClamp(_ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
		self <= minValue ? minValue : (self >= maxValue ? maxValue : self)
	}
}

internal extension Double {
	func clamp(_ minValue: Double, _ maxValue: Double) -> Double {
		return self < minValue ? minValue : (self > maxValue ? maxValue : self)
	}

	func softClamp(_ minValue: Double, _ maxValue: Double) -> Double {
		self <= minValue ? minValue : (self >= maxValue ? maxValue : self)
	}
}

internal extension Int {
	func clamp(_ minValue: Int, _ maxValue: Int) -> Int {
		return self < minValue ? minValue : (self > maxValue ? maxValue : self)
	}

	func softClamp(_ minValue: Int, _ maxValue: Int) -> Int {
		self <= minValue ? minValue : (self >= maxValue ? maxValue : self)
	}
}

internal extension CGPoint {
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

internal extension CGSize {
	func insets(by insets: UIEdgeInsets) -> CGSize {
		return CGSize(width: width - insets.left - insets.right, height: height - insets.top - insets.bottom)
	}
	var transposed: CGSize {
		return CGSize(width: height, height: width)
	}
}

internal func abs(_ left: CGPoint) -> CGPoint {
	return CGPoint(x: abs(left.x), y: abs(left.y))
}
internal func min(_ left: CGPoint, _ right: CGPoint) -> CGPoint {
	return CGPoint(x: min(left.x, right.x), y: min(left.y, right.y))
}
internal func - (left: CGRect, right: CGPoint) -> CGRect {
	return CGRect(origin: left.origin - right, size: left.size)
}
internal func / (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x/right, y: left.y/right)
}
internal func * (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x*right, y: left.y*right)
}
internal func * (left: CGFloat, right: CGPoint) -> CGPoint {
	return right * left
}
internal func * (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x*right.x, y: left.y*right.y)
}
internal prefix func - (point: CGPoint) -> CGPoint {
	return CGPoint.zero - point
}
internal func / (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width/right, height: left.height/right)
}
internal func - (left: CGPoint, right: CGSize) -> CGPoint {
	return CGPoint(x: left.x - right.width, y: left.y - right.height)
}

internal extension CGRect {
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
