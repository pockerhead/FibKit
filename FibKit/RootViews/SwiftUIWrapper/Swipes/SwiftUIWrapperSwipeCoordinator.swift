//
//  SwiftUIWrapperSwipeAnimator.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit
import SwiftUI

class SwiftUIWrapperSwipeCoordinator<Content: View>: NSObject, UIGestureRecognizerDelegate {
    
    // MARK: - Namespace Classes
    final class WrapperPanGR: UIPanGestureRecognizer {}
    final class WrapperSwipeGR: UISwipeGestureRecognizer {}
    
    // MARK: - Dependencies
    weak var swiftUIWrapper: SwiftUIWrapperContainer<Content>?
    
    // MARK: - Properties
    var haveSwipeAction = false
    var isSwipeOpen: Bool = false {
        didSet {
            if oldValue != isSwipeOpen, isSwipeOpen {
                onSwipeOpenClosure?()
            }
        }
    }
    var openedSwipe: SwipeType?
    var rightSwipeViews: [SwipeView]? {
        didSet {
            haveSwipeAction = haveSwipeAction || rightSwipeViews?.isEmpty == false
        }
    }
    var rightSwipeActions: [() -> Void] = []
    var leftSwipeViews: [SwipeView]? {
        didSet {
            haveSwipeAction = haveSwipeAction || leftSwipeViews?.isEmpty == false
        }
    }
    var leftSwipeActions: [() -> Void] = []
    var onSwipeOpenClosure: (()->())?
    lazy var swipeRight: WrapperSwipeGR = { WrapperSwipeGR(target: self, action: #selector(swipeGest(_:))) }()
    lazy var swipeLeft: WrapperSwipeGR = { WrapperSwipeGR(target: self, action: #selector(swipeGest(_:))) }()
    lazy var pan: WrapperPanGR = { WrapperPanGR(target: self, action: #selector(panGest(_:))) }()
    var rightSwipeHostingViewWidth: CGFloat?
    var leftSwipeHostingViewWidth: CGFloat?
    fileprivate var rightSwipeHosting = UIHostingController<SwipeStackView>(rootView: SwipeStackView())
    var rightSwipeHostingView: UIView {
        rightSwipeHosting.view
    }
    fileprivate var leftSwipeHosting = UIHostingController<SwipeStackView>(rootView: SwipeStackView())
    var leftSwipeHostingView: UIView {
        leftSwipeHosting.view
    }
    
    // MARK: - Init
    init(wrapper: SwiftUIWrapperContainer<Content>) {
        self.swiftUIWrapper = wrapper
    }
    
    public func configureUI() {
    }
    
    func addSwipeViewsIfNeeded() {
        guard rightSwipeHostingView.superview == nil,
              leftSwipeHostingView.superview == nil else { return }
        rightSwipeHostingView.clipsToBounds = true
        rightSwipeHostingView.layer.masksToBounds = true
        leftSwipeHostingView.clipsToBounds = true
        leftSwipeHostingView.layer.masksToBounds = true
        rightSwipeHostingView.insetsLayoutMarginsFromSafeArea = false
        rightSwipeHostingView.preservesSuperviewLayoutMargins = false
        leftSwipeHostingView.insetsLayoutMarginsFromSafeArea = false
        leftSwipeHostingView.preservesSuperviewLayoutMargins = false
        swiftUIWrapper?.insertSubview(rightSwipeHostingView, belowSubview: swiftUIWrapper?.hostingView ?? UIView())
        swiftUIWrapper?.insertSubview(leftSwipeHostingView, belowSubview: swiftUIWrapper?.hostingView ?? UIView())
        rightSwipeHostingViewWidth = CGFloat((self.rightSwipeViews)?.count ?? 0) * 108
        leftSwipeHostingViewWidth = CGFloat((self.leftSwipeViews)?.count ?? 0) * 108
        rightSwipeHosting.rootView.views = ((self.rightSwipeViews) ?? [])
            .enumerated()
            .map({ index, swipe in
                SwipeView(isFirst: swipe.isFirst,
                          action: { [weak self] in
                            self?.rightSwipeActions.get(index)?()
                            DispatchQueue.main.async {
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                            self?.animateSwipe(isOpen: false, swipeWidth: self?.rightSwipeHostingViewWidth)
                          },
                          title: swipe.title,
                          icon: swipe.icon,
                          width: swipe.width,
                          background: swipe.background,
                          secondBackground: swipe.secondBackground)
            })
        leftSwipeHosting.rootView.views = ((self.leftSwipeViews) ?? [])
            .enumerated()
            .map({ index, swipe in
                SwipeView(isFirst: swipe.isFirst,
                          action: { [weak self] in
                            self?.leftSwipeActions.get(index)?()
                            DispatchQueue.main.async {
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                            self?.animateSwipe(isOpen: false, swipeWidth: self?.leftSwipeHostingViewWidth)
                          },
                          title: swipe.title,
                          icon: swipe.icon,
                          width: swipe.width,
                          background: swipe.background,
                          secondBackground: swipe.secondBackground)
            })
    }
    
    // MARK: - Public
    
    public func configure(with data: SwiftUIWrapper<Content>) {
        rightSwipeViews = data.rightSwipeViews
        leftSwipeViews = data.leftSwipeViews
        rightSwipeActions = (data.rightSwipeViews ?? []).map({ $0.action })
        leftSwipeActions = (data.leftSwipeViews ?? []).map({ $0.action })
        onSwipeOpenClosure = data.onSwipeOpenClosure
        addSwipes(leftSwipeViews: data.leftSwipeViews, rightSwipeViews: data.rightSwipeViews)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? WrapperPanGR {
            if otherGestureRecognizer is WrapperSwipeGR {
                return pan.velocity(in: gestureRecognizer.view).x.isBeetween(-300, 300)
            }
            return abs(pan.velocity(in: gestureRecognizer.view).y)
                > abs(pan.velocity(in: gestureRecognizer.view).x)
        } else if gestureRecognizer is WrapperSwipeGR {
            if otherGestureRecognizer is WrapperPanGR {
                return false
            } else if let pan = otherGestureRecognizer as? UIPanGestureRecognizer {
                return abs(pan.velocity(in: gestureRecognizer.view).y)
                    < abs(pan.velocity(in: gestureRecognizer.view).x)
            }
        }
        if otherGestureRecognizer is WrapperSwipeGR {
            return false
        }
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? WrapperPanGR {
            return abs(pan.velocity(in: gestureRecognizer.view).y)
                < abs(pan.velocity(in: gestureRecognizer.view).x)
        }
        if gestureRecognizer is WrapperSwipeGR {
            return pan.velocity(in: pan.view).x.isOutside(-400, 400)
        }
        return true
    }
    // MARK: - Internal
    func animateSwipe(direction: SwipeType = .right,
                      isOpen: Bool,
                      swipeWidth: CGFloat?,
                      initialVel: CGFloat? = nil,
                      completion: (() -> Void)? = nil) {
        var isOpen = isOpen
        switch direction {
        case .left:
            if (leftSwipeViews ?? []).isEmpty {
                isOpen = false
            }
            swiftUIWrapper?.backgroundColor = (leftSwipeViews ?? self.leftSwipeViews)?.last?.secondBackground ?? .clear
        case .right:
            if (rightSwipeViews ?? []).isEmpty {
                isOpen = false
            }
            swiftUIWrapper?.backgroundColor = (rightSwipeViews ?? self.rightSwipeViews)?.first?.background ?? .clear
        }
        openedSwipe = isOpen ? direction : nil
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: initialVel ?? 0,
            options: [.allowUserInteraction],
            animations: {[weak swiftUIWrapper, weak self] in
                self?.isSwipeOpen = isOpen
                swiftUIWrapper?.hostingView.layer.cornerRadius = isOpen ? 12 : 0
                if isOpen {
                    switch direction {
                    case .left:
                        swiftUIWrapper?.hostingView.frame.origin.x = (swipeWidth ?? self?.leftSwipeHostingViewWidth ?? 0) - 8
                    case .right:
                        swiftUIWrapper?.hostingView.frame.origin.x = -(swipeWidth ?? self?.rightSwipeHostingViewWidth ?? 0) + 8
                    }
                } else {
                    swiftUIWrapper?.hostingView.frame.origin.x = 0
                }
            }, completion: {[weak self] _ in
                if !isOpen {
                    self?.rightSwipeHostingView.removeFromSuperview()
                    self?.leftSwipeHostingView.removeFromSuperview()
                }
                completion?()
            }
        )
    }
    
    func prepareForReuse() {
        haveSwipeAction = false
        isSwipeOpen = false
        rightSwipeHostingView.removeFromSuperview()
        leftSwipeHostingView.removeFromSuperview()
    }
    
    func addSwipes(leftSwipeViews: [SwipeView]? = nil,
                   rightSwipeViews: [SwipeView]? = nil) {
        swiftUIWrapper?.gestureRecognizers?.removeAll(where: { $0 is WrapperPanGR || $0 is WrapperSwipeGR })
        if haveSwipeAction {
            leftSwipeHostingView.isHidden = false
            rightSwipeHostingView.isHidden = false
            swipeLeft.direction = .left
            swipeLeft.delegate = self
            swiftUIWrapper?.addGestureRecognizer(swipeLeft)
            swipeRight.direction = .right
            swipeRight.delegate = self
            swiftUIWrapper?.addGestureRecognizer(swipeRight)
            pan.delegate = self
            swiftUIWrapper?.addGestureRecognizer(pan)
            swiftUIWrapper?.hostingView.clipsToBounds = true
            swiftUIWrapper?.hostingView.layer.masksToBounds = true
        } else {
            rightSwipeHostingView.isHidden = true
            leftSwipeHostingView.isHidden = true
            swiftUIWrapper?.hostingView.clipsToBounds = false
            swiftUIWrapper?.hostingView.layer.masksToBounds = false
        }
    }
    
    // MARK: - Actions
    @objc func swipeGest(_ sender: UISwipeGestureRecognizer) {
        switch sender.state {
        case .began:
            addSwipeViewsIfNeeded()
        case .ended:
            NotificationCenter.default.post(name: NSNotification.Name("startSwipeOnSwiftUIWrapper"),
                                            object: nil,
                                            userInfo: ["swipeViewRef": swiftUIWrapper as Any])
            animateSwipe(isOpen: sender === swipeLeft,
                         swipeWidth: rightSwipeHostingViewWidth,
                         initialVel: max(0, abs(pan.velocity(in: pan.view).x / 100)))
        default: break
        }
    }
    
    @objc func panGest(_ sender: UIPanGestureRecognizer) {
        guard let swiftUIWrapper = swiftUIWrapper else { return }
        switch sender.state {
        case .began:
            addSwipeViewsIfNeeded()
            NotificationCenter.default.post(name: NSNotification.Name("startSwipeOnSwiftUIWrapper"),
                                            object: nil,
                                            userInfo: ["swipeViewRef": swiftUIWrapper])
        case .changed:
            let rightSwipeWidth = rightSwipeHostingViewWidth ?? .zero
            let leftSwipeWidth = leftSwipeHostingViewWidth ?? .zero
            var swipeType: SwipeType?
            switch swiftUIWrapper.hostingView.frame.origin.x {
            case (0...):
                swipeType = .left
                swiftUIWrapper.backgroundColor = (leftSwipeViews ?? self.leftSwipeViews)?.last?.secondBackground ?? .clear
            case (...0):
                swipeType = .right
                swiftUIWrapper.backgroundColor = (rightSwipeViews ?? self.rightSwipeViews)?.first?.background ?? .clear
            default: break
            }
            let point = sender.translation(in: sender.view)
            var pointX = point.x
            if isSwipeOpen, let swipeType = openedSwipe {
                switch swipeType {
                case .right:
                    pointX = point.x - rightSwipeWidth
                case .left:
                    pointX = point.x + leftSwipeWidth
                }
            }
            if swiftUIWrapper.hostingView.frame.origin.x != 0, let swipeType = swipeType {
                switch swipeType {
                case .right:
                    if pointX < -rightSwipeWidth + 8 {
                        let distance = -rightSwipeWidth + 8 - pointX
                        let coef = CGFloat(0.9)
                        let width = swiftUIWrapper.hostingView.frame.width * 2
                        let adding = (distance * width * coef) / (width + coef * distance)
                        pointX += adding
                    }
                    let dist = Distance(x1: -rightSwipeWidth + 8, x2: 0)
                    let result = Distance(x1: 12, x2: 0).convertPoint(point: pointX + rightSwipeWidth - 8, from: dist)
                    swiftUIWrapper.hostingView.layer.cornerRadius = abs(result.clamp(0, 12))
                case .left:
                    if pointX > leftSwipeWidth - 8 {
                        let distance = pointX - leftSwipeWidth - 8
                        let coef = CGFloat(0.9)
                        let width = swiftUIWrapper.hostingView.frame.width * 2
                        let adding = (distance * width * coef) / (width + coef * distance)
                        pointX -= adding
                    }
                    let dist = Distance(x1: leftSwipeWidth - 8, x2: 0)
                    let result = Distance(x1: 12, x2: 0).convertPoint(point: pointX - leftSwipeWidth + 8, from: dist)
                    swiftUIWrapper.hostingView.layer.cornerRadius = abs(result.clamp(0, 12))
                }
                
            }
            let minClamp = (rightSwipeHostingViewWidth ?? 0) == 0 ? 0 : -swiftUIWrapper.hostingView.frame.width
            let maxClamp = (leftSwipeHostingViewWidth ?? 0) == 0 ? 0 : swiftUIWrapper.hostingView.frame.width
            swiftUIWrapper.hostingView.frame.origin.x = pointX.clamp(minClamp, maxClamp)
        case .cancelled, .failed, .ended:
            let rightSwipeWidth = rightSwipeHostingViewWidth ?? .zero
            let leftSwipeWidth = leftSwipeHostingViewWidth ?? .zero
            var swipeType: SwipeType?
            switch swiftUIWrapper.hostingView.frame.origin.x {
            case (0...): swipeType = .left
            case (...0): swipeType = .right
            default: break
            }
            let point = sender.translation(in: sender.view)
            let diff = sender.velocity(in: sender.view).x
            var pointX = point.x
            if isSwipeOpen, let swipeType = openedSwipe {
                switch swipeType {
                case .right:
                    pointX = point.x - rightSwipeWidth
                case .left:
                    pointX = point.x + leftSwipeWidth
                }
            }
            var swipeWidth: CGFloat = 0
            var needOpenSwipe = false
            if let swipeType = swipeType {
                switch swipeType {
                case .right:
                    needOpenSwipe = pointX + diff < -rightSwipeWidth / 3
                    swipeWidth = rightSwipeWidth
                case .left:
                    needOpenSwipe = pointX + diff > leftSwipeWidth / 3
                    swipeWidth = leftSwipeWidth
                }
                animateSwipe(direction: swipeType, isOpen: needOpenSwipe, swipeWidth: swipeWidth, initialVel: max(0, abs(diff / 100)))
            } else {
                animateSwipe(direction: .right, isOpen: false, swipeWidth: nil)
            }
        default: break
        }
    }

}
