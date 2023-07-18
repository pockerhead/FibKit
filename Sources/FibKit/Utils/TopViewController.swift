import UIKit

internal extension UIApplication {
	// MARK: - Find Top View Controller
	
	static func topViewController() -> UIViewController? {
		findTopViewController(UIApplication.shared.delegate?.window??.rootViewController)
	}
	
	static func findTopViewController(_ controller: UIViewController? =
									  UIApplication.shared.delegate?.window??.rootViewController, searchInPresented: Bool = true) -> UIViewController? {
		
		if let navigationController = controller as? UINavigationController {
			return findTopViewController(navigationController.viewControllers.first, searchInPresented: searchInPresented)
		}
		if let tabController = controller as? UITabBarController {
			if let selected = tabController.selectedViewController {
				return findTopViewController(selected, searchInPresented: searchInPresented)
			}
		}
		if searchInPresented, let presented = controller?.presentedViewController {
			return findTopViewController(presented, searchInPresented: searchInPresented)
		}
		return controller
	}
}
