//
//  UIScrollView+Addtion.swift
//  CollectionView
//
//  Created by Luke on 4/16/17.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

// swiftlint:disable all
extension UIScrollView {
	
	public var expandedRect: CGRect? {
		guard let self = self as? FibGrid else { return nil }
		guard self.needExpandedWidth || self.needExpandedHeight else { return nil }
		var rect = bounds
		if self.needExpandedWidth {
			rect.origin.x = -(rect.width)
			rect.size.width = rect.width * 3
		}
		if self.needExpandedHeight {
			rect.origin.y = -(rect.height)
			rect.size.height = rect.height * 3
		}
		return rect
	}
	
	public var visibleFrame: CGRect {
		if let expandedRect = expandedRect {
			return expandedRect
		}
		return bounds
	}
	public var visibleFrameLessInset: CGRect {
		var visibleFrameLessInset = visibleFrame.inset(by: adjustedContentInset)
		if let grid = self as? FibGrid, let gridRootView = grid.containedRootView {
			if let headerViewModel = gridRootView._headerViewModel {
				let headerHeight = grid.containedRootView?._headerInitialHeight ?? 0
				visibleFrameLessInset.origin.y -= headerHeight
				if headerViewModel.atTop {
					visibleFrameLessInset.origin.y += grid.additionalHeaderInset ?? 0
					visibleFrameLessInset.size.height += grid.additionalHeaderInset ?? 0
				}
			} else if let navigationConfiguration = gridRootView.navigationConfiguration {
				visibleFrameLessInset.origin.y += grid.additionalHeaderInset ?? 0
				visibleFrameLessInset.size.height += grid.additionalHeaderInset ?? 0
			} else {
				switch gridRootView.topInsetStrategy {
				case .custom(let margin):
					visibleFrameLessInset.origin.y -= (gridRootView.safeAreaInsets.top - margin())
				case .safeArea: break
				case .top:
					visibleFrameLessInset.origin.y -= gridRootView.safeAreaInsets.top
				case .statusBar:
					visibleFrameLessInset.origin.y -= (gridRootView.safeAreaInsets.top - (gridRootView.statusBarFrame?.height ?? 0))
				}
			}
						
		}
		return visibleFrameLessInset
	}
	
	public func getCurrentFrameLessInset() -> CGRect {
		var visibleFrameLessInset = frame.inset(by: adjustedContentInset)
		if let grid = self as? FibGrid, let gridRootView = grid.containedRootView {
			if let headerViewModel = gridRootView._headerViewModel {
				let headerHeight = grid.containedRootView?._headerInitialHeight ?? 0
				visibleFrameLessInset.origin.y -= headerHeight
				if headerViewModel.atTop {
					visibleFrameLessInset.origin.y += grid.additionalHeaderInset ?? 0
					visibleFrameLessInset.size.height -= grid.additionalHeaderInset ?? 0
				}
			} else if let navigationConfiguration = gridRootView.navigationConfiguration {
				visibleFrameLessInset.origin.y += grid.additionalHeaderInset ?? 0
				visibleFrameLessInset.size.height -= grid.additionalHeaderInset ?? 0
			} else {
				switch gridRootView.topInsetStrategy {
				case .custom(let margin):
					visibleFrameLessInset.origin.y -= (gridRootView.safeAreaInsets.top - margin())
				case .safeArea: break
				case .top:
					visibleFrameLessInset.origin.y -= gridRootView.safeAreaInsets.top
				case .statusBar:
					visibleFrameLessInset.origin.y -= (gridRootView.safeAreaInsets.top - (gridRootView.statusBarFrame?.height ?? 0))
				}
			}
						
		}
		return visibleFrameLessInset
	}
	public var absoluteFrameLessInset: CGRect {
		let insetRect = CGRect(origin: .zero, size: bounds.size).inset(by: contentInset)
		if let self = self as? FibGrid, self.isEmbedCollection {
			return insetRect
		}
		return insetRect.inset(by: safeAreaInsets)
	}
	public var innerSize: CGSize {
		if let expandedRect = expandedRect {
			return expandedRect.size
		}
		return absoluteFrameLessInset.size
	}
	public var offsetFrame: CGRect {
		return CGRect(
			x: -adjustedContentInset.left,
			y: -adjustedContentInset.top,
			width: max(0, contentSize.width - bounds.width + adjustedContentInset.right + adjustedContentInset.left),
			height: max(0, contentSize.height - bounds.height + adjustedContentInset.bottom + adjustedContentInset.top)
		)
	}
	public func absoluteLocation(for point: CGPoint) -> CGPoint {
		return point - contentOffset
	}
	public func scrollTo(edge: UIRectEdge, animated: Bool) {
		let target: CGPoint
		switch edge {
		case UIRectEdge.top:
			let currentOffset = contentOffset
			contentOffset.y =  -adjustedContentInset.top - 100
			var newAdjustedContentInset = adjustedContentInset
			contentOffset.y =  -newAdjustedContentInset.top - 100
			newAdjustedContentInset = adjustedContentInset
			contentOffset.y =  currentOffset.y
			target = CGPoint(x: 0, y: -newAdjustedContentInset.top)
		case UIRectEdge.bottom:
			target = CGPoint(x: contentOffset.x, y: offsetFrame.maxY)
		case UIRectEdge.left:
			target = CGPoint(x: offsetFrame.minX, y: contentOffset.y)
		case UIRectEdge.right:
			target = CGPoint(x: offsetFrame.maxX, y: contentOffset.y)
		default:
			return
		}
		let isUp = target.y < contentOffset.y
		let boundsHeight = (frame.size.height)
		let isTargetLargerThanBounds = abs(target.y - contentOffset.y) > (boundsHeight * 3)
		if animated {
			if isTargetLargerThanBounds {
				if isUp {
					contentOffset.y = target.y + (boundsHeight * 3)
				} else {
					contentOffset.y = target.y - (boundsHeight * 3)
				}
			}
		}
		setContentOffset(target, animated: animated)
	}
}
