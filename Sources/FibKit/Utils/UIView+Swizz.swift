import UIKit

extension UIView: UIContextMenuInteractionDelegate {
	private struct AssociatedKeys {
		static var _dragContext = ".com.SmartStaff._dragContext"
		static var _interactionItems = "com.SmartStaff._interactionItems"
		static var _dragInteraction = "com.SmartStaff._dragInteraction"
		static var _dropInteraction = "com.SmartStaff._dropInteraction"
	}
	
	public var interactionMenu: FibContextMenu? {
		get { return objc_getAssociatedObject(self, &AssociatedKeys._interactionItems) as? FibContextMenu }
		set { objc_setAssociatedObject(self, &AssociatedKeys._interactionItems, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	public var dragContext: DragInteractionContext? {
		get { return objc_getAssociatedObject(self, &AssociatedKeys._dragContext) as? DragInteractionContext }
		set { objc_setAssociatedObject(self, &AssociatedKeys._dragContext, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	public var dragInteraction: UIDragInteraction? {
		get { return objc_getAssociatedObject(self, &AssociatedKeys._dragInteraction) as? UIDragInteraction }
		set { objc_setAssociatedObject(self, &AssociatedKeys._dragInteraction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	public var dropInteraction: UIDropInteraction? {
		get { return objc_getAssociatedObject(self, &AssociatedKeys._dropInteraction) as? UIDropInteraction }
		set { objc_setAssociatedObject(self, &AssociatedKeys._dropInteraction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	public func addContextMenu(_ menu: FibContextMenu?) {
		guard let menu = menu else {
			interactions.forEach({ removeInteraction($0) })
			self.interactionMenu = nil
			return
		}
		self.interactionMenu = menu
		let interaction = UIContextMenuInteraction(delegate: self)
		addInteraction(interaction)
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
		guard let menu = interactionMenu else { return nil }
		return UIContextMenuConfiguration(identifier: nil, previewProvider: menu.previewProvider) { _ in
			return menu.menu
		}
	}
	
	public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		guard let menu = interactionMenu else { return }
		animator.addAnimations {
			menu.previewAction?()
		}
	}
}

extension UIView: UIDragInteractionDelegate {
	
	public  func addDrag(itemsProvider: @escaping (() -> [UIDragItem])) {
		let context = DragInteractionContext(itemsProvider: itemsProvider)
		dragContext = context
		if dragInteraction == nil {
			dragInteraction = UIDragInteraction(delegate: self)
			addInteraction(dragInteraction!)
		}
		dragInteraction?.isEnabled = true
	}
	
	public  func removeDrag() {
		dragInteraction?.isEnabled = false
	}
	
	public  func addDrop(delegate: UIDropInteractionDelegate) {
		let drop = UIDropInteraction(delegate: delegate)
		self.dropInteraction = drop
		addInteraction(drop)
	}
	
	public  func removeDrop() {
		if let drop = self.dropInteraction {
			removeInteraction(drop)
		}
	}
	
	public func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
		guard let items = dragContext?.itemsProvider() else { return [] }
		return items
	}
}

public struct DragInteractionContext {
	public init(itemsProvider: @escaping (() -> [UIDragItem])) {
		self.itemsProvider = itemsProvider
	}
	
	public var itemsProvider: (() -> [UIDragItem])
}

public struct FibContextMenu {
	public init(menu: UIMenu, previewProvider: (() -> UIViewController?)? = nil, previewAction: (() -> Void)? = nil) {
		self.menu = menu
		self.previewProvider = previewProvider
		self.previewAction = previewAction
	}
	
	
	public var menu: UIMenu
	public var previewProvider: (() -> UIViewController?)?
	public var previewAction: (() -> Void)?
}

extension UIBarButtonItem {
	
	public  static func swizzleBackButtonMenu() {
		if #available(iOS 14.0, *) {
			exchange(
				#selector(setter: UIBarButtonItem.menu),
				with: #selector(setter: UIBarButtonItem.swizzledMenu),
				in: UIBarButtonItem.self
			)
		}
	}
	
	private static func exchange(
		_ selector1: Selector,
		with selector2: Selector,
		in cls: AnyClass
	) {
		guard
			let method = class_getInstanceMethod(
				cls,
				selector1
			),
			let swizzled = class_getInstanceMethod(
				cls,
				selector2
			)
		else {
			return
		}
		method_exchangeImplementations(method, swizzled)
	}
}

@available(iOS 14.0, *)
private extension UIBarButtonItem {
	@objc dynamic var swizzledMenu: UIMenu? {
		get {
			nil
		}
		set {
			
		}
	}
}
