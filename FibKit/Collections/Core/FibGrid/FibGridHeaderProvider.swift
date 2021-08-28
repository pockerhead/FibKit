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

    public var collectionView: CollectionView?
    private var _canReorderItems: Bool = false
    private var reloadTask: DispatchWorkItem?

    
    open var sections: [Provider] {
        didSet {
            updateSetNeedsReloadTask()
        }
    }
    
    func updateSetNeedsReloadTask() {
        reloadTask?.cancel()
        reloadTask = nil
        let blockTask = DispatchWorkItem.init(block: {[weak self] in
            guard let self = self else { return }
            self.setNeedsReload()
        })
        self.reloadTask = blockTask
        DispatchQueue.main.async {
            blockTask.perform()
        }
    }

    open var animator: Animator? {
        didSet { updateSetNeedsReloadTask() }
    }

    open var headerViewSource: HeaderViewSource = FibGridViewSource() {
        didSet { updateSetNeedsReloadTask() }
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

    var scrollDirection: UICollectionView.ScrollDirection

    open var isSticky = true {
        didSet {
            if isSticky {
                stickyLayout.isStickyFn = { index in
                    if index % 2 == 0 {
                        if let section = self.sections[index / 2] as? GridSection {
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
            updateSetNeedsReloadTask()
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
         layout: Layout = FlowLayout(),
         animator: Animator? = nil,
         sections: [GridSection] = [],
         collectionView: CollectionView) {
        self.animator = animator
        self.stickyLayout = StickyLayout(rootLayout: layout)
        self._canReorderItems = sections.reduce(false, { $0 || $1.haveDidReloadSectionsClosure })
        self.sections = sections
        self.collectionView = collectionView
        self.identifier = identifier
        self.tapHandler = nil
        self.scrollDirection = layout is RowLayout ? .horizontal : .vertical
        if let layout = layout as? WrapperLayout {
            self.scrollDirection = layout.rootLayout is RowLayout ? .horizontal : .vertical
        }
    }
    
    public func setSections(_ sections: [GridSection] = []) {
        self._canReorderItems = sections.reduce(false, { $0 || $1.haveDidReloadSectionsClosure })
        self.sections = sections
    }

    open var numberOfItems: Int {
        return sections.count * 2
    }

    open func section(at: Int) -> Provider? {
        if at % 2 == 0 {
            return nil
        } else {
            GridsReuseManager.shared.grids[sections[at / 2].identifier ?? ""] = WeakRef(ref: self.collectionView as? FibGrid)
            return sections[at / 2]
        }
    }

    @discardableResult
    func bindReload(_ didReload: (() -> Void)?) -> FibGridHeaderProvider {
        self.didReloadClosure = didReload
        return self
    }

    open func identifier(at: Int) -> String {
        let sectionIdentifier = sections[at / 2].identifier ?? "\(at)"
        GridsReuseManager.shared.grids[sectionIdentifier] = WeakRef(ref: self.collectionView as? FibGrid)
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
        guard let data = (sections[index] as? GridSection)?.headerData else { return UIView() }
        return headerViewSource.view(data: data, index: index)
    }

    open func update(view: UIView, at: Int) {
        let index = at / 2
        guard let data = (sections[index] as? GridSection)?.headerData else { return }
        headerViewSource.update(view: view as! ViewModelConfigurable, data: data, index: index)
    }

    open func didTap(view: UIView, at: Int) {
        if let tapHandler = (sections[at / 2] as? GridSection)?.headerTapHandler {
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
        var scrollDirection: UICollectionView.ScrollDirection

        var numberOfItems: Int {
            return sections.count * 2
        }
        func data(at: Int) -> Any {
            let arrayIndex = at / 2
            if at % 2 == 0 {
                return (headerProvider?.sections[arrayIndex] as? GridSection)?.headerData as Any
            } else {
                return sections[arrayIndex]
            }
        }

        func headerData(at: Int) -> ViewModelWithViewClass? {
            (headerProvider?.sections[at] as? GridSection)?.headerData
        }
        func identifier(at: Int) -> String {
            let sectionIdentifier = sections[at / 2].identifier ?? "\(at)"
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
                let opdummy = headerViewSource.getDummyView(data: data) as? ViewModelConfigurable
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

