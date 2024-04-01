//
//  FormViewProvider.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all


import UIKit


open class FibGridProvider: ItemProvider, CollectionReloadable, LayoutableProvider {
	public var description: String {
		String(describing: FibGridProvider.self)
	}
    public var identifier: String? {
        didSet {
            GridsReuseManager.shared.sizeSources[identifier ?? ""] = sizeSource
            GridsReuseManager.shared.layouts[identifier ?? ""] = layout
        }
    }
    public var dataSource: FibGridDataSource { didSet { setNeedsReload() } }
    public var viewSource: FibGridViewSource { didSet { setNeedsReload() } }
    public var sizeSource: FibGridSizeSource { didSet { setNeedsInvalidateLayout() } }
    public var layout: Layout { didSet { setNeedsInvalidateLayout() } }
    public var animator: Animator? { didSet { setNeedsReload() } }
	public weak var collectionView: FibGrid? {
		set {
			self._collectionView = newValue
		}
		get {
			if let cw = _collectionView {
				return cw
			} else if let cw = GridsReuseManager.shared.grids[identifier ?? ""] {
				return cw.ref
			} else {
				return nil
			}
		}
	}
	
	private weak var _collectionView: FibGrid?
    public var isAsync = true
    var needLastSeparator: Bool = true
	public var canReorderItems: Bool {
		didReorderItemsClosure != nil || reorderContext != nil
	}
    var tapHandler: TapHandler?
    var didReloadClosure: (() -> Void)?
    var scrollDirection: FibGrid.ScrollDirection
    var didReorderItemsClosure: ((Int, Int) -> Void)?
	var reorderContext: ReorderContext?
    var separatorViewModel: ViewModelWithViewClass?
	var backgroundViewModel: FibSectionBackgroundView.ViewModel?
	weak var backgroundViewRef: FibSectionBackgroundView?
	var backgroundViewOffsets: UIEdgeInsets = .zero
    public typealias TapHandler = (TapContext) -> Void
    
    /// DTO struct that represents tap on Section view
    public struct TapContext {
        
        public init(grid: FibGrid?, view: UIView, index: Int, dataSource: FibGridDataSource, gridSection: FibGridProvider? = nil) {
            self.grid = grid
            self.view = view
            self.index = index
            self.dataSource = dataSource
            self.section = gridSection
        }
        
        public weak var section: FibGridProvider?
        
        public let grid: FibGrid?
        
        /// View that responds on user tap
        public let view: UIView
        
        /// Index of data in Section.data
        public let index: Int
        
        /// Private dataSource
        public let dataSource: FibGridDataSource
        
        /// Model that binds to view
        public var data: ViewModelWithViewClass? {
            return dataSource.data(at: index)
        }
        
        /// calls setNeedReload to whole Section
        public func setNeedsReload() {
            dataSource.setNeedsReload()
        }
    }

    public init(identifier: String? = nil,
                dataSource: FibGridDataSource,
                viewSource: FibGridViewSource = FibGridViewSource(),
                sizeSource: FibGridSizeSource = FibGridSizeSource(),
                didReorderItemsClosure: ((Int, Int) -> Void)?,
                layout: Layout = FlowLayout(),
                animator: Animator? = AnimatedReloadAnimator(),
                tapHandler: TapHandler? = nil,
                separatorViewModel: ViewModelWithViewClass? = nil,
                forceReassignLayout: Bool = true) {
        self.dataSource = dataSource
        self.viewSource = viewSource
        self.separatorViewModel = separatorViewModel
        self.didReorderItemsClosure = didReorderItemsClosure
        if let existedSizeSource = GridsReuseManager.shared.sizeSources[identifier ?? ""] {
            self.sizeSource = existedSizeSource
        } else {
            self.sizeSource = sizeSource
            GridsReuseManager.shared.sizeSources[identifier ?? ""] = sizeSource
        }
        self.animator = animator
        self.tapHandler = tapHandler
        self.identifier = identifier
        var neededLayout = layout
        if !forceReassignLayout,
           let existedLayout = GridsReuseManager.shared.layouts[identifier ?? ""] {
            neededLayout = existedLayout
        } else {
            GridsReuseManager.shared.layouts[identifier ?? ""] = neededLayout
        }
        self.scrollDirection = neededLayout is RowLayout ? .horizontal : .vertical
        if let layout = neededLayout as? WrapperLayout {
            self.scrollDirection = layout.rootLayout is RowLayout ? .horizontal : .vertical
        }
        self.layout = neededLayout
    }

    public func didReload() {
        didReloadClosure?()
    }

    @discardableResult
    public func bindReload(_ didReload: (() -> Void)?) -> FibGridProvider {
        self.didReloadClosure = didReload
        return self
    }

    public var numberOfItems: Int {
		var numberOfItems = dataSource.numberOfItems
        if separatorViewModel != nil {
			numberOfItems = dataSource.numberOfItems * 2
        }
		if backgroundViewModel != nil {
			numberOfItems += 1
		}
        return numberOfItems
    }
    public func view(at: Int) -> UIView {
		var view: UIView
		var at = at
		if let backgroundViewModel {
			if at == 0 {
				let view = viewSource.view(data: backgroundViewModel, index: at)
				backgroundViewRef = view as? FibSectionBackgroundView
				return view
			} else {
				at = at - 1
			}
		}
        if separatorViewModel != nil {
            if at % 2 != 0 {
				if !needLastSeparator, at == numberOfItems - 1 {
					view = viewSource.view(data: FormViewSpacer(0), index: at)
				} else if let cellSeparator = dataSource.data(at: at / 2)?.separator {
					view = viewSource.view(data: cellSeparator, index: at)
				} else {
					view = viewSource.view(data: separatorViewModel, index: at)
				}
            } else {
				view = viewSource.view(data: dataSource.data(at: at / 2), index: at / 2)
            }
		} else {
			view = viewSource.view(data: dataSource.data(at: at), index: at)
		}
		(view as? FibCoreView)?.setMaskView(backgroundViewRef)
		view.fb_provider = self
		return view
    }
	
    public func update(view: UIView, at: Int) {
		view.fb_provider = self
		var at = at
		if let backgroundViewModel {
			if at == 0 {
				viewSource.update(view: view as! ViewModelConfigurable, data: backgroundViewModel, index: at)
				return
			} else {
				at = at - 1
			}
		}
        if separatorViewModel != nil {
            if at % 2 != 0 {
                if let cellSeparator = dataSource.data(at: at / 2)?.separator {
                    viewSource.update(view: view as! ViewModelConfigurable, data: cellSeparator, index: at)
                    return
                }
                viewSource.update(view: view as! ViewModelConfigurable, data: separatorViewModel, index: at)
            } else {
                viewSource.update(view: view as! ViewModelConfigurable, data: dataSource.data(at: at / 2), index: at / 2)
            }
            return
        }
        viewSource.update(view: view as! ViewModelConfigurable, data: dataSource.data(at: at), index: at)
    }
    public func identifier(at: Int) -> String {
		var at = at
		if let backgroundViewModel {
			if at == 0 {
				return "_FVP.BackgroundView.\(backgroundViewModel.viewClass().className)"
			} else {
				at = at - 1
			}
		}
        if separatorViewModel != nil {
            if at % 2 != 0 {
                return "_FVP.Separator_at_\(at)"
            } else {
                return dataSource.identifier(at: at / 2)
            }
        }
        return dataSource.identifier(at: at)
    }
    public func layoutContext(collectionSize: CGSize) -> LayoutContext {
        return BasicProviderLayoutContext(collectionSize: collectionSize,
                                          dataSource: dataSource,
                                          viewSource: viewSource,
                                          sizeSource: sizeSource,
                                          scrollDirection: scrollDirection,
                                          separatorViewModel: separatorViewModel)
    }
    public func animator(at: Int) -> Animator? {
        return animator
    }
    public func didTap(view: UIView, at: Int) {
		var at = at
		if let backgroundViewModel {
			if at == 0 {
				return
			} else {
				at = at - 1
			}
		}
        if let tapHandler = tapHandler {
            if separatorViewModel != nil {
                if at % 2 == 0 {
					let context = TapContext(grid: self.collectionView, view: view as! ViewModelConfigurable, index: at / 2, dataSource: dataSource, gridSection: self)
                    tapHandler(context)
                }
                return
            }
			let context = TapContext(grid: self.collectionView, view: view as! ViewModelConfigurable, index: at, dataSource: dataSource, gridSection: self)
            tapHandler(context)
        }
    }
	
	public func frame(at: Int) -> CGRect {
		var at = at
		if backgroundViewModel != nil {
			if at == 0 {
				var backgroundRect = CGRect(origin: .zero, size: contentSize)
				if let layout = layout as? InsetLayout {
					backgroundRect = CGRect(
						origin: layout.rootLayout.frame(at: 0).origin
							.translate(layout.insets.left, dy: layout.insets.top),
						size: layout.rootLayout.contentSize)
					backgroundRect = backgroundRect
						.inset(by: -backgroundViewOffsets)
				} else {
					backgroundRect.origin = layout.frame(at: 0).origin
				}
				return backgroundRect
			} else {
				at = at - 1
			}
		}
		return internalLayout.frame(at: at)
	}
	
	public func visibleIndexes(visibleFrame: CGRect, visibleFrameLessInset: CGRect) -> [Int] {
		if let backgroundViewModel {
			var indexes = internalLayout.visibleIndexes(visibleFrame: visibleFrame, visibleFrameLessInset: visibleFrameLessInset)
			if indexes.isEmpty {
				return indexes
			} else {
				indexes[0] = 0
				indexes.append(indexes.last! + 1)
				return indexes
			}
		} else {
			return internalLayout.visibleIndexes(visibleFrame: visibleFrame, visibleFrameLessInset: visibleFrameLessInset)
		}
	}
	
	public func didBeginLongTapWithProvider(context: LongGestureContext) {
		reorderContext?.didBeginReorderSession?()
	}

	public func didLongTapContinue(context: LongGestureContext) -> CGRect? {
		guard let intersectsView = context.intersectsCell?.cell,
			  var intersectsIndex = context.intersectsCell?.index
		else { return nil }
		let sectionHaveSeparator = separatorViewModel != nil
		if sectionHaveSeparator, intersectsIndex % 2 != 0 {
			return nil
		}
		var draggedIndex = context.index
		if sectionHaveSeparator {
			intersectsIndex = intersectsIndex / 2
			draggedIndex = draggedIndex / 2
		}
		if backgroundViewModel != nil {
			intersectsIndex -= 1
			draggedIndex -= 1
		}
		let draggedFrame = context.view.frame
		let intersectsFrame = intersectsView.frame
		let intersectsSquare = intersectsFrame.size.square
		let intersectionFrame = context.intersectionFrame ?? .zero
		let draggedFrameSquare = draggedFrame.size.square
		let intersectionFrameSquare = intersectionFrame.size.square
		let needReorder = (intersectionFrameSquare > (draggedFrameSquare / 2.2)) || (intersectionFrameSquare > (intersectsSquare / 2.2))
		if needReorder {
			self.dataSource.mutateDataWithoutReload { dataSource in
				let data = dataSource.data.remove(at: clampToNumberOfItems(draggedIndex))
				dataSource.data.insert(data, at: clampToNumberOfItems(intersectsIndex))
			}
			context.collectionView?.draggedCell?.index = intersectsIndex
			if reorderContext?.reorderType == .immediateReload {
				self.setNeedsReload()
			}
			return intersectsFrame
		}
        return nil
    }

    public func didLongTapEnded(context: LongGestureContext) {
		guard var finalIndex = context.collectionView?.draggedCell?.index.softClamp(0, dataSource.numberOfItems - 1) else {
            return
        }
		var initialIndex = context.collectionView?.draggedCellInitialIndex ?? 0
		if separatorViewModel != nil {
			initialIndex = initialIndex / 2
		}
		if backgroundViewModel != nil {
			initialIndex -= 1
			if finalIndex == 1 {
				finalIndex -= 1
			}
		}
		didReorderItemsClosure?(initialIndex, finalIndex)
		reorderContext?.didEndReorderSession(
			clampToNumberOfItems(initialIndex),
			clampToNumberOfItems(finalIndex)
		)
    }
	
	func clampToNumberOfItems(_ index: Int) -> Int {
		index.clamp(0, dataSource.numberOfItems - 1)
	}

    public func hasReloadable(_ reloadable: CollectionReloadable) -> Bool {
        return reloadable === self || reloadable === dataSource || reloadable === sizeSource
    }

    struct BasicProviderLayoutContext: LayoutContext {
        var collectionSize: CGSize
        var dataSource: FibGridDataSource
        var viewSource: FibGridViewSource
        var sizeSource: FibGridSizeSource
        var scrollDirection: FibGrid.ScrollDirection
        var separatorViewModel: ViewModelWithViewClass?

        var numberOfItems: Int {
            if separatorViewModel != nil {
                return dataSource.numberOfItems * 2
            }
            return dataSource.numberOfItems
        }
        func data(at: Int) -> Any {
            if let separator = separatorViewModel {
                if at % 2 != 0 {
                    if let cellSeparator = dataSource.data(at: at / 2)!.separator {
                        return cellSeparator
                    }
                    return separator
                }
                return dataSource.data(at: at / 2)!
            }
            return dataSource.data(at: at)!
        }
        func identifier(at: Int) -> String {
            if separatorViewModel != nil {
                if at % 2 != 0 {
                    return dataSource.identifier(at: at / 2) + "_separator"
                }
                return dataSource.identifier(at: at / 2)
            }
            return dataSource.identifier(at: at)
        }
        func size(at index: Int, collectionSize: CGSize) -> CGSize {
            var index = index
            if var separatorViewModel = separatorViewModel {
                if index % 2 != 0 {
					if let cellSeparator = dataSource.data(at: index / 2)?.separator {
						separatorViewModel = cellSeparator
					}
					return sizeSource.size(
						at: index,
						data: separatorViewModel,
						collectionSize: collectionSize,
						dummyView: mainOrSync({
							viewSource.getDummyView(data: separatorViewModel) as! ViewModelConfigurable
						}),
						direction: scrollDirection
					)
				} else {
                    index = index / 2
                }
            }
            let data = dataSource.data(at: index)
			let dummyView = mainOrSync {
				viewSource.getDummyView(data: data) as! ViewModelConfigurable
			}
            return sizeSource.size(at: index,
                                   data: data,
                                   collectionSize: collectionSize,
                                   dummyView: dummyView,
                                   direction: scrollDirection)
        }
    }
}

public class Distance {
    public var x1: CGFloat // firstPoint
    public var x2: CGFloat // lastPoint

    public init(x1: CGFloat, x2: CGFloat) {
        self.x1 = x1
        self.x2 = x2
    }

    public func contains(x: CGFloat) -> Bool {
        return x > x1 && x < x2
    }

	public var length: CGFloat {
		x2 - x1
	}

	public func convertPoint(point: CGFloat, from distance: Distance) -> CGFloat {
		let k = point / distance.length
		return x1 + (length * k)
	}
}
