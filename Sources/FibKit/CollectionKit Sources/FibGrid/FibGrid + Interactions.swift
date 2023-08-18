//
//  FibGrid + Interactions.swift
//  
//
//  Created by Денис Садаков on 17.08.2023.
//

import Foundation


extension FibGrid {
	@objc func scrollWhenDragIfNeeded() {
		guard isInProcessDragging, let cell = draggedCell?.cell,
			  let selfWindowFrame = superview?.convert(frame, to: nil).inset(by: adjustedContentInset),
			  let cellWindowFrame = cell.superview?.convert(cell.frame, to: nil),
			  let provider = dragProvider as? FibGridProvider else { return }
		bringSubviewToFront(cell)
		let maxManualOffset: CGFloat = 5
		if provider.layout is FlowLayout || (provider.layout as? WrapperLayout)?.rootLayout is FlowLayout {
			if cellWindowFrame.maxY > selfWindowFrame.maxY {
				let x = contentOffset.x
				var y = contentOffset.y
				let offset = (cellWindowFrame.maxY - selfWindowFrame.maxY).clamp(0, maxManualOffset)
				y = (y + offset).clamp(0, contentSize.height - bounds.height)
				let increasedContentOffset = CGPoint(x: x, y: y)
				setContentOffset(increasedContentOffset, animated: false)
				DispatchQueue.main.async {
					self.draggedCell?.cell.center.x = self.longTapGestureRecognizer.location(in: self).x
					self.detectMovingCell()
				}
			} else if cellWindowFrame.origin.y < selfWindowFrame.origin.y {
				let x = contentOffset.x
				var y = contentOffset.y
				let offset = abs(cellWindowFrame.origin.y - selfWindowFrame.origin.y).clamp(0, maxManualOffset)
				y = (y - offset).clamp(0, contentSize.height - bounds.height)
				let increasedContentOffset = CGPoint(x: x, y: y)
				setContentOffset(increasedContentOffset, animated: false)
				DispatchQueue.main.async {
					self.draggedCell?.cell.center.x = self.longTapGestureRecognizer.location(in: self).x
					self.detectMovingCell()
				}
			}
		} else if provider.layout is RowLayout || (provider.layout as? WrapperLayout)?.rootLayout is RowLayout {
			if cellWindowFrame.maxX > selfWindowFrame.maxX {
				var x = contentOffset.x
				let y = contentOffset.y
				let offset = (cellWindowFrame.maxX - selfWindowFrame.maxX).clamp(0, maxManualOffset)
				x = (x + offset).clamp(0, contentSize.width - bounds.width)
				let increasedContentOffset = CGPoint(x: x, y: y)
				setContentOffset(increasedContentOffset, animated: false)
				DispatchQueue.main.async {
					self.draggedCell?.cell.center.x = self.longTapGestureRecognizer.location(in: self).x
					self.detectMovingCell()
				}
			} else if cellWindowFrame.origin.x < selfWindowFrame.origin.x {
				var x = contentOffset.x
				let y = contentOffset.y
				let offset = abs(cellWindowFrame.origin.x - selfWindowFrame.origin.x).clamp(0, maxManualOffset)
				x = (x - offset).clamp(0, contentSize.width - bounds.width)
				let increasedContentOffset = CGPoint(x: x, y: y)
				setContentOffset(increasedContentOffset, animated: false)
				DispatchQueue.main.async {
					self.draggedCell?.cell.center.x = self.longTapGestureRecognizer.location(in: self).x
					self.detectMovingCell()
				}
			}
		}
	}
	
	func detectMovingCell() {
		guard let draggedCell = draggedCell?.cell,
			  let draggedCellIndex = self.draggedCell?.index else { return }
		let context = LongGestureContext(view: draggedCell,
										 collectionView: self,
										 locationInCollection: longTapGestureRecognizer.location(in: self),
										 previousLocationInCollection: previousLocation,
										 index: draggedCellIndex)
		context.oldCellFrame = draggedCellOldFrame
		context.lastReorderedIndex = lastReorderedIndex
		bringSubviewToFront(draggedCell)
		for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
			if cell === draggedCell { continue }
			if cell.frame.intersects(draggedCell.frame) {
				guard let index = (flattenedProvider as? FlattenedProvider)?.indexPath(index).1 else { return }
				let intersectionFrame = cell.frame.intersection(draggedCell.frame)
				let intersectionSquare = intersectionFrame.size.square
				if  intersectionSquare > (context.intersectionFrame?.size.square ?? 0) {
					context.intersectsCell = CellPath(cell: cell, index: index)
					context.intersectionFrame = intersectionFrame
				}
			}
		}
	}
	
	func removeAllLongPressRecognizers() {
		gestureRecognizers?.forEach { rec in
			guard rec.className.contains("LongPress") ||
					rec.className.contains("UIScrollViewDelayedTouchesBegan") else { return }
			removeGestureRecognizer(rec)
		}
	}
	
	private func tap(location: CGPoint) {
		for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
			if cell.point(inside: location, with: nil) {
				flattenedProvider.didTap(view: cell, at: index)
				return
			}
		}
	}
	
	
	/// Works only with formview with one section!!
	/// - Parameter location: location
	/// - Returns: index
	public func findNearLowIndex(at location: CGPoint) -> Int? {
		guard (provider as? FibGridHeaderProvider)?.sections.count == 1 else { return nil }
		var nearestIndex: Int?
		let location = CGPoint(x: location.x, y: location.y + contentOffset.y)
		let cellsAndIndices = zip(visibleCells, visibleIndexes)
		for (cell, index) in cellsAndIndices {
			if cell.frame.contains(location) {
				if location.y > cell.center.y {
					nearestIndex = index
				} else {
					nearestIndex = index - 1
				}
				break
			} else {
				if let nearestI = nearestIndex,
				   let possibleNearestCell = visibleCells.get(nearestI) {
					if possibleNearestCell.center.distance(location) > cell.center.distance(location) {
						nearestIndex = index
					}
				} else {
					nearestIndex = index
				}
			}
		}
		return nearestIndex
	}
	
	@IBAction func tap(sender: UITapGestureRecognizer) {
		for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
			if cell.point(inside: sender.location(in: cell), with: nil) {
				if let cell = cell as? SwipeControlledView, cell.isSwipeOpen {
					cell.animateSwipe(direction: .right, isOpen: false, swipeWidth: nil, initialVel: nil, completion: nil)
					return
				}
				flattenedProvider.didTap(view: cell, at: index)
				return
			}
		}
		let superCollectionView: FibGrid? = findViewInSuperViews()
		if let superCollectionView = superCollectionView {
			superCollectionView.tap(sender: tapGestureRecognizer)
		}
	}
	
	@IBAction func longTap(gesture: UILongPressGestureRecognizer) {
		guard let provider = (provider as? ItemProvider), provider.canReorderItems == true else { return }
		if gesture.state == .began {
			displayLink.add(to: .main, forMode: .default)
			becomeFirstResponder()
			for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
				if cell.point(inside: gesture.location(in: cell), with: nil) {
					feedback.impactOccurred()
					draggedCellOldFrame = cell.frame
					draggedCellInitialFrame = draggedCellOldFrame
					bringSubviewToFront(cell)
					cell.alpha = 0.7
					self.oldDataArray = (cell.fb_provider as? FibGridProvider)?.dataSource.data ?? []
					UIView.animate(withDuration: 0.2) {
						cell.center.x = gesture.location(in: self).x
					}
					let identifier = flattenedProvider.identifier(at: index)
					let interIndexPath = (flattenedProvider as? FlattenedProvider)?.indexPath(index)
					let interProviderIndex = interIndexPath?.1 ?? index
					self.draggedCellInitialIndex = interProviderIndex
					self.draggedSectionIndex = (interIndexPath?.0 ?? 1) - 1
					let context = LongGestureContext(view: cell,
													 collectionView: self,
													 locationInCollection: gesture.location(in: self),
													 previousLocationInCollection: previousLocation,
													 index: interProviderIndex)
					flattenedProvider.didBeginLongTapWithProvider(context: context)
					dragProvider = (cell.fb_provider as? ItemProvider)
					dragProvider?.didBeginLongTapWithProvider(context: context)
					let isVerticalScroll = (dragProvider as? GridSection)?.scrollDirection == .vertical
					UIView.animate(withDuration: 0.2) {
						if isVerticalScroll {
							cell.center.y = gesture.location(in: self).y
						} else {
							cell.center.x = gesture.location(in: self).x
						}
					}
					draggedCell = CellPath(cell: cell,
										   index: interProviderIndex,
										   identifier: identifier)
					identifierCache[index] = identifier
					isInProcessDragging = true
				}
			}
		} else {
			guard let draggedCell = draggedCell?.cell,
				  let draggedCellIndex = self.draggedCell?.index else { return }
			let context = LongGestureContext(view: draggedCell,
											 collectionView: self,
											 locationInCollection: gesture.location(in: self),
											 previousLocationInCollection: previousLocation,
											 index: draggedCellIndex)
			context.oldCellFrame = draggedCellOldFrame
			context.lastReorderedIndex = lastReorderedIndex
			for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
				if cell === draggedCell { continue }
				if cell.frame.intersects(draggedCell.frame) {
					guard let index = (flattenedProvider as? FlattenedProvider)?.indexPath(index).1 else { return }
					let intersectionFrame = cell.frame.intersection(draggedCell.frame)
					let intersectionSquare = intersectionFrame.size.square
					if  intersectionSquare > (context.intersectionFrame?.size.square ?? 0) {
						context.intersectsCell = CellPath(cell: cell, index: index)
						context.intersectionFrame = intersectionFrame
					}
				}
			}
			switch gesture.state {
				case .changed:
					bringSubviewToFront(draggedCell)
				case .cancelled:
					clearDrag {[weak self] in
						guard let self = self else { return }
						self.dragProvider?.didLongTapCancelled(context: context)
					}
				case .ended:
					clearDrag {[weak self] in
						guard let self = self else { return }
						self.dragProvider?.didLongTapEnded(context: context)
					}
				default:
					break
			}
		}
		previousLocation = gesture.location(in: self)
	}
	
	private func clearDrag(closure: (() -> Void)?) {
		displayLink.remove(from: .main, forMode: .default)
		self.resignFirstResponder()
		self.isInProcessDragging = false
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			(self.draggedCell?.cell.fb_provider as? FibGridProvider)?.dataSource.data = self.oldDataArray
			closure?()
			self.draggedCell?.cell.alpha = 1
			self.feedback.impactOccurred()
			self.draggedCell?.cell.removeFromSuperview()
			self.draggedCell = nil
			self.draggedCellOldFrame = nil
			self.draggedSectionIndex = nil
			self.previousLocation = nil
			self.dragProvider = nil
			self.lastReorderedIndex = nil
			self.dragProvider = nil
			self.setNeedsReload()
		}
	}
}
