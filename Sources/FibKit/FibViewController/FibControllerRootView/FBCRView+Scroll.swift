//
//  File.swift
//  
//
//  Created by Артём Балашов on 18.10.2023.
//

import UIKit

extension FibControllerRootView: UIScrollViewDelegate {
	
	open func scrollViewDidScroll(_ scrollView: UIScrollView) {
		proxyDelegate?.scrollViewDidScroll?(scrollView)
		configureShutterViewFrame()
		if rootFormView.scrollDirection == .vertical {
			scrollView.contentOffset.x = scrollView.adjustedContentInset.left
		} else if rootFormView.scrollDirection == .horizontal {
			scrollView.contentOffset.y = scrollView.adjustedContentInset.top
		}
		var navigationHeaderShift: CGFloat = 0
		if !isSearching, navigationConfiguration != nil {
			assignNavigationFramesIfNeeded()
			calculateHeaderFrame()
			updateHeaderFrame()
			navigationHeaderShift = getNavigationHeaderScrollShift() - getHeaderAdditionalNavigationMargin()
		}
		var headerChangedHeight: CGFloat = 0
		defer {
			self.rootFormView.additionalHeaderInset = headerChangedHeight + navigationHeaderShift
			self.rootFormView.verticalScrollIndicatorInsets.top = headerChangedHeight + navigationHeaderShift
		}
		guard let headerInitialHeight = _headerInitialHeight else { return }
		let offsetY = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
		let size = headerInitialHeight - offsetY
		var minHeight: CGFloat = headerInitialHeight
		var maxHeight: CGFloat = headerInitialHeight
		headerChangedHeight = size.clamp(minHeight, maxHeight)
		guard let headerViewModel = _headerViewModel else { return }
		guard headerViewModel.allowedStretchDirections.isEmpty == false else {
			return
		}
		if headerViewModel.allowedStretchDirections.contains(.down) {
			maxHeight = headerViewModel.maxHeight ?? .greatestFiniteMagnitude
		}
		if headerViewModel.allowedStretchDirections.contains(.up) {
			minHeight = headerViewModel.minHeight ?? 0
		}
		guard headerHeight >= minHeight && headerHeight <= maxHeight else {
			return
		}
		self.headerHeight = size.clamp(minHeight, maxHeight)
		header?.layoutIfNeeded()
		updateHeaderFrame()
		header?.sizeChanged(
			size: CGSize(width: header?.frame.width ?? 0,
						 height: size.clamp(minHeight, maxHeight)),
			initialHeight: headerInitialHeight,
			maxHeight: maxHeight,
			minHeight: minHeight
		)
	}
	
	public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
										  withVelocity velocity: CGPoint,
										  targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		proxyDelegate?.scrollViewWillEndDragging?(scrollView,
												  withVelocity: velocity,
												  targetContentOffset: targetContentOffset)
	}
	
	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		proxyDelegate?.scrollViewWillBeginDragging?(scrollView)
	}
}
