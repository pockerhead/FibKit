//
//  FibGrid + Scroll.swift
//  
//
//  Created by Денис Садаков on 17.08.2023.
//

import Foundation

extension FibGrid {
	
	public func scroll(to index: Int, animated: Bool) throws {
		let itemFrame = flattenedProvider.frame(at: index)
		var headerFrame: CGRect = .zero
		if let header = visibleCells.first(where: {$0 is StickyHeaderView}) {
			headerFrame = header.frame
		}
		var targetPoint = CGPoint(x: itemFrame.origin.x + headerFrame.width, y: itemFrame.origin.y + headerFrame.height)
		let itemXDiff = self.contentSize.width - itemFrame.origin.x
		let itemYDiff = self.contentSize.height - itemFrame.origin.y
		if itemXDiff < self.visibleFrame.width || itemYDiff < self.visibleFrame.height {
			targetPoint = CGPoint(x: self.contentSize.width - self.visibleFrame.width, y:self.contentSize.height - self.visibleFrame.height)
		}
		if animated {
			UIView.animate(withDuration: 0.3) {
				self.contentOffset = targetPoint
			}
		} else {
			self.contentOffset = targetPoint
		}
	}
	
	public func scrollToFirst(where predicate: ((ViewModelWithViewClass?) -> Bool), animated: Bool = true) throws {
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(FibGridError.unableToScroll)
		}
		var indexPath: IndexPath?
		for (sectionIndex, provider) in provider.sections.enumerated() {
			guard let section = provider as? GridSection else { continue }
			for (index, viewModel) in section.data.enumerated() {
				if predicate(viewModel) {
					indexPath = .init(item: index * 2, section: sectionIndex)
					break
				}
			}
			if indexPath != nil { break }
		}
		guard let indexPath = indexPath else { return }
		try scroll(to: indexPath, animated: animated)
	}
	
	public func scroll(to section: GridSection, animated: Bool) throws {
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(FibGridError.unableToScroll)
		}
		guard let index = provider.sections.firstIndex(where: { $0.identifier == section.identifier }) else {
			debugPrint("Incorrect section index at \(section.identifier ?? "undef")")
			throw(FibGridError.unableToScroll)
		}
		try scroll(to: IndexPath(row: 0, section: index), animated: animated)
	}
	
	public func scroll(to sectionId: String, animated: Bool) throws {
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(FibGridError.unableToScroll)
		}
		guard let index = provider.sections.firstIndex(where: { $0.identifier == sectionId }) else {
			debugPrint("Not found section with id \(sectionId)")
			throw(FibGridError.unableToScroll)
		}
		try scroll(to: IndexPath(row: 0, section: index), animated: animated)
	}
	
	@discardableResult
	public func scroll(
		to indexPath: IndexPath,
		animated: Bool,
		considerNearbyItems: Bool = false,
		bounce: CGFloat = 0,
		customScroll: ((CGPoint, CGFloat) -> Void)? = FibGrid.defaultCustomScrollClosure
	) throws -> CGPoint {
		var indexPath = indexPath
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(FibGridError.unableToScroll)
		}
		let optInner = provider.sections.get(indexPath.section) as? (Provider & LayoutableProvider)
		guard let innerProvider = optInner else {
			debugPrint("Incorrect inner provider \(String(describing: optInner)) in \(provider) provider")
			throw(FibGridError.unableToScroll)
		}
		
		if let fbProvider = innerProvider as? FibGridProvider,
		   fbProvider.separatorViewModel != nil {
			indexPath.item = indexPath.item * 2
			indexPath.item = min(indexPath.item, fbProvider.numberOfItems - 1)
		}
		var topMargin: CGFloat = 0
		if indexPath.section > 0 {
			topMargin = (0...(indexPath.section - 1)).reduce(0, { accum, nextIndex in
				let sectionInnerSize = (provider.sections.get(nextIndex)?.contentSize.height ?? 0)
				var headerSize = CGSize.zero
				if let fvhp = provider as? FibGridHeaderProvider,
				   let data = (fvhp.sections.get(nextIndex) as? SectionProtocol)?.headerData,
				   let dummy = fvhp.headerViewSource
					.getDummyView(data: data) as? ViewModelConfigurable {
					
					headerSize = fvhp.headerSizeSource.size(at: nextIndex,
															data: data,
															collectionSize: contentSize,
															dummyView: dummy,
															direction: fvhp.scrollDirection)
				}
				
				return accum + sectionInnerSize + headerSize.height
			})
		}
		let itemFrame = innerProvider.frame(at: indexPath.item)
		let insetLeft = (innerProvider.layout as? InsetLayout)?.insets.left ?? 0
		let insetTop = (innerProvider.layout as? InsetLayout)?.insets.top ?? 0
		var horizontalScroll = false
		if ((innerProvider.layout as? WrapperLayout)?
			.rootLayout as? RowLayout) != nil {
			if provider.sections.count != 1 {
				throw(FibGridError.unableToScroll)
			}
			horizontalScroll = true
		}
		let flowSpacing = ((innerProvider.layout as? WrapperLayout)?
			.rootLayout as? FlowLayout)?
			.lineSpacing ?? 0
		let targetY = itemFrame.origin.y + insetTop + topMargin - flowSpacing - (flowSpacing / 2) - adjustedContentInset.top
		var targetPoint = CGPoint(x: itemFrame.origin.x - insetLeft,
								  y: targetY)
		if considerNearbyItems,
		   indexPath.item - 1 >= 0,
		   indexPath.item + 1 <= ((innerProvider as? FibGridProvider)?.dataSource.data.count ?? 0) - 1 {
			let absoluteItemFrame = self.convert(itemFrame, to: self.superview)
			if absoluteItemFrame.center.x + 1 > visibleFrame.width / 2 {
				let nextItemFrame = innerProvider.frame(at: indexPath.item + 1)
				guard nextItemFrame.maxX > visibleFrame.maxX else {
					throw(FibGridError.unableToScroll)
				}
				targetPoint.x -= (visibleFrame.width - itemFrame.width)
				targetPoint.x += nextItemFrame.width
				targetPoint.x = max(targetPoint.x, 0)
			} else if absoluteItemFrame.center.x - 1 < visibleFrame.width / 2 {
				let previousItemFrame = innerProvider.frame(at: indexPath.item - 1)
				guard previousItemFrame.minX < visibleFrame.minX else {
					throw(FibGridError.unableToScroll)
				}
				targetPoint.x -= previousItemFrame.width
				targetPoint.x = max(targetPoint.x, 0)
			}
		}
		let itemYDiff = self.contentSize.height - targetPoint.y - contentInset.bottom
		if !horizontalScroll, self.contentSize.height >= self.visibleFrame.height, (itemYDiff + 1) < self.visibleFrame.height {
			let targetX = self.contentSize.width - self.visibleFrame.width + safeAreaInsets.right
			let targetY = self.contentSize.height - self.visibleFrame.height + safeAreaInsets.bottom
			targetPoint = CGPoint(x: targetX, y: targetY)
		}
		let itemXDiff = self.contentSize.width - targetPoint.x - contentInset.right
		if self.contentSize.width >= self.visibleFrame.width, (itemXDiff + 1) < self.visibleFrame.width {
			let targetX = self.contentSize.width - self.visibleFrame.width + safeAreaInsets.right
			let targetY = self.contentSize.height - self.visibleFrame.height + safeAreaInsets.bottom
			targetPoint = CGPoint(x: max(0, targetX), y: max(0, targetY))
		}
		if horizontalScroll {
			targetPoint.y = 0
		}
		let isUp = targetPoint.y < contentOffset.y
		let boundsHeight = (frame.size.height)
		let isTargetLargerThanBounds = abs(targetPoint.y - contentOffset.y) > boundsHeight
		if animated {
			if isTargetLargerThanBounds {
				if isUp {
					contentOffset.y = targetPoint.y + (boundsHeight / 2.3)
				} else {
					contentOffset.y = targetPoint.y - (boundsHeight / 2.3)
				}
			}
			if let customScroll = customScroll {
				customScroll(targetPoint, bounce)
			} else {
				setContentOffset(targetPoint, animated: true)
			}
		} else {
			setContentOffset(targetPoint, animated: false)
		}
		return targetPoint
	}
	
}
