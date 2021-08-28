//
//  AnyHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 27.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit

// swiftlint:disable all
public class AnimatedReloadAnimator: Animator {
    public static let defaultEntryTransform: CATransform3D = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, 0.8, 0.8, 1), 0, 0, -1)
    static let fancyEntryTransform: CATransform3D = {
        var trans = CATransform3DIdentity
        trans.m34 = -1 / 500
        return CATransform3DScale(CATransform3DRotate(CATransform3DTranslate(trans, 0, -50, -100), 0.5, 1, 0, 0), 0.8, 0.8, 1)
    }()

    let entryTransform: CATransform3D
    var animationContext: AnimationContext

    public enum PageDirection {
        case left
        case right

        func getTx(collectionView: CollectionView, frame: CGRect) -> CGFloat {
            switch self {
            case .left:
                return collectionView.frame.minX - frame.width
            case .right:
                return collectionView.frame.maxX + frame.width
            }
        }

        public var reverse: PageDirection {
            switch self {
            case .left:
                return .right
            case .right:
                return .left
            }
        }
    }

    var pageDirection: PageDirection?

    public init(entryTransform: CATransform3D = defaultEntryTransform, pageDirection: PageDirection? = nil, animationContext: AnimationContext = AnimationContext()) {
        self.entryTransform = entryTransform
        self.pageDirection = pageDirection
        self.animationContext = animationContext
        super.init()
    }

    override open func delete(collectionView: CollectionView, view: UIView) {
        if collectionView.isReloading, collectionView.bounds.intersects(view.frame) {
            let initialTransform = view.transform
            UIView.animate(withDuration: animationContext.deleteDuration, delay: 0, options: [.allowUserInteraction], animations: {
                if collectionView.isChangingPage, let direction = self.pageDirection {
                    view.layer.transform = CATransform3DTranslate(self.entryTransform, direction.reverse.getTx(collectionView: collectionView, frame: view.frame), 0, 0)
                } else {
                    view.layer.transform = self.entryTransform
                }
                view.alpha = 0
            }, completion: { _ in
                if !collectionView.visibleCells.contains(view) {
                    view.recycleForCollectionKitReuse()
                    view.transform = initialTransform
                    view.alpha = 1
                }
            })
        } else {
            view.recycleForCollectionKitReuse()
        }
    }

    override open func insert(collectionView: CollectionView, view: UIView, at: Int, frame: CGRect) {
        view.bounds = frame.bounds
        view.center = frame.center
        if collectionView.isReloading, collectionView.hasReloaded, collectionView.bounds.intersects(frame) {
            let offsetTime: TimeInterval = TimeInterval(frame.origin.distance(collectionView.contentOffset) / 3000)
            let initialTransform = view.transform
            if collectionView.isChangingPage, let direction = pageDirection {
                view.layer.transform = CATransform3DTranslate(entryTransform, direction.reverse.getTx(collectionView: collectionView, frame: frame), 0, 0)
            } else {
                view.layer.transform = entryTransform
            }
            view.alpha = 0
            UIView.animate(withDuration: animationContext.insertDuration, delay: offsetTime, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {
                view.transform = initialTransform
                view.alpha = 1
            })
        } else {
            view.alpha = 1
        }
    }

    override open func update(collectionView: CollectionView, view: UIView, at: Int, frame: CGRect) {
        let initialTransform = view.transform
        if needAnimateHeader(collectionView: collectionView, view: view, frame: frame) {
            UIView.performWithoutAnimation {
                view.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, 0, 1)
                super.update(collectionView: collectionView, view: view, at: at, frame: frame)
                return
            }
        }
        if view.center != frame.center {
            UIView.animate(withDuration: animationContext.updateDuration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.layoutSubviews, .allowUserInteraction], animations: {
                view.center = frame.center
            }, completion: nil)
        }
        if view.bounds.size != frame.bounds.size {
            UIView.animate(withDuration: animationContext.updateDuration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.layoutSubviews, .allowUserInteraction], animations: {
                view.bounds.size = frame.bounds.size
            }, completion: nil)
        }
        if view.alpha != 1 || view.transform != .identity || view.transform != initialTransform {
            UIView.animate(withDuration: animationContext.updateDuration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.transform = initialTransform
                view.alpha = 1
            }, completion: nil)
        }
    }

    func needAnimateHeader(collectionView: CollectionView, view: UIView, frame: CGRect) -> Bool {
        guard view is StickyHeaderView else { return false }
        let offset = abs(collectionView.contentOffset.y + collectionView.contentInset.top + collectionView.safeAreaInsets.top)
        let additionalHeaderoffset = abs(collectionView.contentOffset.y + (collectionView.additionalHeaderInset ?? 0) + collectionView.safeAreaInsets.top)
        let additionalHeaderoffsetLessSafeAreaTop = abs(collectionView.contentOffset.y + (collectionView.additionalHeaderInset ?? 0))
        return (frame.origin.y == offset
                || frame.origin.y == additionalHeaderoffset
                || frame.origin.y == additionalHeaderoffsetLessSafeAreaTop)

    }
}

/// DTO struct that represents animation behaviour of concrete Section
public struct AnimationContext {
    
    /// duration of insertion views
    let insertDuration: TimeInterval
    /// duration of delete views
    let deleteDuration: TimeInterval
    /// duration of update views
    let updateDuration: TimeInterval
    
    /// DTO struct that represents animation behaviour of concrete Section
    /// - Parameters:
    ///   - insertDuration: duration of insertion views
    ///   - deleteDuration: duration of delete views
    ///   - updateDuration: duration of update views
    public init(insertDuration: TimeInterval = 0.5,
                deleteDuration: TimeInterval = 0.25,
                updateDuration: TimeInterval = 0.6) {
        self.insertDuration = insertDuration
        self.deleteDuration = deleteDuration
        self.updateDuration = updateDuration
    }
}

public protocol StickyHeaderView {
    var isExpanded: Bool { get }
}

public extension StickyHeaderView {
    var isExpanded: Bool { true }
}

public func withFibSpringAnimation(duration: TimeInterval = 0.6, usingSpringWithDamping: CGFloat = 0.9, initialSpringVelocity: CGFloat = 0, _ closure: @escaping (() -> Void), completion: ((Bool) -> Void)? = nil) {
    UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: usingSpringWithDamping, initialSpringVelocity: initialSpringVelocity, options: [.layoutSubviews], animations: {
        closure()
    }, completion: { b in completion?(b) })
}
