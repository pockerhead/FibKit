import UIKit

protocol ViewFromNibLoadable: AnyObject {

}

extension ViewFromNibLoadable where Self: UIView {
	func loadFromNib(using aDecoder: NSCoder) -> Any? {
		if !subviews.isEmpty {
			return self
		}

		let moduleBundle = Bundle.module
		let selfBundle = Bundle(for: type(of: self))
		let view: UIView
		if let selfView = selfBundle.loadNibNamed(String(describing: type(of: self)), owner: nil, options: nil)?.first as? UIView {
			view = selfView
		} else if let moduleView = moduleBundle.loadNibNamed(String(describing: type(of: self)), owner: nil, options: nil)?.first as? UIView {
			view = moduleView
		} else {
			return nil
		}

		view.translatesAutoresizingMaskIntoConstraints = false
		let contraints = constraints
		removeConstraints(contraints)
		view.addConstraints(contraints)

		return view
	}
}

internal extension UIView {

	@discardableResult
	static func fromNib<T: UIView>(owner: Any? = UIView.self, bundle: Bundle? = .module) -> T? {
		guard let view = bundle?.loadNibNamed(self.className, owner: owner, options: nil)?[0] as? T else {
			return nil
		}

		return view
	}

	@discardableResult
	func fromNib<T: UIView>() -> T? {
		guard let contentView = Bundle.module
			.loadNibNamed(self.className, owner: self, options: nil)?.first as? T else {
			return nil
		}
		addSubview(contentView)
		contentView.fillSuperview()
		return contentView
	}
}

internal extension UIView {
	
	var isAnimating: Bool {
		(layer.animationKeys() ?? []).isEmpty == false || recursiveSubviews.reduce(true, { $0 || ($1.layer.animationKeys() ?? []).isEmpty == false })
	}
	
	var recursiveSubviews: [UIView] {
		return subviews + subviews.flatMap { $0.recursiveSubviews }
	}
}
