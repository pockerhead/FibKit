//
//  PopoverService.swift
//  SmartStaff
//
//  Created by artem on 03.05.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit
import VisualEffectView

/// Shared instance let for simple calling methods
public let PopoverService = PopoverServiceInstance.shared
public protocol HighlightableView: ViewModelConfigurable {
    
    var isHighlighted: Bool { get set }
    
    func setHighlighted(highlighted: Bool)
}

public typealias ContextMenu = FibCell.ViewModel

/// Class for showing conextMenu with formview inside it
public final class PopoverServiceInstance: NSObject, UITraitEnvironment {
	
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

    public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		applyAppearance()
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

    /// Own window for alertService
    lazy var window: UIWindow = {
        let w = DragProxyWindow(frame: UIScreen.main.bounds)
        dragGest.delegate = self
        w.addGestureRecognizer(dragGest)
		let gr = UITapGestureRecognizer(target: self, action: #selector(hideContextMenu))
		w.addGestureRecognizer(gr)
        w.rootViewController = RootTransparentStyleViewController()
        return w
    }()
    
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
        UIApplication.shared.delegate?.window
    }

    /// Snapshot of view, that captured by context
    private var contextViewSnapshot: UIView?

    /// Weak reference to view, captured by context
    private weak var contextView: UIView?
    private weak var fromGesture: UIGestureRecognizer?

    /// Feedback generator
    private var feedBack = UIImpactFeedbackGenerator(style: .medium)
    
    private var contextViewRectInWindow = CGRect()
    
    /// Shows conext menu for choosed view
    /// - Parameters:
    ///   - menu: see FibCell.ViewModel
    ///   - view: captured view
    ///   - controller: viewController that contains captured view
    public func showContextMenu(_ menu: ContextMenu,
                                view: UIView?,
                                needBlurBackground: Bool = true,
                                gesture: UIGestureRecognizer?) {
        guard var viewRect = view?.superview?.convert(view?.frame ?? .zero, to: nil) else { return }
        let oldRect = viewRect
        if viewRect.minY < window.safeAreaInsets.top {
            viewRect.origin.y = window.safeAreaInsets.top
        } else if viewRect.maxY > window.frame.height - window.safeAreaInsets.bottom {
            viewRect.origin.y = window.frame.height - window.safeAreaInsets.bottom - viewRect.height
        }
        contextView = view
        contextViewRectInWindow = viewRect
        currentAppWindow??.endEditing(true)
//        menu.sections = menu.sections.map { section in
//            let tapHandler = section.tapHandler
//            return section.tapHandler({[weak self] context in
//                self?.hideContextMenu()
//                DispatchQueue.main.async {
//                    tapHandler?(context)
//                }
//            })
//        }
        // @ab: TODO - исправить баги
//        if let gesture = gesture {
//            self.fromGesture = gesture
//            gesture.addTarget(self, action: #selector(drag(_:)))
//            window.addGestureRecognizer(gesture)
//            gesture.delegate = self
//        }
        let safeAreaHorizontal = window.safeAreaInsets.left + window.safeAreaInsets.right
        let safeAreaVertical = window.safeAreaInsets.top + window.safeAreaInsets.bottom
		let width = (window.bounds.width - 128 - safeAreaHorizontal).clamp(0, 254)
        let size = CGSize(width: width,
                          height: window.bounds.height - 64 - safeAreaVertical)
        let formViewSize = self.contextMenu.sizeWith(size, data: menu)
        let formViewHeight = formViewSize?.height.clamp(0, size.height) ?? size.height
        let viewCenterHigherThanSelfCenter = viewRect.center.y < window.center.y
        var contextMenuY: CGFloat = viewCenterHigherThanSelfCenter
            ? viewRect.maxY + 16
            : viewRect.minY - formViewHeight - 16
        contextMenuY = max(contextMenuY, window.safeAreaInsets.top + 32)

        configureOverlayView(needBlur: needBlurBackground)
        configureContextMenu(with: size, viewRect: viewRect, formViewHeight: formViewHeight)
        configureSnapshot(with: view, viewRect: viewRect, oldRect: oldRect)
        prepareWindow()
        
        feedBack.impactOccurred()
        withFibSpringAnimation(duration: 0.4) {[weak self] in
            self?.applyContextViewRect(
                viewCenterHigherThanSelfCenter: viewCenterHigherThanSelfCenter,
                contextMenuY: contextMenuY,
                formViewHeight: formViewHeight,
                viewRect: viewRect,
                size: size,
                needBlurBackground: needBlurBackground
            )
        } completion: {[weak self] _ in
            guard let self = self else { return }
            self.contextMenu.configure(with: menu)
            self.contextMenu.formView.scrollTo(edge: .top, animated: true)
        }
    }

    private func prepareWindow() {
        self.window.layoutIfNeeded()
        window.isHidden = false
        window.windowLevel = .alert
    }

    private func configureOverlayView(needBlur: Bool) {
        window.addSubview(overlayView)
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
        window.addSubview(contextViewSnapshot!)
        contextViewSnapshot!.frame = oldRect
        contextViewSnapshot?.isUserInteractionEnabled = false
//        contextViewSnapshot?.layer.applySketchShadow()
        delay {
            let size = view?.frame.size ?? .zero
            withFibSpringAnimation {
                if viewRect != oldRect {
                    self.contextViewSnapshot?.frame = viewRect
                }
                let xDiff = (self.contextViewSnapshot?.frame.size.width ?? 0) - size.width
                let yDiff = (self.contextViewSnapshot?.frame.size.height ?? 0) - size.height
                self.contextViewSnapshot?.frame.size = size
                self.contextViewSnapshot?.frame.origin.x += xDiff / 2
                self.contextViewSnapshot?.frame.origin.y += yDiff / 2
            }
        }
    }

    private func configureContextMenu(with size: CGSize, viewRect: CGRect, formViewHeight: CGFloat) {
        window.addSubview(contextMenu)
        self.contextMenu.frame.size = size
        self.contextMenu.backgroundColor = .clear
        self.contextMenu.formView.showsVerticalScrollIndicator = false
        self.contextMenu.formView.isScrollEnabled = true
		self.contextMenu.formView.transform = .init(scaleX: 0.01, y: 0.01)
		let contextMenuX = viewRect.center.x - (size.width / 2)
		let contextMenuY = viewRect.origin.y
        self.contextMenu.frame = CGRect(x: contextMenuX,
                                        y: contextMenuY,
                                        width: 0,
                                        height: 0)
        self.contextMenu.alpha = 0
    }

    private func applyContextViewRect(viewCenterHigherThanSelfCenter: Bool,
                                      contextMenuY: CGFloat,
                                      formViewHeight: CGFloat,
                                      viewRect: CGRect,
                                      size: CGSize,
                                      needBlurBackground: Bool) {
        self.window.layoutIfNeeded()
        let normalizedY = viewCenterHigherThanSelfCenter
            ? contextMenuY
            : max(contextMenuY, viewRect.size.height + 16)
        let normalizedHeight = min(formViewHeight,
                                   size.height - viewRect.size.height - 16)
        let minimumX: CGFloat = 16
        let maximumX = window.bounds.width - 16 - size.width
        let contextMenuX = viewRect.minX.clamp(minimumX, maximumX)
        
		self.contextMenu.frame = CGRect(x: contextMenuX,
                                        y: normalizedY,
                                        width: size.width,
                                        height: normalizedHeight)
        self.contextMenu.alpha = 1
		// TODO: @ab есть баги
		//        if needBlurBackground, let currentAppWindow = currentAppWindow {
		//            currentAppWindow?.transform = .init(scaleX: 0.98, y: 0.98)
		//        }
        self.contextMenu.formView.transform = .identity
		self.overlayView.alpha = needBlurBackground ? 1 : 0
        guard let contextSnapshot = self.contextViewSnapshot else { return }
        if viewCenterHigherThanSelfCenter == false
            && self.contextMenu.frame.maxY > contextSnapshot.frame.minY {
            contextSnapshot.frame.origin.y = self.contextMenu.frame.maxY + 16
        } else if viewCenterHigherThanSelfCenter == true
            && self.contextMenu.frame.minY < contextSnapshot.frame.maxY {
            contextSnapshot.frame.origin.y = self.contextMenu.frame.minY - contextSnapshot.frame.height - 16
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
        feedBack.impactOccurred()
        self.contextView?.isHidden = false
        self.contextView?.alpha = 0
        delay(0.2) {
            withFibSpringAnimation(duration: 0.2) {
                self.contextViewSnapshot?.alpha = 0
            }
        }
        withFibSpringAnimation(duration: 0.1) {
//            guard let self = self else { return }
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
                    self.contextViewSnapshot?.frame = viewRect
                }
            }
        }
        withFibSpringAnimation(duration: 0.4) {[weak self] in
            guard let self = self else { return }
            
            
            self.contextMenu.transform = .init(scaleX: 0.01, y: 0.01)
            self.contextMenu.frame.origin.x = self.contextViewRectInWindow.center.x
            self.contextMenu.frame.origin.y = self.contextViewRectInWindow.center.y
            self.contextMenu.alpha = 0
            self.overlayView.alpha = 0
        } completion: {[weak self] _ in
            guard let self = self else { return }
            self.contextView = nil
            self.window.isHidden = true
            self.window.resignKey()
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                self.contextMenu.removeFromSuperview()
                self.contextMenu.transform = .identity
                self.overlayView.removeFromSuperview()
                self.contextViewSnapshot?.removeFromSuperview()
                completion?()
				self.completion?()
				self.completion = nil
            }
        }
    }
	
	func applyAppearance() {
		contextMenu.backgroundColor = .clear
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
        debugPrint("[BEGAN]", point)
        touchesBegan?(point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        touchesEnded?(point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
		debugPrint("[MOVED]", point)
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
