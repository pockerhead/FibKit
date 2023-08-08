//
//  CollectionKit.swift
//  CollectionKit
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//
import UIKit

// swiftlint:disable all
open class CollectionView: UIScrollView {
	
	public static var defaultCustomScrollClosure: ((CGPoint, CGFloat) -> Void)?
	
	open var provider: Provider? {
		didSet { setNeedsReload() }
	}
	
	public var animator: Animator = AnimatedReloadAnimator() {
		didSet { setNeedsReload() }
	}
	
	public var needExpandedHeight = false
	public var needExpandedWidth = false
	
	public private(set) var reloadCount = 0
	public private(set) var needsReload = true
	public private(set) var needsInvalidateLayout = false
	public private(set) var isLoadingCell = false
	public private(set) var isReloading = false
	public var isChangingPage = false
	public var deletePageDirection: AnimatedReloadAnimator.PageDirection?
	public var hasReloaded: Bool { return reloadCount > 0 }
	private var feedback = UIImpactFeedbackGenerator(style: .medium)
	
	public var additionalHeaderInset: CGFloat?
	lazy var tapGestureRecognizer: UITapGestureRecognizer = {
		let tap = UITapGestureRecognizer()
		tap.addTarget(self, action: #selector(tap(sender:)))
		addGestureRecognizer(tap)
		return tap
	}()
	
	lazy var longTapGestureRecognizer: UILongPressGestureRecognizer = {
		let tap = UILongPressGestureRecognizer()
		tap.addTarget(self, action: #selector(longTap(gesture:)))
		return tap
	}()
	
	lazy var displayLink: CADisplayLink = {
		let link = CADisplayLink(target: self, selector: #selector(scrollWhenDragIfNeeded))
		return link
	}()
	
	// visible identifiers for cells on screen
	public private(set) var visibleIndexes: [Int] = []
	public private(set) var visibleCells: [UIView] = []
	public private(set) var visibleFrames: [CGRect] = []
	public private(set) var visibleIdentifiers: [String] = []
	
	var draggedCell: CellPath?
	var draggedCellOldFrame: CGRect?
	var draggedCellInitialFrame: CGRect?
	
	var draggedSectionIndex: Int?
	var previousLocation: CGPoint?
	var dragProvider: ItemProvider?
	var lastReorderedIndex: Int?
	var isInProcessDragging: Bool = false
	
	struct CellPath {
		var cell: UIView
		var index: Int
		var identifier: String?
	}
	
	public var loadCellsInBounds: Bool = true
	
	public private(set) var lastLoadBounds: CGRect = .zero
	public private(set) var contentOffsetChange: CGPoint = .zero
	
	lazy var flattenedProvider: ItemProvider = EmptyCollectionProvider()
	var identifierCache: [Int: String] = [:]
	
	public convenience init(provider: Provider) {
		self.init()
		commonInit()
		self.provider = provider
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	func commonInit() {
		CollectionViewManager.shared.register(collectionView: self)
		_ = tapGestureRecognizer
		_ = longTapGestureRecognizer
	}
	
	@objc func scrollWhenDragIfNeeded() {
		guard isInProcessDragging, let cell = draggedCell?.cell,
			  let selfWindowFrame = superview?.convert(frame, to: nil),
			  let cellWindowFrame = cell.superview?.convert(cell.frame, to: nil),
			  let provider = dragProvider as? FibGridProvider else { return }
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
				context.intersectsCell = CellPath(cell: cell, index: index)
			}
		}
		let newOldRect = dragProvider?.didLongTapContinue(context: context)
		if let lnewOldRect = newOldRect {
			feedback.impactOccurred()
			draggedCellOldFrame = lnewOldRect
			if lnewOldRect == draggedCellInitialFrame ?? .zero {
				lastReorderedIndex = context.index
			} else {
				lastReorderedIndex = context.intersectsCell?.index
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
		let superCollectionView: CollectionView? = findViewInSuperViews()
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
					UIView.animate(withDuration: 0.2) {
						cell.center.x = gesture.location(in: self).x
					}
					let identifier = flattenedProvider.identifier(at: index)
					let interIndexPath = (flattenedProvider as? FlattenedProvider)?.indexPath(index)
					let interProviderIndex = interIndexPath?.1 ?? index
					self.draggedSectionIndex = (interIndexPath?.0 ?? 1) - 1
					let context = LongGestureContext(view: cell,
													 collectionView: self,
													 locationInCollection: gesture.location(in: self),
													 previousLocationInCollection: previousLocation,
													 index: interProviderIndex)
					flattenedProvider.didBeginLongTapWithProvider(context: context)
					if let dragProvider = context.dragProvider as? FibGridHeaderProvider,
					   interProviderIndex == 0,
					   dragProvider.sections.have(self.draggedSectionIndex ?? 0) {
						self.dragProvider = dragProvider.sections[self.draggedSectionIndex ?? 0] as? ItemProvider
					} else {
						dragProvider = context.dragProvider
					}
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
					context.intersectsCell = CellPath(cell: cell, index: index)
				}
			}
			switch gesture.state {
			case .changed:
				let newOldRect = dragProvider?.didLongTapContinue(context: context)
				if let lnewOldRect = newOldRect {
					draggedCellOldFrame = lnewOldRect
					feedback.impactOccurred()
					if lnewOldRect == draggedCellInitialFrame ?? .zero {
						lastReorderedIndex = context.index
					} else {
						if lastReorderedIndex == context.intersectsCell?.index {
							let isVerticalScroll = (dragProvider as? LayoutableProvider)?.layout is FlowLayout
							let draggedToBegin: Bool
							if isVerticalScroll {
								draggedToBegin = context.locationInCollection.y < previousLocation?.y ?? 0
							} else {
								draggedToBegin = context.locationInCollection.x < previousLocation?.x ?? 0
							}
							if draggedToBegin {
								lastReorderedIndex = ((context.intersectsCell?.index ?? 0) - 1)
							} else {
								lastReorderedIndex = ((context.intersectsCell?.index ?? 0) + 1)
							}
						} else {
							lastReorderedIndex = context.intersectsCell?.index
						}
					}
				}
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
			closure?()
			withFibSpringAnimation {[weak self] in
				guard let self = self else { return }
				self.draggedCell?.cell.frame = self.draggedCellOldFrame ?? .zero
				self.draggedCell?.cell.alpha = 1
			} completion: { _ in
				self.feedback.impactOccurred()
				self.draggedCell?.cell.removeFromSuperview()
				self.draggedCell = nil
				self.draggedCellOldFrame = nil
				self.draggedSectionIndex = nil
				self.previousLocation = nil
				self.dragProvider = nil
				self.lastReorderedIndex = nil
				self.dragProvider = nil
				DispatchQueue.main.async {[weak self] in
					guard let self = self else { return }
					self.reloadData()
				}
			}
		}
	}
	
	var reloadTask: DispatchWorkItem?
	
	func updateLayoutSubviewsTask() {
		reloadTask?.cancel()
		reloadTask = nil
		let blockTask = DispatchWorkItem.init(block: {[weak self] in
			guard let self = self else { return }
			self._reloadOrInvalidateLayout()
		})
		self.reloadTask = blockTask
		delay(cyclesCount: 4) { [weak blockTask] in
			if let blockTask = blockTask {
				blockTask.perform()
			}
		}
	}
	
	func _asyncLayoutSubviews() {
		if needsReload {
			updateLayoutSubviewsTask()
		} else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
			updateLayoutSubviewsTask()
		} else if bounds != lastLoadBounds {
			loadCells()
		}
	}
	
	func _layoutSubviews() {
		if needsReload {
			reloadData()
		} else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
			invalidateLayout()
		} else if bounds != lastLoadBounds {
			loadCells()
		}
	}
	
	func _reloadOrInvalidateLayout() {
		if needsReload {
			reloadData()
		} else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
			invalidateLayout()
		}
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		if let self = self as? FibGrid, self.isAsync {
			_asyncLayoutSubviews()
		} else {
			_layoutSubviews()
		}
	}
	
	public func setNeedsReload() {
		mainOrSync {[self] in
			needsReload = true
			setNeedsLayout()
		}
	}
	
	public func setNeedsInvalidateLayout() {
		needsInvalidateLayout = true
		setNeedsLayout()
	}
	
	public func invalidateLayout() {
		guard !isLoadingCell && !isReloading && hasReloaded else { return }
		flattenedProvider.layout(collectionSize: innerSize)
		contentSize = flattenedProvider.contentSize
		needsInvalidateLayout = false
		loadCells()
	}
	
	/*
	 * Update visibleCells & visibleIndexes according to scrollView's visibleFrame
	 * load cells that move into the visibleFrame and recycles them when
	 * they move out of the visibleFrame.
	 */
	func loadCells() {
		guard !isLoadingCell && !isReloading && hasReloaded else { return }
		isLoadingCell = true
		
		_loadCells(forceReload: false)
		if !isInProcessDragging {
			for (cell, index) in zip(visibleCells, visibleIndexes) {
				let animator = cell.currentCollectionAnimator ?? self.animator
				animator.update(collectionView: self, view: cell, at: index, frame: flattenedProvider.frame(at: index))
			}
		}
		
		lastLoadBounds = bounds
		isLoadingCell = false
	}
	
	lazy var collectionViewLayoutQueue = DispatchQueue(label: "ru.ditbrains.collectionViewLayoutQueue_\(ObjectIdentifier(self))", qos: .userInitiated)
	
	// reload all frames. will automatically diff insertion & deletion
	public func reloadData(contentOffsetAdjustFn: ((CGSize) -> CGPoint)? = nil) {
		guard !isReloading && !isInProcessDragging else { return }
		provider?.willReload()
		if (provider as? ItemProvider)?.canReorderItems == true {
			addGestureRecognizer(longTapGestureRecognizer)
		} else {
			removeGestureRecognizer(longTapGestureRecognizer)
		}
		flattenedProvider = (provider ?? EmptyCollectionProvider()).flattenedProvider()
		isReloading = true
		let size = self.innerSize
		let needTestAsyncFibGrid = true
		if needTestAsyncFibGrid == false,
			let self = self as? FibGrid,
			self.isAsync {
			collectionViewLayoutQueue.async {
				self.flattenedProvider.layout(collectionSize: size)
				delay {
					self.reloadAfterLayout(contentOffsetAdjustFn: contentOffsetAdjustFn)
				}
			}
		} else {
			self.flattenedProvider.layout(collectionSize: size)
			self.reloadAfterLayout(contentOffsetAdjustFn: contentOffsetAdjustFn)
		}
	}
	
	private func reloadAfterLayout(contentOffsetAdjustFn: ((CGSize) -> CGPoint)? = nil) {
		let oldContentOffset = self.contentOffset
		self.contentSize = self.flattenedProvider.contentSize
		if let offset = contentOffsetAdjustFn?(self.contentSize) {
			self.contentOffset = offset
		}
		self.contentOffsetChange = self.contentOffset - oldContentOffset
		
		let oldVisibleCells = Set(self.visibleCells)
		self._loadCells(forceReload: true)
		
		for (cell, index) in zip(self.visibleCells, self.visibleIndexes) {
			cell.currentCollectionAnimator = cell.collectionAnimator ?? self.flattenedProvider.animator(at: index)
			let animator = cell.currentCollectionAnimator ?? self.animator
			if oldVisibleCells.contains(cell) {
				// cell was on screen before reload, need to update the view.
				self.insertSubview(cell, at: index)
				self.flattenedProvider.update(view: cell, at: index)
				animator.shift(collectionView: self, delta: self.contentOffsetChange, view: cell,
							   at: index, frame: self.flattenedProvider.frame(at: index))
			}
			animator.update(collectionView: self, view: cell,
							at: index, frame: self.flattenedProvider.frame(at: index))
		}
		
		self.lastLoadBounds = self.bounds
		self.needsInvalidateLayout = false
		self.needsReload = false
		self.reloadCount += 1
		self.isReloading = false
		self.isChangingPage = false
		self.flattenedProvider.didReload()
	}
	
	private func _loadCells(forceReload: Bool) {
		let passedRect = loadCellsInBounds ? visibleFrame : visibleFrameLessInset
		let newIndexes = flattenedProvider.visibleIndexes(visibleFrame: visibleFrame, visibleFrameLessInset: visibleFrameLessInset)
		
		
		// optimization: we assume that corresponding identifier for each index doesnt change unless forceReload is true.
		guard forceReload ||
				newIndexes.last != visibleIndexes.last ||
				newIndexes != visibleIndexes else {
			let visibleFrameLessInset = visibleFrameLessInset
			collectionViewLayoutQueue.async {[weak self] in
				guard let self = self else { return }
				for (cell, frame) in zip(visibleCells, visibleFrames) {
					appearSubviewIfNeeded(cell,
										  cellFrame: frame,
										  visibleFrameLessInset: visibleFrameLessInset)
				}
			}
			
			return
		}
		
		
		var existingIdentifierToCellMap: [String: UIView] = [:]
		
		// during reloadData we clear all cache
		if forceReload {
			identifierCache.removeAll()
		}
		
		var newIdentifierSet = Set<String>()
		let newIdentifiers: [String] = newIndexes.map { index in
			if let identifier = identifierCache[index] {
				newIdentifierSet.insert(identifier)
				return identifier
			} else {
				let identifier = flattenedProvider.identifier(at: index)
				// avoid identifier collision
				var finalIdentifier = identifier
				var count = 1
				while newIdentifierSet.contains(finalIdentifier) {
					finalIdentifier = identifier + "(\(count))"
					count += 1
				}
				newIdentifierSet.insert(finalIdentifier)
				identifierCache[index] = finalIdentifier
				return finalIdentifier
			}
		}.compactMap({ $0 })
		
		// 1st pass, delete all removed cells
		for (index, identifier) in visibleIdentifiers.enumerated() {
			let cell = visibleCells[index]
			if !newIdentifierSet.contains(identifier) && cell !== draggedCell?.cell {
//				if let cell = cell as? FormViewAppearable {
//					cell.onDissappear(with: self as? FibGrid)
//				}
				cell.isAppearedOnFibGrid = false
				if (cell.currentCollectionAnimator as? AnimatedReloadAnimator)?.pageDirection != nil {
					(cell.currentCollectionAnimator as? AnimatedReloadAnimator)?.pageDirection = deletePageDirection
				}
				(cell.currentCollectionAnimator ?? animator)?.delete(collectionView: self, view: cell)
			} else {
				existingIdentifierToCellMap[identifier] = cell
			}
		}
		
		// 2nd pass, insert new views
		let newCells: [UIView] = zip(newIdentifiers, newIndexes).map { identifier, index in
			if let existingCell = existingIdentifierToCellMap[identifier] {
				return existingCell
			} else {
				let cell = _generateCell(index: index)
//				if let cell = cell as? FormViewAppearable {
//					cell.onAppear(with: self as? FibGrid)
//				}
				if subviews.get(index) !== cell {
					insertSubview(cell, at: index)
				}
				return cell
			}
		}
		
		if !newCells.isEmpty && (visibleCells.filter{type(of: $0) === type(of: newCells.first!)}).count == 0 {
			newCells.first?.reuseManager?.prepareReuseIfNeeded(type: type(of: newCells.first!))
		}
		newCells.map({ $0 as? SwipeControlledView }).compactMap({ $0 }).forEach({ cell in
			if cell.haveSwipeAction && cell.isSwipeOpen && !cell.isAnimating {
				cell.animateSwipe(direction: .right, isOpen: false, swipeWidth: nil, initialVel: nil, completion: nil)
			}
		})
		visibleIndexes = newIndexes
		visibleIdentifiers = newIdentifiers
		visibleCells = newCells
		visibleFrames = []
		for (cell, index) in zip(visibleCells, visibleIndexes) {
			visibleFrames.append(cell.frame)
			appearSubviewIfNeeded(cell, cellFrame: cell.frame, visibleFrameLessInset: visibleFrameLessInset)
			insertSubview(cell, at: index)
		}
	}
	
	private func appearSubviewIfNeeded(_ cell: UIView,
									   cellFrame: CGRect,
									   visibleFrameLessInset: CGRect) {
		if let self = self as? FibGrid,
		   let cell = cell as? FormViewAppearable {
			if cellFrame.intersects(visibleFrameLessInset),
				(cell.isAppearedOnFibGrid ?? false) == false {
				mainOrSync {
					cell.isAppearedOnFibGrid = true
					cell.onAppear(with: self)
				}
			} else if !cellFrame.intersects(visibleFrameLessInset),
					  cell.isAppearedOnFibGrid == true {
				mainOrSync {
					cell.isAppearedOnFibGrid = false
					cell.onDissappear(with: self)
				}
			}
		}
	}
	
	private func _generateCell(index: Int) -> UIView {
		let cell = flattenedProvider.view(at: index)
		let frame = flattenedProvider.frame(at: index)
		cell.bounds.size = frame.bounds.size
		cell.center = frame.center
		cell.currentCollectionAnimator = cell.collectionAnimator ?? flattenedProvider.animator(at: index)
		let animator = cell.currentCollectionAnimator ?? self.animator
		let identifier = flattenedProvider.identifier(at: index)
		if isInProcessDragging,
		   let draggedIdent = draggedCell?.identifier, draggedIdent == identifier {
			cell.alpha = 0
			return cell
		}
		animator.insert(collectionView: self, view: cell, at: index, frame: flattenedProvider.frame(at: index))
		return cell
	}
}

extension CollectionView {
	public func indexForCell(at point: CGPoint) -> Int? {
		for (index, cell) in zip(visibleIndexes, visibleCells) {
			if cell.point(inside: cell.convert(point, from: self), with: nil) {
				return index
			}
		}
		return nil
	}
	
	public func index(for cell: UIView) -> Int? {
		if let position = visibleCells.firstIndex(of: cell) {
			return visibleIndexes[position]
		}
		return nil
	}
	
	public func cell(at index: Int) -> UIView? {
		if let position = visibleIndexes.firstIndex(of: index) {
			return visibleCells[position]
		}
		return nil
	}
}

extension CollectionView {
	
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
	
	public func scroll(to section: GridSection, animated: Bool) throws {
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(CollectionKitError.unableToScroll)
		}
		guard let index = provider.sections.firstIndex(where: { $0.identifier == section.identifier }) else {
			debugPrint("Incorrect section index at \(section.identifier)")
			throw(CollectionKitError.unableToScroll)
		}
		try scroll(to: IndexPath(row: 0, section: index), animated: animated)
	}
	
	public func scroll(to sectionId: String, animated: Bool) throws {
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(CollectionKitError.unableToScroll)
		}
		guard let index = provider.sections.firstIndex(where: { $0.identifier == sectionId }) else {
			debugPrint("Not found section with id \(sectionId)")
			throw(CollectionKitError.unableToScroll)
		}
		try scroll(to: IndexPath(row: 0, section: index), animated: animated)
	}
	
	@discardableResult
	public func scroll(
		to indexPath: IndexPath,
		animated: Bool,
		considerNearbyItems: Bool = false,
		bounce: CGFloat = 0,
		customScroll: ((CGPoint, CGFloat) -> Void)? = CollectionView.defaultCustomScrollClosure
	) throws -> CGPoint {
		var indexPath = indexPath
		let optProvider = self.provider as? SectionProvider
		guard let provider = optProvider else {
			debugPrint("Incorrect provider \(String(describing: optProvider))")
			throw(CollectionKitError.unableToScroll)
		}
		let optInner = provider.sections.get(indexPath.section) as? (Provider & LayoutableProvider)
		guard let innerProvider = optInner else {
			debugPrint("Incorrect inner provider \(String(describing: optInner)) in \(provider) provider")
			throw(CollectionKitError.unableToScroll)
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
				throw(CollectionKitError.unableToScroll)
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
					throw(CollectionKitError.unableToScroll)
				}
				targetPoint.x -= (visibleFrame.width - itemFrame.width)
				targetPoint.x += nextItemFrame.width
				targetPoint.x = max(targetPoint.x, 0)
			} else if absoluteItemFrame.center.x - 1 < visibleFrame.width / 2 {
				let previousItemFrame = innerProvider.frame(at: indexPath.item - 1)
				guard previousItemFrame.minX < visibleFrame.minX else {
					throw(CollectionKitError.unableToScroll)
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
		if animated {
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

public enum CollectionKitError: Error {
	case unableToScroll
	
}

extension UIView {
	
	func findViewInSuperViews<T: UIView>() -> T? {
		if superview == nil { return nil }
		if let s = superview as? T {
			return s
		} else if let s: T = superview?.findViewInSuperViews() {
			return s
		} else {
			return nil
		}
	}
}
