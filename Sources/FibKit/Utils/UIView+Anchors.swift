import UIKit

extension UIView {
	internal func addConstraintsWithFormat(_ format: String, views: UIView...) {

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

	internal func safeFillSuperview() {
		translatesAutoresizingMaskIntoConstraints = false
		if let superview = superview {
			leftAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leftAnchor).isActive = true
			rightAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.rightAnchor).isActive = true
			topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor).isActive = true
			bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor).isActive = true
		}
	}

	internal func fillSuperview(_ insets: UIEdgeInsets = .zero) {
		translatesAutoresizingMaskIntoConstraints = false
		if let superview = superview {
			leftAnchor.constraint(equalTo: superview.leftAnchor, constant: insets.left).isActive = true
			rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -insets.right).isActive = true
			topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top).isActive = true
			bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom).isActive = true
		}
	}

	internal func anchor(_ top: NSLayoutYAxisAnchor? = nil,
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

	internal func anchor(top: NSLayoutYAxisAnchor? = nil,
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

	internal func anchorWithReturnAnchors(_ top: NSLayoutYAxisAnchor? = nil,
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

	internal func anchorCenterXToSuperview(constant: CGFloat = 0) {
		translatesAutoresizingMaskIntoConstraints = false
		if let anchor = superview?.centerXAnchor {
			centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
		}
	}

	@discardableResult
	internal func anchorCenterYToSuperview(constant: CGFloat = 0) -> NSLayoutConstraint? {
		translatesAutoresizingMaskIntoConstraints = false
		if let anchor = superview?.centerYAnchor {
			let constraint = centerYAnchor.constraint(equalTo: anchor, constant: constant)
			constraint.isActive = true
			return constraint
		}
		return nil
	}

	internal func anchorCenterSuperview() {
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

	internal init(singleValue: CGFloat) {
		self.init(top: singleValue,
				  left: singleValue,
				  bottom: singleValue,
				  right: singleValue)
	}

	internal var horizontalSum: CGFloat {
		left + right
	}

	internal var verticalSum: CGFloat {
		bottom + top
	}
}

internal extension UIView {
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

	func makeOval(clipsBounds: Bool = false, animated: Bool = false, cornerCurve: CALayerCornerCurve = .continuous) {
		if clipsBounds {
			clipsToBounds = true
			layer.masksToBounds = true
		}
		let isVerticalShape = bounds.height >= bounds.width
		self.layer.cornerCurve = cornerCurve
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
