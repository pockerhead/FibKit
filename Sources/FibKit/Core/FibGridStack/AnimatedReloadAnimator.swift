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
	
	public static let simpleEntryTransform: CATransform3D = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, 0.8, 1, 1), 0, 0, 0)
	public static let defaultEntryTransform: CATransform3D = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, 0.8, 0.8, 1), 0, 0, 0)
	static let fancyEntryTransform: CATransform3D = {
		var trans = CATransform3DIdentity
		trans.m34 = -1 / 500
		return CATransform3DScale(CATransform3DRotate(CATransform3DTranslate(trans, 0, -50, -100), 0.5, 1, 0, 0), 0.8, 0.8, 1)
	}()
	
	let entryTransform: CATransform3D
	var animationContext: AnimationContext
	let needInsertionDelay: Bool
	var needEntryTransform: Bool = false
	
	public enum PageDirection {
		case left
		case right
		
		func getTx(collectionView: FibGrid, frame: CGRect) -> CGFloat {
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
	
	public init(entryTransform: CATransform3D = defaultEntryTransform, pageDirection: PageDirection? = nil, animationContext: AnimationContext = AnimationContext(), needInsertionDelay: Bool = true) {
		self.entryTransform = entryTransform
		self.pageDirection = pageDirection
		self.animationContext = animationContext
		self.needInsertionDelay = needInsertionDelay
		super.init()
	}
	
	override open func delete(collectionView: FibGrid, view: UIView) {
		if collectionView.isReloading, collectionView.bounds.intersects(view.frame) {
			let initialTransform = view.transform
			UIView.animate(withDuration: animationContext.deleteDuration, delay: 0, options: [.allowUserInteraction], animations: {[weak self] in
				guard let self = self else { return }
				if collectionView.isChangingPage, let direction = self.pageDirection {
					view.layer.transform = CATransform3DTranslate(self.entryTransform, direction.reverse.getTx(collectionView: collectionView, frame: view.frame), 0, 0)
				} else if needEntryTransform {
					view.layer.transform = self.entryTransform
				}
				view.alpha = 0
			}, completion: {[weak self] _ in
				if !collectionView.visibleCells.contains(view) {
					guard let self = self else { return }
					view.recycleForCollectionKitReuse()
					view.transform = initialTransform
					view.alpha = 1
				}
			})
		} else {
			view.recycleForCollectionKitReuse()
		}
	}
	
	override open func insert(collectionView: FibGrid, view: UIView, at: Int, frame: CGRect) {
		view.bounds = frame.bounds
		view.center = frame.center
		if collectionView.isReloading, collectionView.hasReloaded, collectionView.bounds.intersects(frame) {
			let offsetTime: TimeInterval = TimeInterval(frame.origin.distance(collectionView.contentOffset) / 3000)
			let initialTransform = view.transform
			if collectionView.isChangingPage, let direction = pageDirection {
				view.layer.transform = CATransform3DTranslate(entryTransform, direction.reverse.getTx(collectionView: collectionView, frame: frame), 0, 0)
			} else if needEntryTransform {
				view.layer.transform = entryTransform
			}
			view.alpha = 0
			UIView.animate(withDuration: animationContext.insertDuration, delay: needInsertionDelay ? offsetTime : 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {[weak self] in
				guard let self = self else { return }
				view.transform = initialTransform
				view.alpha = 1
			})
		} else {
			view.alpha = 1
		}
	}
	
	override open func update(collectionView: FibGrid, view: UIView, at: Int, frame: CGRect) {
		let initialTransform = view.transform
		if needAnimateHeader(collectionView: collectionView, view: view, frame: frame) {
			UIView.performWithoutAnimation {
				collectionView.bringSubviewToFront(view)
				view.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, 0, 1)
				super.update(collectionView: collectionView, view: view, at: at, frame: frame)
				return
			}
		}
		if view.center != frame.center {
			UIView.animate(withDuration: animationContext.updateDuration, delay: 0, usingSpringWithDamping: animationContext.updateDamping, initialSpringVelocity: 0, options: [.layoutSubviews, .allowUserInteraction], animations: {
				view.center = frame.center
			}, completion: nil)
		}
		if view.bounds.size != frame.bounds.size {
			UIView.animate(withDuration: animationContext.updateDuration, delay: 0, usingSpringWithDamping: animationContext.updateDamping, initialSpringVelocity: 0, options: [.layoutSubviews, .allowUserInteraction], animations: {
				view.bounds.size = frame.bounds.size
			}, completion: nil)
		}
		if view.alpha != 1 || view.transform != .identity || view.transform != initialTransform {
			UIView.animate(withDuration: animationContext.updateDuration, delay: 0, usingSpringWithDamping: animationContext.updateDamping, initialSpringVelocity: 0, options: [], animations: {
				view.transform = initialTransform
				view.alpha = 1
			}, completion: nil)
		}
	}
	
	func needAnimateHeader(collectionView: FibGrid, view: UIView, frame: CGRect) -> Bool {
		guard view is StickyHeaderView else { return false }
		let pureOffset = abs(collectionView.contentOffset.y)
		let offset = abs(collectionView.contentOffset.y + collectionView.contentInset.top + collectionView.safeAreaInsets.top)
		let additionalHeaderoffset = abs(collectionView.contentOffset.y + (collectionView.additionalHeaderInset ?? 0) + collectionView.safeAreaInsets.top)
		let additionalHeaderoffsetLessSafeAreaTop = abs(collectionView.contentOffset.y + (collectionView.additionalHeaderInset ?? 0))
		let frameAtPureOffset = frame.origin.y.isBeetween(pureOffset - 1, pureOffset + 1)
		let frameAtOffset = frame.origin.y.isBeetween(offset - 1, offset + 1)
		let frameAtHeaderOffset = frame.origin.y.isBeetween(additionalHeaderoffset - 1, additionalHeaderoffset + 1)
		let frameAtHeaderOffsetLessSafeAreaTop = frame.origin.y.isBeetween(additionalHeaderoffsetLessSafeAreaTop - 1, additionalHeaderoffsetLessSafeAreaTop + 1)
		return (frameAtOffset
				|| frameAtHeaderOffset
				|| frameAtHeaderOffsetLessSafeAreaTop
				|| frameAtPureOffset) && (view.fb_isHeader ?? false)
		
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
	let updateDamping: CGFloat
	
	/// DTO struct that represents animation behaviour of concrete Section
	/// - Parameters:
	///   - insertDuration: duration of insertion views
	///   - deleteDuration: duration of delete views
	///   - updateDuration: duration of update views
	public init(insertDuration: TimeInterval = 0.5,
				deleteDuration: TimeInterval = 0.25,
				updateDuration: TimeInterval = 0.6,
				updateDamping: CGFloat = 0.9) {
		self.insertDuration = insertDuration
		self.deleteDuration = deleteDuration
		self.updateDuration = updateDuration
		self.updateDamping = updateDamping
	}
}

public protocol StickyHeaderView {
	var isExpanded: Bool { get }
}

public extension StickyHeaderView {
	var isExpanded: Bool { true }
}

public func withFibSpringAnimation(duration: TimeInterval = 0.6,
								   delay: TimeInterval = 0,
								   usingSpringWithDamping: CGFloat = 0.9,
								   initialSpringVelocity: CGFloat = 0,
								   options: UIView.AnimationOptions = [],
								   _ closure: @escaping (() -> Void),
								   completion: ((Bool) -> Void)? = nil) {
	UIView.animate(withDuration: duration,
				   delay: delay,
				   usingSpringWithDamping: usingSpringWithDamping,
				   initialSpringVelocity: initialSpringVelocity,
				   options: options,
				   animations: { closure() },
				   completion: { b in completion?(b) })
}
