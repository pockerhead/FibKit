import UIKit
import VisualEffectView

extension UIView {
	
	var statusBarFrame: CGRect? {
		window?.windowScene?.statusBarManager?.statusBarFrame
	}
}

extension UINavigationController {
	@discardableResult
	internal func addBlurEffect(blurRadius: CGFloat = 24) -> UIVisualEffectView {
		let blurEffectView = VisualEffectView()
		// Find size for blur effect.
		let statusBarHeight = view.statusBarFrame?.height ?? 0
		let bounds = navigationBar.bounds.insetBy(dx: 0, dy: -statusBarHeight).offsetBy(dx: 0, dy: -statusBarHeight)
		// Create blur effect.
		blurEffectView.blurRadius = blurRadius
		blurEffectView.frame = bounds
		blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		// Set navigation bar up.
		navigationBar.isTranslucent = true
		navigationBar.setBackgroundImage(UIImage(), for: .default)
		navigationBar.shadowImage = UIImage()
		navigationBar.addSubview(blurEffectView)
		navigationBar.sendSubviewToBack(blurEffectView)
		
		return blurEffectView
	}

	internal func pushViewController(_ viewController: UIViewController,
								   animated: Bool,
								   completion: (() -> Void)?) {
		pushViewController(viewController, animated: animated)

		guard animated, let coordinator = transitionCoordinator else {
			completion?()
			return
		}
		coordinator.animate(alongsideTransition: nil) { _ in completion?() }
	}
	
	internal func popViewController(animated: Bool,
								   completion: (() -> Void)?) {
		popViewController(animated: animated)

		guard animated, let coordinator = transitionCoordinator else {
			completion?()
			return
		}
		coordinator.animate(alongsideTransition: nil) { _ in completion?() }
	}

	internal func setViewControllers(_ viewControllers: [UIViewController],
								   animated: Bool,
								   completion: (() -> Void)?) {
		setViewControllers(viewControllers, animated: animated)

		guard animated, let coordinator = transitionCoordinator else {
			completion?()
			return
		}
		coordinator.animate(alongsideTransition: nil) { _ in completion?() }
	}

	@available(iOS 13.0, *)
	internal func applyStandart() {
		navigationBar.standardAppearance.configureWithDefaultBackground()
	}

	@available(iOS 13.0, *)
	internal func killAppearance() {
		navigationBar.standardAppearance.configureWithTransparentBackground()
	}

	internal func clear() {
		navigationBar.setBackgroundImage(UIImage(), for: .default)
		navigationBar.shadowImage = UIImage()
		navigationBar.isTranslucent = true
		toolbar.setBackgroundImage(UIImage().withRenderingMode(.alwaysTemplate), forToolbarPosition: .any, barMetrics: .default)
		toolbar.backgroundColor = .clear
		navigationBar.backgroundColor = .clear
	}
	
	internal func setDefault() {
		navigationBar.setBackgroundImage(nil, for: .default)
		navigationBar.shadowImage = nil
		navigationBar.isTranslucent = true
		toolbar.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
		toolbar.backgroundColor = nil
		navigationBar.backgroundColor = nil
	}
}

/// Passes through all touch events to views behind it, except when the
/// touch occurs in a contained UIControl or view with a gesture
/// recognizer attached
internal final class PassThroughNavigationBar: UINavigationBar {

	override internal func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard nestedInteractiveViews(in: self, contain: point) else { return false }
		return super.point(inside: point, with: event)
	}

	private func nestedInteractiveViews(in view: UIView, contain point: CGPoint) -> Bool {

		if view.isPotentiallyInteractive, view.bounds.contains(convert(point, to: view)) {
			return true
		}

		for subview in view.subviews {
			if nestedInteractiveViews(in: subview, contain: point) {
				return true
			}
		}

		return false
	}
}

internal extension UIView {
	var isPotentiallyInteractive: Bool {
		guard isUserInteractionEnabled else { return false }
		return (isControl || doesContainGestureRecognizer)
	}

	var isControl: Bool {
		self is UIControl
	}

	var doesContainGestureRecognizer: Bool {
		!(gestureRecognizers?.isEmpty ?? true)
	}
}
