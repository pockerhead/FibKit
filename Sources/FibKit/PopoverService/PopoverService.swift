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
public protocol HighlightableView: ViewModelConfigurable {
	
	var isHighlighted: Bool { get set }
	
	func setHighlighted(highlighted: Bool)
}

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
	
	public static var defaultAppearance = Appearance(
		blurColorTint: .systemBackground
	)
	
	var blurColorTint: UIColor? {
		PopoverServiceInstance.defaultAppearance.blurColorTint
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
	lazy var window: UIWindow = {
		let w = proxyWindow
		dragGest.delegate = self
		w.addGestureRecognizer(dragGest)
		let gr = UITapGestureRecognizer(target: self, action: #selector(hideContextMenu))
		w.addGestureRecognizer(gr)
		gr.delegate = allTapDelegateHelper
		w.rootViewController = RootTransparentStyleViewController()
		return w
	}()
	
	private var scrollView = UIScrollView()
	public var passViewEvent: UIEvent?
	public var completion: (() -> Void)?

	/// Blur view that applies with conext menu
	private lazy var overlayView: VisualEffectView = {
		let view = VisualEffectView()
		view.colorTint = blurColorTint
		view.colorTintAlpha = 0.2
		view.blurRadius = 16
		let gr = UITapGestureRecognizer(target: self, action: #selector(hideContextMenu))
		view.addGestureRecognizer(gr)
		return view
	}()

	/// Conext menu, contains self-sized formView with scroll
	private var contextMenu = FibCell()

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
	private var contextViewSnapshot: UIView?

	/// Weak reference to view, captured by context
	private weak var contextView: UIView?
	private weak var fromGesture: UIGestureRecognizer?

	/// Feedback generator
	private var feedBack = UIImpactFeedbackGenerator(style: .medium)
	private var allHeight: CGFloat = 0
	private var contextViewRectInWindow = CGRect()
	private var viewToMenuSpacing: CGFloat = 16
	private var hidingInProcess = false
	
	/// Shows conext menu for choosed view
	/// - Parameters:
	///   - menu: see FibCell.ViewModel
	///   - view: captured view
	///   - controller: viewController that contains captured view
	public func showContextMenu(_ menu: ContextMenu,
								view: UIView?,
								needBlurBackground: Bool = true,
								gesture: UIGestureRecognizer?,
								viewToMenuSpacing: CGFloat = 16,
								menuWidth: CGFloat? = nil) {
		guard var viewRect = view?.superview?.convert(view?.frame ?? .zero, to: nil) else { return }
		let oldRect = viewRect
		if viewRect.minY < window.safeAreaInsets.top {
			viewRect.origin.y = window.safeAreaInsets.top
		} else if viewRect.maxY > window.frame.height - window.safeAreaInsets.bottom {
			viewRect.origin.y = window.frame.height - window.safeAreaInsets.bottom - viewRect.height
		}
		contextView = view
		contextViewRectInWindow = viewRect
		self.viewToMenuSpacing = viewToMenuSpacing
		contextMenu.contentView.layer.masksToBounds = true
		currentAppWindow??.endEditing(true)
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
			let size = CGSize(width: width,
							  height: window.bounds.height - 64 - safeAreaVertical)
			let formViewSize = self.contextMenu.sizeWith(size, data: menu)
			let formViewHeight = formViewSize?.height.clamp(0, size.height) ?? size.height
			var contextMenuY: CGFloat = viewRect.maxY + viewToMenuSpacing
			contextMenuY = max(contextMenuY, window.safeAreaInsets.top + 32)

			configureOverlayView(needBlur: needBlurBackground)
			prepareScrollView()
			configureSnapshot(with: view, viewRect: viewRect, oldRect: oldRect)
			configureContextMenu(with: size, viewRect: viewRect, formViewHeight: formViewHeight)
			prepareWindow()
			
			let allHeight = viewRect.height + viewToMenuSpacing + formViewHeight + window.safeAreaInsets.verticalSum
			self.allHeight = allHeight
			feedBack.impactOccurred()
			withFibSpringAnimation(duration: 0.4) {[weak self] in
				self?.applyContextViewRect(
					contextMenuY: contextMenuY,
					formViewHeight: formViewHeight,
					viewRect: viewRect,
					size: size,
					needBlurBackground: needBlurBackground,
					allHeight: allHeight,
					viewToMenuSpacing: viewToMenuSpacing
				)
			} completion: {[weak self] _ in
				guard let self = self else { return }
				self.contextMenu.configure(with: menu)
				self.contextMenu.formView.scrollTo(edge: .top, animated: false)
			}
		}
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

	private func configureSnapshot(with view: UIView?, viewRect: CGRect, oldRect: CGRect) {
		contextViewSnapshot = view?.snapshotView(afterScreenUpdates: true)
		contextView?.alpha = 0
		view?.applyIdentityRecursive()
		contextViewSnapshot?.addGestureRecognizer(PreventTouchGR(target: self, action: nil))
		scrollView.addSubview(contextViewSnapshot!)
		contextViewSnapshot!.frame = oldRect
		contextViewSnapshot?.layer.applySketchShadow()
	}
	
	var canc: AnyCancellable?

	private func configureContextMenu(with size: CGSize, viewRect: CGRect, formViewHeight: CGFloat) {
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
	}

	private func applyContextViewRect(contextMenuY: CGFloat,
									  formViewHeight: CGFloat,
									  viewRect: CGRect,
									  size: CGSize,
									  needBlurBackground: Bool,
									  allHeight: CGFloat,
									  viewToMenuSpacing: CGFloat) {
		self.window.layoutIfNeeded()
		let minimumX: CGFloat = 16
		let maximumX = window.bounds.width - 16 - size.width
		let contextMenuX = viewRect.minX.clamp(minimumX, maximumX)
		
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
		let contextSnapshotX = viewRect.minX.clamp(8, window.bounds.width - 8 - viewRect.width)
		contextSnapshot.frame = .init(origin: .init(x: contextSnapshotX, y: 0),
									  size: viewRect.size)
		if !(viewRect.origin.y + allHeight > scrollView.frame.height) {
			insetTop = max(0, viewRect.minY)
		} else {
			if allHeight < (scrollView.frame.height - window.safeAreaInsets.bottom) {
				insetTop = scrollView.frame.height - allHeight - 32
			}
		}
		UIView.performWithoutAnimation {
			self.contextMenu.frame.origin.y = insetTop + viewRect.height / 2
		}
		scrollView.contentInset.top = insetTop - window.safeAreaInsets.top
		
		delay {
			let finalMenuFrame = CGRect(x: contextMenuX,
										y: contextSnapshot.frame.maxY + viewToMenuSpacing,
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
	
	@objc public func hideContextMenu() {
		hideContextMenu(nil)
	}

	private func hideContextMenu(_ completion: (() -> Void)? = nil) {
		guard self.hidingInProcess == false else { return }
		self.hidingInProcess = true
		feedBack.impactOccurred()
		self.contextView?.isHidden = false
		self.contextView?.alpha = 0
		delay(0.2) {
			withFibSpringAnimation(duration: 0.2) {
				self.contextViewSnapshot?.alpha = 0
			}
		}
		withFibSpringAnimation(duration: 0.1) {[weak self] in
			guard let self = self else { return }
			// TODO: @ab есть баги
			//            if let currentAppWindow = self.currentAppWindow {
			//                currentAppWindow?.transform = .identity
			//            }
		} completion: {[weak self] _ in
			withFibSpringAnimation(duration: 0.1) {[weak self] in
				guard let self = self else { return }
				self.contextView?.alpha = 1
			}
			withFibSpringAnimation(duration: 0.3) {[weak self] in
				guard let self = self else { return }
				if let viewRect = self.contextView?.superview?.convert(self.contextView?.frame ?? .zero, to: nil) {
					self.scrollView.contentInset.top = -window.safeAreaInsets.top
					self.contextViewSnapshot?.frame = viewRect
					self.contextViewSnapshot?.frame.origin.y += self.scrollView.contentOffset.y
				}
			}
		}
		withFibSpringAnimation(duration: 0.4) {[weak self] in
			guard let self = self else { return }
			
			self.contextMenu.transform = .init(scaleX: 0.01, y: 0.01)
			self.contextMenu.frame.origin = self.contextViewRectInWindow.center
			self.contextMenu.alpha = 0
			self.overlayView.alpha = 0
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
					feedBack.impactOccurred()
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
