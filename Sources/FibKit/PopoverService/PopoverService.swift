//
//  PopoverService.swift
//  SmartStaff
//
//  Created by artem on 03.05.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
import UIKit
import VisualEffectView
import Combine

/// Shared instance let for simple calling methods
public let PopoverService = PopoverServiceInstance.shared

public typealias ContextMenu = FibCell.ViewModel

public class AllSimultaneouslyTapGestDelegate: NSObject, UIGestureRecognizerDelegate {
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		true
	}
}

public protocol PreventTouchGRProtocol {}
public class PreventTouchGR: UITapGestureRecognizer, PreventTouchGRProtocol {}

/// Class for showing conextMenu with formview inside it
public final class PopoverServiceInstance: NSObject, UITraitEnvironment {
	public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		// todo
	}
	
	public struct Appearance {
		public init(blurColorTint: UIColor? = nil) {
			self.blurColorTint = blurColorTint
		}
		
		public var blurColorTint: UIColor?
	}
	
	public var menuVisibilityHandler: ((Bool) -> Void)? = nil
	
	public static var defaultAppearance = Appearance(
		blurColorTint: .systemBackground
	)
	
	var blurColorTint: UIColor? {
		PopoverServiceInstance.defaultAppearance.blurColorTint
	}
	
	var isMenuOpen: Bool = false {
		didSet {
			menuVisibilityHandler?(isMenuOpen)
		}
	}
	
	public var traitCollection: UITraitCollection {
		.init()
	}
	
	static let shared: PopoverServiceInstance = {
		let service = PopoverServiceInstance()
		return service
	}()
	
	private override init() {
		super.init()
		NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
	}
	
	lazy var dragGest = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
	let allTapDelegateHelper = AllSimultaneouslyTapGestDelegate()
	
	var proxyWindow: UIWindow {
		if let scene = currentScene {
			return DragProxyWindow(windowScene: scene)
		} else {
			return DragProxyWindow(frame: UIScreen.main.bounds)
		}
	}
	/// Own window for alertService
	public private(set) lazy var window: UIWindow = {
		let w = proxyWindow
		(w as? DragProxyWindow)?.popoverService = self
		dragGest.delegate = self
//		w.addGestureRecognizer(dragGest)
		let gr = UITapGestureRecognizer(target: self, 
										action: #selector(hideContextMenuAfterAction))
		w.addGestureRecognizer(gr)
		gr.delegate = allTapDelegateHelper
		w.rootViewController = RootTransparentStyleViewController()
		return w
	}()
	
	var scrollView = UIScrollView()
	public var passViewEvent: UIEvent?
	public var completion: (() -> Void)?

	/// Blur view that applies with conext menu
	lazy var overlayView: VisualEffectView = {
		let view = VisualEffectView()
		view.colorTint = blurColorTint
		view.colorTintAlpha = 0.2
		view.blurRadius = 16
		let gr = UITapGestureRecognizer(target: self,
										action: #selector(hideContextMenuAfterAction))
		view.addGestureRecognizer(gr)
		return view
	}()

	/// Conext menu, contains self-sized formView with scroll
	var contextMenu = FibCell()

	private var currentAppWindow: UIWindow?? {
		if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? UIWindowSceneDelegate {
			return delegate.window
		}
		else {
			return UIApplication.shared.delegate?.window
		}
	}
	
	private var currentScene: UIWindowScene? {
		UIApplication.shared.connectedScenes.first as? UIWindowScene
	}

	/// Snapshot of view, that captured by context
	var contextViewSnapshot: UIView?

	/// Weak reference to view, captured by context
	private weak var contextView: UIView?
	private weak var fromGesture: UIGestureRecognizer?

	/// Feedback generator
	private var feedBack = UISelectionFeedbackGenerator()
	private var allHeight: CGFloat = 0
	private var contextViewRectInWindow = CGRect()
	private var viewToMenuSpacing: CGFloat = 16
	private var hidingInProcess = false
	private var menuWidth: CGFloat?
	private var needBlurBackground = true
	public private(set) var needHideAfterAction = true
	private var onHideAction: (() -> Void)? = nil
	private var leftXOffset: CGFloat = 0
	private var rightXOffset: CGFloat = 0
	private var menuAlignment: HorizontalMenuAlignment = .common
	private var shadowDescriptor: ShadowDescriptor? = nil
	private var snapshotCancellable: AnyCancellable?
	private var context: Context = .init()

	public enum HorizontalMenuAlignment {
		case left
		case right
		case common
	}
	
	public enum VerticalMenuAlignment {
		case bottom
		case common
	}
	
	public enum DismissalInteraction {
		case onlyTap
		case anyTouch
	}

	public struct Context {
		
		var view: UIView?
		var needBlurBackground: Bool = true
		var gesture: UIGestureRecognizer?
		var viewToMenuSpacing: CGFloat = 16
		var menuWidth: CGFloat? = nil
		var needHideAfterAction: Bool = true
		var leftXOffset: CGFloat = 0
		var needHideSnapshot: Bool = false
		var rightXOffset: CGFloat = 0
		var onHideAction: (() -> Void)? = nil
		var horizontalMenuAlignment: HorizontalMenuAlignment = .common
		var verticalMenuAlignment: VerticalMenuAlignment = .bottom
		var dismissalInteraction: DismissalInteraction = .onlyTap
		var shadowDescriptor: ShadowDescriptor? = nil

		public init(
			view: UIView? = nil,
			needHideSnapshot: Bool = false,
			needBlurBackground: Bool = true,
			gesture: UIGestureRecognizer? = nil,
			viewToMenuSpacing: CGFloat = 16,
			menuWidth: CGFloat? = nil,
			needHideAfterAction: Bool = true,
			leftXOffset: CGFloat = 0,
			rightXOffset: CGFloat = 0,
			onHideAction: (() -> Void)? = nil,
			menuAlignment: HorizontalMenuAlignment = .common,
			verticalMenuAlignment: VerticalMenuAlignment = .bottom,
			dismissalInteraction: DismissalInteraction = .onlyTap,
			shadowDescriptor: ShadowDescriptor? = nil
		) {
			self.view = view
			self.needHideSnapshot = needHideSnapshot
			self.needBlurBackground = needBlurBackground
			self.gesture = gesture
			self.viewToMenuSpacing = viewToMenuSpacing
			self.menuWidth = menuWidth
			self.needHideAfterAction = needHideAfterAction
			self.leftXOffset = leftXOffset
			self.rightXOffset = rightXOffset
			self.onHideAction = onHideAction
			self.horizontalMenuAlignment = menuAlignment
			self.verticalMenuAlignment = verticalMenuAlignment
			self.dismissalInteraction = dismissalInteraction
			self.shadowDescriptor = shadowDescriptor
		}
	}
	
	public func showContextMenuWith(
		_ context: Context = Context(),
		_ menu: ContextMenu,
		isSecure: Bool = false
	) {
		self.context = context
		showContextMenu(menu,
						view: context.view,
						needHideSnapshot: context.needHideSnapshot,
						needBlurBackground: context.needBlurBackground,
						gesture: context.gesture,
						viewToMenuSpacing: context.viewToMenuSpacing,
						menuWidth: context.menuWidth,
						needHideAfterAction: context.needHideAfterAction,
						leftXOffset: context.leftXOffset,
						rightXOffset: context.rightXOffset,
						menuAlignment: context.horizontalMenuAlignment,
						verticalMenuAlignment: context.verticalMenuAlignment,
						shadowDescriptor: context.shadowDescriptor,
						onHideAction: context.onHideAction,
						isSecure: isSecure,
						menuVisibilityHandler: menuVisibilityHandler
		)
	}

	/// Shows conext menu for choosed view
	/// - Parameters:
	///   - menu: see FibCell.ViewModel
	///   - view: captured view
	///   - controller: viewController that contains captured view
	@available(*, deprecated, renamed: "showContextMenuWith", message: "Use function with context")
	public func showContextMenu(_ menu: ContextMenu,
								view: UIView?,
								needHideSnapshot: Bool = false,
								needBlurBackground: Bool = true,
								gesture: UIGestureRecognizer?,
								viewToMenuSpacing: CGFloat = 16,
								menuWidth: CGFloat? = nil,
								needHideAfterAction: Bool = true,
								leftXOffset: CGFloat = 0,
								rightXOffset: CGFloat = 0,
								menuAlignment: HorizontalMenuAlignment = .common,
								verticalMenuAlignment: VerticalMenuAlignment = .bottom,
								shadowDescriptor: ShadowDescriptor? = nil,
								onHideAction: (() -> Void)? = nil,
								isSecure: Bool = false,
								menuVisibilityHandler: ((Bool) -> Void)? = nil) {
		self.menuVisibilityHandler = menuVisibilityHandler
		isMenuOpen = true
		guard !hidingInProcess else { return }
		setLayerDisableScreenshots(window.layer, isSecure)
		self.leftXOffset = leftXOffset
		self.rightXOffset = rightXOffset
		self.menuAlignment = menuAlignment
		self.shadowDescriptor = shadowDescriptor
		var newRect = view?.frame ?? .zero
		newRect.origin.x -= leftXOffset
		newRect.size.width += self.leftXOffset + self.rightXOffset
		guard var viewRect = view?.superview?.convert(newRect, to: nil) else { return }
		let oldRect = viewRect
		self.menuWidth = menuWidth
		self.needBlurBackground = needBlurBackground
		contextView = view
		contextViewRectInWindow = viewRect
		self.viewToMenuSpacing = viewToMenuSpacing
		contextMenu.contentView.layer.masksToBounds = true
		currentAppWindow??.endEditing(true)
		self.onHideAction = onHideAction
		self.needHideAfterAction = needHideAfterAction
		if context.dismissalInteraction == .anyTouch {
			(window as? DragProxyWindow)?.isPassthroughTouches = true
		} else {
			(window as? DragProxyWindow)?.isPassthroughTouches = false
		}
		self.contextMenu.collectionAnimator = AnimatedReloadAnimator(animationContext: .disabledAnimation)
		self.contextMenu.configure(with: menu.animated(false))
		delay(0.3) {[weak self] in
			self?.contextMenu.collectionAnimator = nil
		}
		self.contextMenu.formView.scrollTo(edge: .top, animated: false)
		// @ab: TODO - исправить баги
//        if let gesture = gesture {
//            self.fromGesture = gesture
//            gesture.addTarget(self, action: #selector(drag(_:)))
//            window.addGestureRecognizer(gesture)
//            gesture.delegate = self
//        }
		delay {[weak self] in
			guard let self = self else { return }
			let safeAreaHorizontal = window.safeAreaInsets.left + window.safeAreaInsets.right
			let safeAreaVertical = window.safeAreaInsets.top + window.safeAreaInsets.bottom
			var width: CGFloat = 0
			if let strategyWidth = menuWidth {
				width = strategyWidth
			} else {
				width = (window.bounds.width - 128 - safeAreaHorizontal).clamp(0, 254)
			}
			let height: CGFloat
			let isMenuTopAligned: Bool
			switch verticalMenuAlignment {
			case .bottom:
				height = window.bounds.height - 64 - safeAreaVertical
				isMenuTopAligned = false
			case .common:
				let bottomMenuHeight = window.bounds.height - window.safeAreaInsets.bottom - viewRect.maxY - viewToMenuSpacing - 64
				let topMenuHeight = window.bounds.height - (window.bounds.height - viewRect.minY) - window.safeAreaInsets.top - viewToMenuSpacing - 64
				height = max(topMenuHeight, bottomMenuHeight)
				isMenuTopAligned = topMenuHeight > bottomMenuHeight
			}
			let size = CGSize(width: width,
							  height: height)
			let formViewSize = self.contextMenu.sizeWith(size, data: menu)
			let formViewHeight = formViewSize?.height.clamp(0, size.height) ?? size.height
			var contextMenuY: CGFloat = viewRect.maxY + viewToMenuSpacing
			contextMenuY = max(contextMenuY, window.safeAreaInsets.top + 32)

			configureOverlayView(needBlur: needBlurBackground)
			prepareScrollView()
			let snapshotFuture: Future<CGRect?, Never>
			if self.leftXOffset != 0 || self.rightXOffset != 0 {
				snapshotFuture = configureOutOfBoundsSnapshot(with: view, viewRect: viewRect, leftXSpacing: self.leftXOffset, rightXSpacing: self.rightXOffset)
			} else {
				snapshotFuture = configureSnapshot(with: view, viewRect: viewRect, oldRect: oldRect)
			}
			snapshotCancellable = snapshotFuture.sink {[weak self] rect in
				guard let self = self else { return }
				if needHideSnapshot {
					self.contextViewSnapshot?.alpha = 0
				}
				if let rect {
					viewRect = rect
					contextViewRectInWindow = rect
				}
				configureContextMenu(with: size, viewRect: viewRect, formViewHeight: formViewHeight, shadowDescritor: self.shadowDescriptor)
				prepareWindow()
				
				let allHeight = viewRect.height + viewToMenuSpacing + formViewHeight + window.safeAreaInsets.verticalSum
				self.allHeight = allHeight
				feedBack.selectionChanged()
				withFibSpringAnimation(duration: 0.4) {[weak self] in
					self?.applyContextViewRect(
						contextMenuY: contextMenuY,
						formViewHeight: formViewHeight,
						isMenuTopAligned: isMenuTopAligned,
						viewRect: viewRect,
						size: size,
						needBlurBackground: needBlurBackground,
						allHeight: allHeight,
						viewToMenuSpacing: viewToMenuSpacing
					)
				} completion: {[weak self] _ in
					guard let self = self else { return }
				}
				snapshotCancellable = nil
			}
		}
	}
	
	public func update(menu: ContextMenu, 
					   menuWidth: CGFloat? = nil) {
		guard let viewRect = calculateViewRect(for: contextView) else { return }
		var width: CGFloat = 0
		let safeAreaHorizontal = window.safeAreaInsets.left + window.safeAreaInsets.right
		let safeAreaVertical = window.safeAreaInsets.top + window.safeAreaInsets.bottom
		self.menuWidth = menuWidth
		if let strategyWidth = self.menuWidth {
			width = strategyWidth
		} else {
			width = (window.bounds.width - 128 - safeAreaHorizontal).clamp(0, 254)
		}
		let height: CGFloat
		let isMenuTopAligned: Bool
		switch context.verticalMenuAlignment {
		case .bottom:
			height = window.bounds.height - 64 - safeAreaVertical
			isMenuTopAligned = false
		case .common:
			let bottomMenuHeight = window.bounds.height - window.safeAreaInsets.bottom - viewRect.maxY - viewToMenuSpacing - 64
			let topMenuHeight = window.bounds.height - (window.bounds.height - viewRect.minY) - window.safeAreaInsets.top - viewToMenuSpacing - 64
			height = max(topMenuHeight, bottomMenuHeight)
			isMenuTopAligned = topMenuHeight > bottomMenuHeight
		}
		let size = CGSize(width: width,
						  height: height)
		let formViewSize = self.contextMenu.sizeWith(size, data: menu)
		let formViewHeight = formViewSize?.height.clamp(0, size.height) ?? size.height
		var contextMenuY: CGFloat = viewRect.maxY + viewToMenuSpacing
		contextMenuY = max(contextMenuY, window.safeAreaInsets.top + 32)
		let oldOrigin = contextMenu.frame.origin
		configureContextMenu(with: size, viewRect: viewRect, formViewHeight: formViewHeight, shadowDescritor: shadowDescriptor)
		contextMenu.transform = .identity
		contextMenu.alpha = 1
		self.contextMenu.configure(with: menu)
		self.contextMenu.formView.scrollTo(edge: .top, animated: false)
		contextMenu.frame.origin = oldOrigin
		let allHeight = viewRect.height + viewToMenuSpacing + formViewHeight + window.safeAreaInsets.verticalSum
		self.allHeight = allHeight
		feedBack.selectionChanged()
		withFibSpringAnimation(duration: 0.4) {[weak self] in
			self?.applyContextViewRect(
				contextMenuY: contextMenuY,
				formViewHeight: formViewHeight,
				isMenuTopAligned: isMenuTopAligned,
				viewRect: viewRect,
				size: size,
				needBlurBackground: self?.needBlurBackground ?? true,
				allHeight: allHeight,
				viewToMenuSpacing: self?.viewToMenuSpacing ?? 16,
				isUpdating: true
			)
		} completion: {[weak self] _ in
			guard let self = self else { return }
			
		}
	}
	
	private func calculateViewRect(for view: UIView?) -> CGRect? {
		guard var viewRect = contextView?.superview?
			.convert(contextView?.frame ?? .zero, to: nil) else { return nil }
		if viewRect.minY < window.safeAreaInsets.top {
			viewRect.origin.y = window.safeAreaInsets.top
		} else if viewRect.maxY > window.frame.height - window.safeAreaInsets.bottom {
			viewRect.origin.y = window.frame.height - window.safeAreaInsets.bottom - viewRect.height
		}
		return viewRect
	}

	private func prepareWindow() {
		self.window.layoutIfNeeded()
		window.isHidden = false
		window.windowLevel = .alert
	}
	
	private func prepareScrollView() {
		if scrollView.superview == nil {
			window.addSubview(scrollView)
		}
		scrollView.showsVerticalScrollIndicator = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.frame = window.bounds
		scrollView.contentInset.top = -window.safeAreaInsets.top
		scrollView.contentInset.bottom = 0
		scrollView.contentInsetAdjustmentBehavior = .always
	}

	private func configureOverlayView(needBlur: Bool) {
		if overlayView.superview == nil {
			window.addSubview(overlayView)
		}
		self.overlayView.fillSuperview()
		if !needBlur {
			overlayView.blurRadius = 0
			overlayView.colorTint = .clear
			overlayView.colorTintAlpha = 0
		} else {
			overlayView.colorTint = blurColorTint
			overlayView.colorTintAlpha = 0.2
			overlayView.blurRadius = 16
		}
		self.overlayView.alpha = 0
	}

	private func configureSnapshot(with view: UIView?, viewRect: CGRect, oldRect: CGRect) -> Future<CGRect?, Never> {
		Future<CGRect?, Never> { promise in
			view?.applyIdentityRecursive()
			delay(cyclesCount: 3) {[weak self] in
				guard let self = self else { return }
				let newRect = view?.frame ?? .zero
				guard let latestRect = view?.superview?.convert(newRect, to: nil) else {
					promise(.success(nil))
					return
				}
				contextViewSnapshot = view?.asImage()
				if context.needHideSnapshot == false {
					contextView?.alpha = 0
				}
				contextViewSnapshot?.addGestureRecognizer(PreventTouchGR(target: self, action: nil))
				scrollView.addSubview(contextViewSnapshot!)
				contextViewSnapshot!.frame = viewRect
				if let shadowDescriptor = self.shadowDescriptor {
					contextViewSnapshot?.layer.applyShadow(with: shadowDescriptor)
				} else {
					contextViewSnapshot?.layer.applySketchShadow()
				}
				promise(.success(latestRect))
			}
		}
	}

	private func configureOutOfBoundsSnapshot(with view: UIView?,
											  viewRect: CGRect,
											  leftXSpacing: CGFloat,
											  rightXSpacing: CGFloat) -> Future<CGRect?, Never> {
		Future<CGRect?, Never> { promise in
			view?.applyIdentityRecursive()
			delay(cyclesCount: 3) {[weak self] in
				guard let self = self else { return }
				var newRect: CGRect = view?.frame.inset(by: .init(top: 0, left: -leftXSpacing, bottom: 0, right: -rightXSpacing)) ?? .zero
				contextViewSnapshot = view?.asImage(capInsets: .init(top: 0, left: -leftXSpacing, bottom: 0, right: -rightXSpacing))
				if !context.needHideSnapshot {
					contextView?.alpha = 0
				}
				var rect = view?.frame ?? .zero
				rect.origin.x -= leftXOffset
				rect.size.width += self.leftXOffset + self.rightXOffset
				guard let latestRect = view?.superview?.convert(rect, to: nil) else {
					promise(.success(nil))
					return
				}
				contextViewSnapshot?.addGestureRecognizer(PreventTouchGR(target: self, action: nil))
				scrollView.addSubview(contextViewSnapshot!)
				newRect.origin.x = viewRect.origin.x
				newRect.origin.y = viewRect.origin.y
				contextViewSnapshot!.frame = newRect
				if let shadowDescriptor = self.shadowDescriptor {
					contextViewSnapshot?.layer.applyShadow(with: shadowDescriptor)
				} else {
					contextViewSnapshot?.layer.applySketchShadow()
				}
				promise(.success(latestRect))
			}
		}
		
	}

	var canc: AnyCancellable?

	private func configureContextMenu(with size: CGSize, 
									  viewRect: CGRect,
									  formViewHeight: CGFloat,
									  shadowDescritor: ShadowDescriptor?) {
		if contextMenu.superview == nil {
			scrollView.addSubview(contextMenu)
		}
		self.contextMenu.frame.size = .init(width: size.width, height: formViewHeight)
		self.contextMenu.backgroundColor = .clear
		self.contextMenu.formView.showsVerticalScrollIndicator = false
		self.contextMenu.formView.isScrollEnabled = true
		self.contextMenu.transform = .init(scaleX: 0.01, y: 0.01)
		self.contextMenu.frame.origin = viewRect.center
		self.contextMenu.alpha = 0.01

		if let shadowDescritor = shadowDescritor {
			self.contextMenu.layer.applyShadow(with: shadowDescritor)
		}
	}

	private func applyContextViewRect(contextMenuY: CGFloat,
									  formViewHeight: CGFloat,
									  isMenuTopAligned: Bool,
									  viewRect: CGRect,
									  size: CGSize,
									  needBlurBackground: Bool,
									  allHeight: CGFloat,
									  viewToMenuSpacing: CGFloat,
									  isUpdating: Bool = false) {
		self.window.layoutIfNeeded()
		let minimumX: CGFloat = 16
		let maximumX = window.bounds.width - 16 - size.width
		var contextMenuX: CGFloat
		switch menuAlignment {
		case .left:
			contextMenuX = viewRect.minX.clamp(minimumX, viewRect.minX)
		case .right:
			contextMenuX = viewRect.maxX - size.width
			if contextMenuX > maximumX {
				contextMenuX = maximumX
			}
		case .common:
			contextMenuX = viewRect.minX.clamp(minimumX, maximumX)
		}

		self.contextMenu.transform = .identity
		self.contextMenu.alpha = 1
		
		// TODO: @ab есть баги
		//        if needBlurBackground, let currentAppWindow = currentAppWindow {
		//            currentAppWindow?.transform = .init(scaleX: 0.98, y: 0.98)
		//        }
		self.overlayView.alpha = needBlurBackground ? 1 : 0
		guard let contextSnapshot = self.contextViewSnapshot else { return }
		scrollView.contentSize = .init(width: window.bounds.width, height: allHeight)
		var insetTop: CGFloat = 0
		let contextMinX = viewRect.minX - self.leftXOffset
		let contextSnapshotX = contextMinX.clamp(8, window.bounds.width - 8 - (contextView?.frame.width ?? viewRect.width))
		var contextSnapshotSize: CGSize = .init()
		if let contextView = contextView {
			contextSnapshotSize.width = contextView.frame.size.width + leftXOffset + rightXOffset
			contextSnapshotSize.height = contextView.frame.size.height
		} else {
			contextSnapshotSize = viewRect.size
		}
		contextSnapshot.frame = .init(origin: .init(x: contextSnapshotX, y: 0),
									  size: contextSnapshotSize)
		if isMenuTopAligned {
			insetTop = viewRect.minY - formViewHeight - viewToMenuSpacing
		} else if !(viewRect.origin.y + allHeight > scrollView.frame.height) {
			insetTop = max(0, viewRect.minY)
			if viewRect.minY < window.safeAreaInsets.top {
				insetTop = window.safeAreaInsets.top
			}
		} else {
			if allHeight < (scrollView.frame.height - window.safeAreaInsets.bottom) {
				insetTop = scrollView.frame.height - allHeight - 32
			}
		}
		if isUpdating == false {
			UIView.performWithoutAnimation {
				self.contextMenu.frame.origin.y = insetTop + viewRect.height / 2
			}
		}
		scrollView.contentInset.top = insetTop - window.safeAreaInsets.top
		
		if rightXOffset != 0 && contextMenuX != contextSnapshotX {
			contextMenuX += (contextSnapshotX + contextSnapshotSize.width - rightXOffset) - (contextMenuX + size.width)
		}

		if leftXOffset != 0 && contextMenuX == 16 {
			contextMenuX -= contextMenuX - contextSnapshotX - leftXOffset
		}

		delay {[weak self] in
			guard let self = self else { return }
			var finalMenuY = contextSnapshot.frame.maxY + viewToMenuSpacing
			switch context.verticalMenuAlignment {
			case .bottom:
				break
			case .common:
				if isMenuTopAligned {
					finalMenuY = 0
				} else {
					break
				}
			}
			let finalMenuFrame = CGRect(x: contextMenuX,
										y: finalMenuY,
										width: size.width,
										height: formViewHeight)
			withFibSpringAnimation(duration: 0.4) {[weak self] in
				guard let self = self else { return }
				self.contextMenu.frame = finalMenuFrame
				let allHeight = formViewHeight + viewToMenuSpacing + contextSnapshot.frame.height + window.safeAreaInsets.top
				self.allHeight = allHeight
				scrollView.contentSize.height = allHeight
				if allHeight > scrollView.frame.height {
					scrollView.contentInset.top += 32 + window.safeAreaInsets.top
					scrollView.contentInset.bottom += 32
				}
				
				delay {[weak self] in
					guard let self = self else { return }
					scrollView.setContentOffset(.init(x: 0, y: scrollView.offsetFrame.maxY), animated: true)
				}
			}
		}
		
	}
	
	@objc private func willResignActive() {
		guard contextView?.superview != nil else { return }
		delay { [weak self] in
			self?.hideContextMenu()
		}
	}
	
	@objc private func hideContextMenuAfterAction(gesture: UITapGestureRecognizer) {
		let location = gesture.location(in: nil)
		let clickedView = window.hitTest(location, with: nil)
		if clickedView === window || 
			clickedView === overlayView ||
			clickedView === scrollView ||
			clickedView === contextViewSnapshot ||
			clickedView == nil {
			hideContextMenu(nil)
		}
	}

	public func hideContextMenu(executeOnHide: Bool = true, _ completion: (() -> Void)? = nil) {
		guard self.hidingInProcess == false else { return }
		self.hidingInProcess = true
		self.contextView?.isHidden = false
		if !context.needHideSnapshot {
			self.contextView?.alpha = 0
		}
		withFibSpringAnimation(duration: 0.2, delay: 0.2) {
			self.contextViewSnapshot?.alpha = 0
		}
		withFibSpringAnimation(duration: 0.1, delay: 0.2) {[weak self] in
			guard let self = self else { return }
			self.contextView?.alpha = 1
		}
		withFibSpringAnimation(duration: 0.3) {[weak self] in
			guard let self = self else { return }
			if let viewRect = self.contextView?.superview?.convert(self.contextView?.frame ?? .zero, to: nil) {
				self.scrollView.contentInset.top = -window.safeAreaInsets.top
				self.contextViewSnapshot?.frame = viewRect
				if rightXOffset != 0 {
					self.contextViewSnapshot?.frame.size.width += rightXOffset
				}
				if leftXOffset != 0 {
					self.contextViewSnapshot?.frame.size.width += leftXOffset
					self.contextViewSnapshot?.frame.origin.x -= leftXOffset
				}
				self.contextViewSnapshot?.frame.origin.y += self.scrollView.contentOffset.y
			}
			withFibSpringAnimation(duration: 0.4) { [weak self] in
				guard let self = self else { return }
				self.contextMenu.transform = .init(scaleX: 0.01, y: 0.01)
				self.contextMenu.center = self.contextViewRectInWindow.center
				self.contextMenu.alpha = 0
				self.overlayView.alpha = 0
			}
		} completion: {[weak self] _ in
			guard let self = self else { return }
			self.contextView = nil
			self.scrollView.contentInset.top = -window.safeAreaInsets.top
			self.scrollView.contentSize = .zero
			self.window.isHidden = true
			self.window.resignKey()
			self.hidingInProcess = false
			DispatchQueue.main.async {[weak self] in
				guard let self = self else { return }
				self.contextMenu.transform = .identity
				self.contextViewSnapshot?.removeFromSuperview()
				if executeOnHide {
					onHideAction?()
				}
				self.isMenuOpen = false
				completion?()
				self.completion?()
				self.completion = nil
			}
		}
	}
	
	@objc func drag(_ sender: UIGestureRecognizer) {
		let point = sender.location(in: sender.view)
		switch sender.state {
		case .changed:
			contextMenu.formView.visibleCells.forEach({ cell in
				guard let cell = cell as? HighlightableView,
					  let cellAbsFrame = cell.superview?.convert(cell.frame, to: window)
				else { return }
				let havePointInside = cellAbsFrame.contains(point)
				if havePointInside, !cell.isHighlighted {
					feedBack.selectionChanged()
					cell.setHighlighted(highlighted: true)
				} else if !havePointInside, cell.isHighlighted {
					cell.setHighlighted(highlighted: false)
				}
			})
		case .began:
			contextMenu.formView.visibleCells.forEach({ cell in
				guard let cell = cell as? HighlightableView else { return }
				cell.setHighlighted(highlighted: cell.point(inside: point, with: nil))
			})
		case .ended,.cancelled, .failed:
			if let fromGesture = fromGesture {
				let view = sender.view
				delay {
					if view?.gestureRecognizers?.contains(where: { $0 === fromGesture }) == false {
						view?.addGestureRecognizer(fromGesture)
					}
				}
				
				fromGesture.delegate = nil
				fromGesture.removeTarget(self, action: #selector(drag(_:)))
				window.removeGestureRecognizer(fromGesture)
			}
			if sender.state == .ended {
				for (cell, index) in zip(contextMenu.formView.visibleCells, contextMenu.formView.visibleIndexes).reversed() {
					if cell.point(inside: sender.location(in: cell), with: nil) {
						if let cell = cell as? SwipeControlledView, cell.isSwipeOpen {
							cell.animateSwipe(direction: .right, isOpen: false, swipeWidth: nil, initialVel: nil, completion: nil)
							return
						}
						contextMenu.formView.flattenedProvider.didTap(view: cell, at: index)
						return
					}
				}
			}
			
			contextMenu.formView.visibleCells.forEach({ cell in
				guard let cell = cell as? HighlightableView else { return }
				cell.setHighlighted(highlighted: false)
			})
			
		default: break
		}
	}
}

final fileprivate class DragProxyWindow: UIWindow {
	
	private var touchesBegan: ((CGPoint) -> Void)?
	private var touchesEnded: ((CGPoint) -> Void)?
	private var touchesMoved: ((CGPoint) -> Void)?
	private var touchesCancelled: ((CGPoint) -> Void)?
	
	var isPassthroughTouches = false
	weak var popoverService: PopoverServiceInstance?
	
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		guard isPassthroughTouches else {
			return super.hitTest(point, with: event)
		}
		let clickedView = super.hitTest(point, with: event)
		if let popoverService,
		   clickedView === popoverService.window ||
			clickedView === popoverService.overlayView ||
			clickedView === popoverService.scrollView ||
			clickedView === popoverService.contextViewSnapshot ||
			clickedView == nil {
			popoverService.hideContextMenu(nil)
			return nil
		} else {
			return clickedView
		}
	}
	
	func bindingTouchesBegan(_ closure: ((CGPoint) -> Void)?) -> Self {
		touchesBegan = closure
		return self
	}
	
	func bindingTouchesEnded(_ closure: ((CGPoint) -> Void)?) -> Self {
		touchesEnded = closure
		return self
	}
	
	func bindingTouchesMoved(_ closure: ((CGPoint) -> Void)?) -> Self {
		touchesMoved = closure
		return self
	}
	
	func bindingTouchesCancelled(_ closure: ((CGPoint) -> Void)?) -> Self {
		touchesCancelled = closure
		return self
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let point = touches.first?.location(in: self) else { return }
		touchesBegan?(point)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let point = touches.first?.location(in: self) else { return }
		touchesEnded?(point)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let point = touches.first?.location(in: self) else { return }
		touchesMoved?(point)
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let point = touches.first?.location(in: self) else { return }
		touchesCancelled?(point)
	}
}

extension PopoverServiceInstance: UIGestureRecognizerDelegate {
	
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		true
	}
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		true
	}
}

fileprivate extension UIView {
	
	func asImage(capInsets: UIEdgeInsets = .zero) -> UIImageView? {
		let image = UIGraphicsImageRenderer(bounds: self.layer.bounds.inset(by: capInsets)).image { ctx in
			self.layer.render(in: ctx.cgContext)
		}
		let view = UIImageView(image: image)
		view.frame = self.frame
		return view
	}
}

