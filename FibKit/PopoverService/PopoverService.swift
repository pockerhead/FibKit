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

public typealias ContextMenu = FibCell.ViewModel

/// Class for showing conextMenu with formview inside it
public final class PopoverServiceInstance: NSObject, UITraitEnvironment {
    
    public struct Appearance {
        public static var overlayColorTint: UIColor = .systemBackground
    }

    public var traitCollection: UITraitCollection {
        .init()
    }

    public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        contextMenu.backgroundColor = .clear
        contextMenu.formView.backgroundColor = .clear
    }

    static let shared: PopoverServiceInstance = {
        let service = PopoverServiceInstance()
        return service
    }()
    private override init() {}

    /// Own window for alertService
    let window = UIWindow(frame: UIScreen.main.bounds)

    /// Blur view that applies with conext menu
    private lazy var overlayView: VisualEffectView = {
        let view = VisualEffectView()
        view.colorTint = Appearance.overlayColorTint
        view.colorTintAlpha = 0.2
        view.blurRadius = 16
        let gr = UITapGestureRecognizer(target: self, action: #selector(hideContextMenu))
        view.addGestureRecognizer(gr)
        return view
    }()

    /// Conext menu, contains self-sized formView with scroll
    private var contextMenu = FibCell()

    /// Snapshot of view, that captured by context
    private var contextViewSnapshot: UIView?

    /// Weak reference to view, captured by context
    private weak var contextView: UIView?

    /// Feedback generator
    private var feedBack = UIImpactFeedbackGenerator(style: .heavy)
    
    private var contextViewRectInWindow = CGRect()

    /// Shows conext menu for choosed view
    /// - Parameters:
    ///   - menu: see FibCell.ViewModel
    ///   - view: captured view
    ///   - controller: viewController that contains captured view
    public func showContextMenu(_ menu: ContextMenu, view: UIView?, controller: UIViewController?, needBlurBackground: Bool = true) {
        guard let viewRect = view?.superview?.convert(view?.frame ?? .zero, to: nil) else { return }
        contextView = view
        contextViewRectInWindow = viewRect
        controller?.endEditing()
        menu.sections = menu.sections.map { section in
            let tapHandler = section.tapHandler
            return section.tapHandler({[weak self] context in
                self?.hideContextMenu()
                DispatchQueue.main.async {
                    tapHandler?(context)
                }
            })
        }
        let safeAreaHorizontal = window.safeAreaInsets.left + window.safeAreaInsets.right
        let safeAreaVertical = window.safeAreaInsets.top + window.safeAreaInsets.bottom
        let size = CGSize(width: window.bounds.width - 64 - safeAreaHorizontal,
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
        configureSnapshot(with: view, viewRect: viewRect)
        prepareWindow()

        feedBack.impactOccurred()
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0,
                       options: [.layoutSubviews],
                       animations: {[weak self] in
                        self?.applyContextViewRect(viewCenterHigherThanSelfCenter: viewCenterHigherThanSelfCenter,
                                                   contextMenuY: contextMenuY,
                                                   formViewHeight: formViewHeight,
                                                   viewRect: viewRect,
                                                   size: size)
            }, completion: {[weak self] _ in
                guard let self = self else { return }
                self.contextMenu.configure(with: menu)
                self.contextMenu.formView.scrollTo(edge: .top, animated: true)
        })
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
        }
        self.overlayView.alpha = 0
    }

    private func configureSnapshot(with view: UIView?, viewRect: CGRect) {
        view?.applyIdentityRecursive()
        contextViewSnapshot = view?.snapshotView(afterScreenUpdates: true)
        contextView?.alpha = 0
        window.addSubview(contextViewSnapshot!)
        contextViewSnapshot!.frame = viewRect
        contextViewSnapshot?.isUserInteractionEnabled = false
    }

    private func configureContextMenu(with size: CGSize, viewRect: CGRect, formViewHeight: CGFloat) {
        window.addSubview(contextMenu)
        self.contextMenu.frame.size = size
        self.contextMenu.backgroundColor = .clear
        self.contextMenu.formView.backgroundColor = .clear
        self.contextMenu.formView.showsVerticalScrollIndicator = false
        self.contextMenu.formView.isScrollEnabled = true
        self.contextMenu.frame = CGRect(x: viewRect.center.x,
                                        y: viewRect.center.y,
                                        width: size.width,
                                        height: formViewHeight)
        self.contextMenu.alpha = 0
        self.contextMenu.formView.transform = .init(scaleX: 0, y: 0)
    }

    private func applyContextViewRect(viewCenterHigherThanSelfCenter: Bool,
                                      contextMenuY: CGFloat,
                                      formViewHeight: CGFloat,
                                      viewRect: CGRect,
                                      size: CGSize) {
        self.window.layoutIfNeeded()
        let normalizedY = viewCenterHigherThanSelfCenter
            ? contextMenuY
            : max(contextMenuY, viewRect.size.height + 16)
        let normalizedHeight = min(formViewHeight,
                                   size.height - viewRect.size.height - 16)
        self.contextMenu.frame = CGRect(x: 32,
                                        y: normalizedY,
                                        width: size.width,
                                        height: normalizedHeight)
        self.contextMenu.alpha = 1
        self.contextMenu.formView.transform = .identity
        self.overlayView.alpha = 1
        guard let contextSnapshot = self.contextViewSnapshot else { return }
        if viewCenterHigherThanSelfCenter == false
            && self.contextMenu.frame.maxY > contextSnapshot.frame.minY {
            contextSnapshot.frame.origin.y = self.contextMenu.frame.maxY + 16
        } else if viewCenterHigherThanSelfCenter == true
            && self.contextMenu.frame.minY < contextSnapshot.frame.maxY {
            contextSnapshot.frame.origin.y = self.contextMenu.frame.minY - contextSnapshot.frame.height - 16
        }
    }

    @objc public func hideContextMenu() {
        hideContextMenu(nil)
    }

    private func hideContextMenu(_ completion: (() -> Void)? = nil) {
        feedBack.impactOccurred()
        self.contextView?.isHidden = false
        self.contextView?.alpha = 0
        let oldFrame = self.contextView?.frame ?? .zero
        self.contextView?.frame = self.contextViewSnapshot?.superview?
            .convert(self.contextViewSnapshot?.frame ?? .zero,
                     to: self.contextView?.superview) ?? .zero
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [],
            animations: {[weak self] in
                guard let self = self else { return }
                if let viewRect = self.contextView?.superview?.convert(self.contextView?.frame ?? .zero, to: nil) {
                    self.contextViewSnapshot?.frame = viewRect
                }
                self.contextView?.alpha = 1
                self.contextView?.frame = oldFrame
                self.contextViewSnapshot?.alpha = 0
                self.contextMenu.transform = .init(scaleX: 0.01, y: 0.01)
                self.contextMenu.frame.origin.x = self.contextViewRectInWindow.center.x
                self.contextMenu.frame.origin.y = self.contextViewRectInWindow.center.y
                self.contextMenu.alpha = 0
                self.overlayView.alpha = 0
            },
            completion: {[weak self] _ in
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
                }
            }
        )
    }
}
