//
//  CollectionKit.swift
//  CollectionKit
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//
@_exported import UIKit
import SwiftUI
import Combine
import Threading
// swiftlint:disable all
final public class FibGrid: UIScrollView {
	
	public enum ScrollDirection {
		case vertical
		case horizontal
		case unlocked
	}
	struct CellPath {
		var cell: UIView
		var index: Int
		var identifier: String?
	}
	public static var defaultCustomScrollClosure: ((CGPoint, CGFloat) -> Void)?
	public var animator: Animator = AnimatedReloadAnimator() {didSet { setNeedsReload() }}
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
	private(set) var feedback = UIImpactFeedbackGenerator(style: .medium)
	public var additionalHeaderInset: CGFloat?
	// visible identifiers for cells on screen
	public private(set) var visibleIndexes: [Int] = []
	public private(set) var visibleCells: [UIView] = []
	public private(set) var visibleFrames: [CGRect] = []
	public private(set) var visibleIdentifiers: [String] = []
	var draggedCell: CellPath?
	var draggedCellOldFrame: CGRect?
	var draggedCellInitialFrame: CGRect?
	var draggedCellInitialIndex: Int?
	var draggedSectionIndex: Int?
	var previousLocation: CGPoint?
	var dragProvider: ItemProvider?
	var lastReorderedIndex: Int?
	var isInProcessDragging: Bool = false
	public var loadCellsInBounds: Bool = true
	public private(set) var lastLoadBounds: CGRect = .zero
	public private(set) var contentOffsetChange: CGPoint = .zero
	var identifierCache: [Int: String] = [:]
	var cancellables = Set<AnyCancellable>()
	weak var scrollToIndexPub: PassthroughSubject<IndexPath, Never>?
	var hidingScrollIndicators: (horizontal: Bool, vertical: Bool) = (false, false)
	public var scrollDirection: ScrollDirection = .vertical
	/// closure that called when all sections is reloaded, view layouts and fitted contentSize fully
	private var didReloadClosure: (() -> Void)?
	public var overrideRootLayout: Layout?
	public var forcedProviderUpdate: Bool = false
	/// need animated reload
	public var animated: Bool = true
	public var isEmbedCollection = false
	var oldDataArray: [ViewModelWithViewClass?] = []
	var reloadTask: DispatchWorkItem?
	public var isAsync = true
	/// cached structs that contains cached sizes of cells, needs for optimisation
	public var provider: Provider? {
		didSet {
			if let id = provider?.identifier {
				GridsReuseManager.shared.grids[id] = .init(ref: self)
			}
			if let provider = provider as? SectionStack {
				provider.collectionView = self
				self.scrollDirection = provider.scrollDirection
				provider.bindReload {[weak self] in
					self?.didReloadClosure?()
				}
			}
			if let provider = provider as? GridSection {
				provider.collectionView = self
				self.scrollDirection = provider.scrollDirection
				provider.bindReload {[weak self] in
					self?.didReloadClosure?()
				}
			}
			setNeedsReload()
			reloadSections(oldValue)
		}
	}
	lazy var flattenedProvider: ItemProvider = EmptyCollectionProvider()
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
	lazy var collectionViewLayoutQueue = DispatchQueue(label: "com.pockerhead.collectionViewLayoutQueue_\(ObjectIdentifier(self))", qos: .userInitiated)
	public weak var swiftUIUIView: FibGrid?
	/// optional view that contains formView
	weak var containedRootView: FibControllerRootView?
	
	
	public convenience init(provider: Provider?,
							scrollToIndexPub: PassthroughSubject<IndexPath, Never>? = nil,
							horizontal: Bool = false,
							vertical: Bool = false) {
		self.init()
		self.provider = provider
		self.scrollToIndexPub = scrollToIndexPub
		self.hidingScrollIndicators = (horizontal, vertical)
		self.showsVerticalScrollIndicator = !vertical
		self.showsHorizontalScrollIndicator = !horizontal
	}
	
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
	
	private func commonInit() {
		delaysContentTouches = false
		CollectionViewManager.shared.register(collectionView: self)
		_ = tapGestureRecognizer
		_ = longTapGestureRecognizer
	}
	/// view that fills view and displayed when sections is empty
	//    var emptyView = DITCore.InfoMessageView()
	
	/// display empty view
	/// - Parameters:
	///   - model: empty view ViewModel
	///   - height: optional height of empty view
	///   - animated: needs animate
	func displayEmptyView(model: ViewModelWithViewClass, height: CGFloat? = nil, animated: Bool) {
		guard let view = model.getView() else { return }
		let heightStrategy: SimpleViewSizeSource.ViewSizeStrategy
		if let height = height {
			heightStrategy = .offset(height)
		} else {
			heightStrategy = .fill
		}
		let sizeStrategy = (width: SimpleViewSizeSource.ViewSizeStrategy.fill, height: heightStrategy)
		provider = SimpleViewProvider(identifier: "emptyViewProvider",
									  views: [view],
									  sizeStrategy: sizeStrategy,
									  layout: FlowLayout(),
									  animator: animated ? AnimatedReloadAnimator() : nil)
	}
	/// Binds didReload closure
	/// - Parameter didReload: closure that called when all sections is reloaded, view layouts and fitted contentSize fully
	/// - Returns: self
	@discardableResult
	public final func didReload(_ didReload: (() -> Void)?) -> FibGrid {
		self.didReloadClosure = didReload
		return self
	}
	// Проверяем позади формвью наличие интерактивных вьюх, нужно чтобы в режиме
	// шторки (наезд на хедер) можно было обрабатывать нажатия на хедер
	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard FibGridPassthroughHelper.nestedInteractiveViews(in: self, contain: point, convertView: self) else {
			return false
		}
		return super.point(inside: point, with: event)
	}
	private func reloadSections(_ oldValue: Provider?) {}
	private func updateLayoutSubviewsTask() {
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
	
	private func _asyncLayoutSubviews() {
		if needsReload {
			updateLayoutSubviewsTask()
		} else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
			updateLayoutSubviewsTask()
		} else if bounds != lastLoadBounds {
			loadCells()
		}
	}
	
	private func _layoutSubviews() {
		if needsReload {
			reloadData()
		} else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
			invalidateLayout()
		} else if bounds != lastLoadBounds {
			loadCells()
		}
	}
	
	private func _reloadOrInvalidateLayout() {
		if needsReload {
			reloadData()
		} else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
			invalidateLayout()
		}
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		if self.isAsync {
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
	private func loadCells() {
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
	// reload all frames. will automatically diff insertion & deletion
	public func reloadData(contentOffsetAdjustFn: ((CGSize) -> CGPoint)? = nil) {
		guard !isReloading else { return }
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
		if needTestAsyncFibGrid == false,self.isAsync {
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
			if cell !== draggedCell?.cell {
				animator.update(collectionView: self, view: cell,
								at: index, frame: self.flattenedProvider.frame(at: index))
			}
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
				if let cell = cell as? FormViewAppearable,
				   cell.isAppearedOnFibGrid == true {
					cell.onDissappear(with: self)
				}
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
		if let cell = cell as? FormViewAppearable {
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





