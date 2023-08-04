//
//  FormViewHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all


import UIKit

open class FibGridHeaderProvider:
SectionProvider, ItemProvider, LayoutableProvider, CollectionReloadable {

    public typealias HeaderViewSource = FibGridViewSource
    public typealias HeaderSizeSource = FibGridSizeSource

    open var identifier: String?

    public var canReorderItems: Bool { _canReorderItems }

	public weak var collectionView: CollectionView? {
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
	
	private weak var _collectionView: CollectionView?
    private var _canReorderItems: Bool = false
    private var reloadTask: DispatchWorkItem?
    public var isAsync = true
    
    open var sections: [Provider] {
        didSet {
            if isAsync {
                updateSetNeedsReloadTask()
            } else {
                self._canReorderItems = sections.reduce(false, { $0 || (($1 as? GridSection)?.haveDidReorderSectionsClosure ?? false) })
                setNeedsReload()
            }
        }
    }
    
    func updateSetNeedsReloadTask() {
        reloadTask?.cancel()
        reloadTask = nil
        let blockTask = DispatchWorkItem.init(block: {[weak self] in
            guard let self = self else { return }
            self._canReorderItems = self.sections.reduce(false, { $0 || (($1 as? GridSection)?.haveDidReorderSectionsClosure ?? false) })
            self.setNeedsReload()
        })
        self.reloadTask = blockTask
        delay(cyclesCount: 2) {[weak blockTask] in
			guard let bt = blockTask, bt.isCancelled == false else { return }
            blockTask?.perform()
        }
    }

    open var animator: Animator? {
        didSet {
            if isAsync {
                updateSetNeedsReloadTask()
            } else {
                setNeedsReload()
            }
        }
    }

    open var headerViewSource: HeaderViewSource = FibGridViewSource() {
        didSet {
            if isAsync {
                updateSetNeedsReloadTask()
            } else {
                setNeedsReload()
            }
        }
    }
    var didReloadClosure: (() -> Void)?

    open var headerSizeSource: HeaderSizeSource = FibGridSizeSource() {
        didSet { setNeedsInvalidateLayout() }
    }

    open var layout: Layout {
        get { return stickyLayout.rootLayout }
        set {
            stickyLayout.rootLayout = newValue
            setNeedsInvalidateLayout()
        }
    }

    var scrollDirection: FibGrid.ScrollDirection

    open var isSticky = true {
        didSet {
            if isSticky {
                stickyLayout.isStickyFn = { index in
                    if index % 2 == 0 {
                        if let section = self.sections[safe: index / 2] as? SectionProtocol {
                            return section.isSticky
                        } else {
                            return true
                        }
                    } else {
                        return false
                    }
                }
            } else {
                stickyLayout.isStickyFn = { _ in false }
            }
            if isAsync {
                updateSetNeedsReloadTask()
            } else {
                setNeedsReload()
            }
        }
    }

    open var tapHandler: TapHandler?

    public typealias TapHandler = (TapContext) -> Void

    public struct TapContext {
        public let view: UIView
        public let index: Int
        public let section: Provider
        public let grid: FibGrid?
    }

    private var stickyLayout: StickyLayout
    public var internalLayout: Layout { return stickyLayout }

    init(identifier: String? = "RootProvider",
		 layout: Layout = FlowLayout().inset(by: .zero),
         animator: Animator? = AnimatedReloadAnimator(),
         sections: [SectionProtocol] = [],
         collectionView: CollectionView?) {
        self.animator = animator
        self.stickyLayout = StickyLayout(rootLayout: layout)
        self._canReorderItems = sections.reduce(false, { $0 || (($1 as? GridSection)?.haveDidReorderSectionsClosure ?? false) })
        self.sections = sections
        self._collectionView = collectionView
        self.identifier = identifier
        self.tapHandler = nil
        self.scrollDirection = layout is RowLayout ? .horizontal : .vertical
        if let layout = layout as? WrapperLayout {
            self.scrollDirection = layout.rootLayout is RowLayout ? .horizontal : .vertical
        }
    }
    
    public func setSections(_ sections: [GridSection] = []) {
        self._canReorderItems = sections.reduce(false, { $0 || $1.haveDidReorderSectionsClosure })
        self.sections = sections
    }

    open var numberOfItems: Int {
        return sections.count * 2
    }

    open func section(at: Int) -> Provider? {
        if at % 2 == 0 {
            return nil
        } else {
            if self.collectionView !== GridsReuseManager.shared.grids[sections[at / 2].identifier ?? ""]?.ref {
                GridsReuseManager.shared.grids[sections[at / 2].identifier ?? ""] = WeakRef(ref: self.collectionView as? FibGrid)
            }
            return sections[at / 2]
        }
    }

    @discardableResult
    func bindReload(_ didReload: (() -> Void)?) -> FibGridHeaderProvider {
        self.didReloadClosure = didReload
        return self
    }

    open func identifier(at: Int) -> String {
        let sectionIdentifier = sections.get(at / 2)?.identifier ?? "\(at)"
        if self.collectionView !== GridsReuseManager.shared.grids[sectionIdentifier]?.ref {
            GridsReuseManager.shared.grids[sectionIdentifier] = WeakRef(ref: self.collectionView as? FibGrid)
        }
        if at % 2 == 0 {
            return sectionIdentifier + "-header"
        } else {
            return sectionIdentifier
        }
    }

    open func layoutContext(collectionSize: CGSize) -> LayoutContext {
        return ComposedHeaderProviderLayoutContext(
            collectionSize: collectionSize,
            sections: sections,
            headerSizeSource: headerSizeSource,
            headerViewSource: headerViewSource,
            headerProvider: self,
            scrollDirection: scrollDirection
        )
    }

    open func animator(at: Int) -> Animator? {
        return animator
    }

    open func view(at: Int) -> UIView {
        let index = at / 2
        guard let data = (sections[safe: index] as? SectionProtocol)?.headerData else { return UIView() }
        let view = headerViewSource.view(data: data, index: index)
        view.fb_isHeader = true
        return view
    }

    open func update(view: UIView, at: Int) {
        let index = at / 2
        view.fb_isHeader = true
        guard let data = (sections[safe: index] as? SectionProtocol)?.headerData else { return }
        headerViewSource.update(view: view as! ViewModelConfigurable, data: data, index: index)
    }

    open func didTap(view: UIView, at: Int) {
        if let tapHandler = (sections[safe: at / 2] as? SectionProtocol)?.headerTapHandler {
            let index = at / 2
            let context = TapContext(view: view, index: index, section: sections[index], grid: self.collectionView as? FibGrid)
            tapHandler(context)
        }
    }

    open func willReload() {
        for section in sections {
            section.willReload()
        }
    }

    open func didReload() {
        for section in sections {
            section.didReload()
        }
        didReloadClosure?()
    }

    // MARK: private stuff
    open func hasReloadable(_ reloadable: CollectionReloadable) -> Bool {
        return reloadable === self || reloadable === headerSizeSource
            || sections.contains(where: { $0.hasReloadable(reloadable) })
    }

    open func flattenedProvider() -> ItemProvider {
        return FlattenedProvider(provider: self)
    }

    struct ComposedHeaderProviderLayoutContext: LayoutContext {
        var collectionSize: CGSize
        var sections: [Provider]
        var headerSizeSource: HeaderSizeSource
        var headerViewSource: HeaderViewSource
        weak var headerProvider: FibGridHeaderProvider?
        var scrollDirection: FibGrid.ScrollDirection

        var numberOfItems: Int {
            return sections.count * 2
        }
        func data(at: Int) -> Any {
            let arrayIndex = at / 2
            if at % 2 == 0 {
                return (headerProvider?.sections[safe: arrayIndex] as? GridSection)?.headerData as Any
            } else {
                return sections[safe: arrayIndex]
            }
        }

        func headerData(at: Int) -> ViewModelWithViewClass? {
            (headerProvider?.sections[safe: at] as? SectionProtocol)?.headerData
        }
        func identifier(at: Int) -> String {
            let sectionIdentifier = sections.get(at / 2)?.identifier ?? "\(at)"
            if at % 2 == 0 {
                return sectionIdentifier + "-header"
            } else {
                return sectionIdentifier
            }
        }
        func size(at index: Int, collectionSize: CGSize) -> CGSize {
            let arrayIndex = index / 2
            if index % 2 == 0 {
                let opdata = headerData(at: arrayIndex)
                guard let data = opdata else { return .zero }
				let opdummy = mainOrSync {
					headerViewSource.getDummyView(data: data) as? ViewModelConfigurable
				}
                guard let dummyView = opdummy else { return .zero }
                return headerSizeSource.size(at: arrayIndex,
                                             data: data,
                                             collectionSize: collectionSize,
                                             dummyView: dummyView,
                                             direction: scrollDirection)
            } else {
                sections[arrayIndex].layout(collectionSize: collectionSize)
                return sections[arrayIndex].contentSize
            }
        }
    }
}

