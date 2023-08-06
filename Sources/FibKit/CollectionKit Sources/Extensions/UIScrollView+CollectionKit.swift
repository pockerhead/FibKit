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
		guard let self = self as? CollectionView else { return nil }
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
		if let grid = self as? FibGrid {
			visibleFrameLessInset.origin.y -= grid.contentInset.top
			visibleFrameLessInset.size.height += grid.contentInset.top
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
		return CGRect(x: -contentInset.left, y: -contentInset.top,
					  width: max(0, contentSize.width - bounds.width + contentInset.right + contentInset.left),
					  height: max(0, contentSize.height - bounds.height + contentInset.bottom + contentInset.top))
	}
	public func absoluteLocation(for point: CGPoint) -> CGPoint {
		return point - contentOffset
	}
	public func scrollTo(edge: UIRectEdge, animated: Bool) {
		let target: CGPoint
		switch edge {
		case UIRectEdge.top:
			if let formVCRootView = self.superview as? FibControllerRootView,
			   let controller = formVCRootView.controller,
			   controller.navigationController?.navigationBar.prefersLargeTitles == true {
				if controller.navigationItem.searchController != nil {
					target = CGPoint(x: contentOffset.x, y: offsetFrame.minY - 195)
				} else {
					target = CGPoint(x: contentOffset.x, y: offsetFrame.minY - 143)
				}
			} else {
				target = CGPoint(x: contentOffset.x, y: offsetFrame.minY)
			}
		case UIRectEdge.bottom:
			target = CGPoint(x: contentOffset.x, y: offsetFrame.maxY)
		case UIRectEdge.left:
			target = CGPoint(x: offsetFrame.minX, y: contentOffset.y)
		case UIRectEdge.right:
			target = CGPoint(x: offsetFrame.maxX, y: contentOffset.y)
		default:
			return
		}
		setContentOffset(target, animated: animated)
	}
}
