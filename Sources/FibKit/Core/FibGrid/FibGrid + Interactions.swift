//
//  FibGrid + Interactions.swift
//  
//
//  Created by Денис Садаков on 17.08.2023.
//

import Foundation

public struct ReorderContext {
	
	public enum ReorderType {
		case immediateReload
		case defferedReload
	}
	
	public init(
		reorderType: ReorderType = .immediateReload,
		didBeginReorderSession: (() -> Void)? = nil,
		didEndReorderSession: @escaping ((Int, Int) -> Void)
	) {
		self.reorderType = reorderType
		self.didEndReorderSession = didEndReorderSession
		self.didBeginReorderSession = didBeginReorderSession
	}
	
	public private(set) var reorderType: ReorderType
	public private(set) var didEndReorderSession: ((Int, Int) -> Void)
	public private(set) var didBeginReorderSession: (() -> Void)?
}

extension FibGrid {
	@objc func scrollWhenDragIfNeeded() {
		guard isInProcessDragging, let cell = draggedCell?.cell,
			  let selfWindowFrame = superview?.convert(getCurrentFrameLessInset(), to: nil),
			  let cellWindowFrame = cell.superview?.convert(cell.frame, to: nil),
			  let provider = dragProvider as? FibGridProvider else { return }
		bringSubviewToFront(cell)
		let maxManualOffset: CGFloat = 5
		let maxNegativeManualOffset: CGFloat = -5
		let xCellOffsetMin: CGFloat? = (cellWindowFrame.minX - selfWindowFrame.minX < 0) ? (cellWindowFrame.minX - selfWindowFrame.minX) : nil
		let xCellOffsetMax: CGFloat? = (cellWindowFrame.maxX - selfWindowFrame.maxX > 0) ? (cellWindowFrame.maxX - selfWindowFrame.maxX) : nil
		
		let yCellOffsetMin: CGFloat? = (cellWindowFrame.minY - selfWindowFrame.minY < 0) ? (cellWindowFrame.minY - selfWindowFrame.minY) : nil
		let yCellOffsetMax: CGFloat? = (cellWindowFrame.maxY - selfWindowFrame.maxY > 0) ? (cellWindowFrame.maxY - selfWindowFrame.maxY) : nil
		
		let minContentOffset = CGPoint(x: -adjustedContentInset.right, y: -adjustedContentInset.top)
		let maxContentOffset = CGPoint(x: contentSize.width + adjustedContentInset.left - bounds.width, y: contentSize.height + adjustedContentInset.bottom - bounds.height)
		
		if (xCellOffsetMin != nil && contentOffset.x > minContentOffset.x)
			|| (yCellOffsetMin != nil && contentOffset.y > minContentOffset.y)
			|| (xCellOffsetMax != nil && contentOffset.x < maxContentOffset.x)
			|| (yCellOffsetMax != nil && contentOffset.y < maxContentOffset.y) {
			var x = contentOffset.x
			var y = contentOffset.y
			let offsetY = (yCellOffsetMin ?? yCellOffsetMax ?? 0).clamp(maxNegativeManualOffset, maxManualOffset)
			let offsetX = (xCellOffsetMin ?? xCellOffsetMax ?? 0).clamp(maxNegativeManualOffset, maxManualOffset)
			y = (y + offsetY).clamp(minContentOffset.y,	maxContentOffset.y)
			x = (x + offsetX).clamp(minContentOffset.x, maxContentOffset.x)
			let increasedContentOffset = CGPoint(x: x, y: y)
			if increasedContentOffset != contentOffset {
				setContentOffset(increasedContentOffset, animated: false)
				longTap(gesture: self.longTapGestureRecognizer)
			}
		}
		self.draggedCell?.cell.center = self.longTapGestureRecognizer.location(in: self)
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
			displayLink.add(to: .main, forMode: .common)
			becomeFirstResponder()
			for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
				guard cell.point(inside: gesture.location(in: cell), with: nil),
					  !(cell is FibSectionBackgroundView),
					  (cell.fb_provider as? ItemProvider)?.canReorderItems == true,
					  ((cell as? DragControlledView)?.canStartDragSession ?? true)
				else { continue }
				let identifier = flattenedProvider.identifier(at: index)
				let interIndexPath = (flattenedProvider as? FlattenedProvider)?.indexPath(index)
				var interProviderIndex = interIndexPath?.1 ?? index
				if (cell.fb_provider as? FibGridProvider)?.backgroundViewModel != nil {
					interProviderIndex -= 1
				}
				let context = LongGestureContext(view: cell,
												 collectionView: self,
												 locationInCollection: gesture.location(in: self),
												 previousLocationInCollection: previousLocation,
												 index: interProviderIndex)
				flattenedProvider.didBeginLongTapWithProvider(context: context)
				dragProvider = (cell.fb_provider as? ItemProvider)
				dragProvider?.didBeginLongTapWithProvider(context: context)
				guard ((cell as? DragControlledView)?.canBeReordered ?? true) else {
					continue
				}
				draggedCellOldFrame = cell.frame
				draggedCellInitialFrame = draggedCellOldFrame
				bringSubviewToFront(cell)
				if let cell = cell as? (DragControlledView & UIView) {
					if cell.needAlphaChangeOnDrag {
						cell.alpha = 0.7
					}
				} else {
					cell.alpha = 0.7
				}
				self.oldDataArray = (cell.fb_provider as? FibGridProvider)?.dataSource.data ?? []
				UIView.animate(withDuration: 0.2) {
					cell.center = gesture.location(in: self)
				}
				self.draggedCellInitialIndex = interProviderIndex
				self.draggedSectionIndex = (interIndexPath?.0 ?? 1) - 1
				draggedCell = CellPath(cell: cell,
									   index: interProviderIndex,
									   identifier: identifier)
				identifierCache[index] = identifier
				isInProcessDragging = true
				(cell as? DragControlledView)?.onDragBegin()
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
				if cell === draggedCell || cell is FibSectionBackgroundView { continue }
				if cell.frame.intersects(draggedCell.frame) {
					guard (cell.fb_provider as? AnyObject) === (draggedCell.fb_provider as? AnyObject), ((cell as? DragControlledView)?.canBeReordered ?? true) else { continue }
					var index = (flattenedProvider as? FlattenedProvider)?.indexPath(index).1 ?? index
					if (cell.fb_provider as? FibGridProvider)?.backgroundViewModel != nil {
						index -= 1
					}
					let draggedCenter = draggedCell.frame.center
					let intersectionCenter = cell.frame.center
					let intersectionVector = CGVector(
						dx: draggedCenter.x - intersectionCenter.x,
						dy: draggedCenter.y - intersectionCenter.y
					)
					let intersectionVectorLength = abs(intersectionVector.length)
					let intersectionFrame = cell.frame.intersection(draggedCell.frame)
					let intersectionSquare = intersectionFrame.size.square
					if  intersectionVectorLength < (context.intersectionVectorLength ?? .greatestFiniteMagnitude),
						intersectionSquare > (context.intersectionFrame?.size.square ?? 0)
					{
						context.intersectsCell = CellPath(cell: cell, index: index)
						context.intersectionFrame = intersectionFrame
						context.intersectionVectorLength = intersectionVectorLength
					}
				}
			}
			switch gesture.state {
			case .changed:
				bringSubviewToFront(draggedCell)
				_ = self.dragProvider?.didLongTapContinue(context: context)
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
	
	internal func clearDrag(closure: (() -> Void)?) {
		displayLink.remove(from: .main, forMode: .common)
		self.resignFirstResponder()
		self.isInProcessDragging = false
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			(self.draggedCell?.cell.fb_provider as? FibGridProvider)?.dataSource.data = self.oldDataArray
			closure?()
			if let cell = self.draggedCell?.cell as? (DragControlledView & UIView) {
				if cell.needAlphaChangeOnDrag {
					cell.alpha = 1
				}
			} else {
				self.draggedCell?.cell.alpha = 1
			}
			(self.draggedCell?.cell as? DragControlledView)?.onDragEnd()
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

extension CGVector {
	
	var length: Double {
		sqrt(pow(dx, 2) + pow(dy, 2))
	}
}
