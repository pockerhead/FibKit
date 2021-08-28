//
//  AnyHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 27.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit

// swiftlint:disable all

/// Class that represents data sections in FormView, and provide behaviour to inner views, that representations stored in self.data
open class GridSection: FibGridProvider {
    var isGuard: Bool = false
    var isGuardAppend: Bool = false
    
    /// Header viewModel
    open var headerData: ViewModelWithViewClass?
    public var id: String?
    var haveDidReloadSectionsClosure: Bool
    var isSticky = true
    var headerTapHandler: ((FibGridHeaderProvider.TapContext) -> Void)?
    
    public var data: [ViewModelWithViewClass?] {
        get {
            dataSource.data
        }
        set {
            dataSource.data = newValue
        }
    }

    public init(data: [ViewModelWithViewClass?],
                header: ViewModelWithViewClass? = nil,
                dummyViewClass: ViewModelConfigurable.Type? = nil,
                useSharedReuseManager: Bool = false,
                id: String = UUID().uuidString,
                tapHandler: FibGridProvider.TapHandler? = nil,
                headerTapHandler: FibGridHeaderProvider.TapHandler? = nil,
                didReorderItemsClosure: ((Int, Int) -> Void)? = nil,
                didReload: (() -> Void)? = nil,
                insets: UIEdgeInsets = .zero,
                spacing: CGFloat = 0,
                pageDirection: AnimatedReloadAnimator.PageDirection? = nil,
                scrollDirection: UICollectionView.ScrollDirection = .vertical,
                forceReassignLayout: Bool = false) {
        
        var layout: Layout
        if scrollDirection == .vertical {
            layout = FlowLayout(spacing: spacing)
        } else {
            layout = RowLayout(spacing: spacing)
        }
        self.headerData = header ?? FormViewSpacer(0.1, color: .clear, width: 0.1)
        self.haveDidReloadSectionsClosure = didReorderItemsClosure != nil
        self.id = id
        super.init(
            identifier: id,
            dataSource: FibGridDataSource(data: data),
            viewSource: FibGridViewSource(dummyViewNilClass: dummyViewClass,
                                          useSharedReuseManager: useSharedReuseManager),
            didReorderItemsClosure: didReorderItemsClosure,
            layout: layout.inset(by: insets),
            animator: AnimatedReloadAnimator(pageDirection: pageDirection),
            tapHandler: tapHandler,
            forceReassignLayout: forceReassignLayout
        )
    }
    
    /// Handler that calls when section is fully reloaded its data but not started rendering their views
    /// - Parameter closure: handler, excaping closure
    /// - Returns: self
    public func didReload(_ closure: @escaping () -> Void) -> GridSection {
        didReloadClosure = closure
        return self
    }
    
    /// TapHandler of Section, calls when user taps on Section Views (any view e.g. Separator, Spacer, etc...)
    /// - Parameter tapHandler: (TapContext) -> Void, see docs for TapContext
    /// - Returns: self
    public func tapHandler(_ tapHandler: FibGridProvider.TapHandler?) -> GridSection {
        self.tapHandler = tapHandler
        return self
    }
    
    /// Separator model for whole FormSection, if set, separator will show between cells
    /// - Parameter separator: Separator viewModel
    /// - Returns: self
    public func separator(_ separator: ViewModelWithViewClass?) -> GridSection {
        separatorViewModel = separator
        return self
    }
    
    /// header of Section, ViewModelWithViewClass model, that binded to its view
    /// - Parameter header: ViewModelWithViewClass optional
    /// - Returns: self
    public func header(_ header: ViewModelWithViewClass?) -> GridSection {
        headerData = header
        return self
    }
    
    /// Closure that called when user taps on section header
    /// - Parameter headerTapHandler: see FibGridHeaderProvider.TapContext
    /// - Returns: self
    public func headerTapHandler(_ headerTapHandler: ((FibGridHeaderProvider.TapContext) -> Void)?) -> Self {
        self.headerTapHandler = headerTapHandler
        return self
    }
    
    /// Provides Stickty header behaviour when header sticks to top edge of FormView, default its true
    /// - Parameter bool: need Sticky default true
    /// - Returns: sekf
    public func isSticky(_ bool: Bool) -> GridSection {
        self.isSticky = bool
        return self
    }
    
    /// Identifier of Section, if not defined, section may have undefined behaviour
    /// - Parameter id: String identifier of Section, if not defined, section may have undefined behaviour
    /// - Returns: self
    public func id(_ id: String) -> GridSection {
        guard id != identifier else {
            return self
        }
        // TODO: @ab make preventFromReload to prevent section from reloading when modifies id or other props from modifier func
        identifier = id
        self.id = id
        if let existedSizeSource = GridsReuseManager.shared.sizeSources[identifier ?? ""] {
            self.sizeSource = existedSizeSource
        } else {
            GridsReuseManager.shared.sizeSources[identifier ?? ""] = sizeSource
        }
        if let existedLayout = GridsReuseManager.shared.layouts[identifier ?? ""] {
            self.layout = existedLayout
        } else {
            GridsReuseManager.shared.layouts[identifier ?? ""] = self.layout
        }
        return self
    }
    
    /// Closure that calls when user reorder views in Section, deprecated for now, not worked properly in all cases
    /// - Parameter closure: @escaping ((oldIndex: Int, newIndex: Int) -> Void): old and new indices of reorded data
    /// - Returns: sekf
    public func didReorderItems(_ closure: @escaping ((Int, Int) -> Void)) -> GridSection {
        self.haveDidReloadSectionsClosure = true
        self.didReorderItemsClosure = closure
        return self
    }
    
    /// Page direction of reload animation of Section
    /// - Parameter pageDirection: enum left or right
    /// - Returns: self
    @discardableResult
    public func pageDirection(_ pageDirection: AnimatedReloadAnimator.PageDirection?) -> GridSection {
        self.animator = AnimatedReloadAnimator(pageDirection: pageDirection)
        return self
    }
    
    /// Context of animation that reloads Section
    /// - Parameter context: see AnimationContext doc
    /// - Returns: self
    public func animationContext(_ context: AnimationContext) -> GridSection {
        (self.animator as? AnimatedReloadAnimator)?.animationContext = context
        return self
    }
    
    /// Attach an specific animator to modified section
    /// - Parameter animator: Animator of section
    /// - Returns: self
    public func animator(_ animator: Animator?) -> GridSection {
        self.animator = animator
        return self
    }
    
    /// You may provide custom Layout class to Section with custom scrollDirection
    /// - Parameters:
    ///   - layout: Layout
    ///   - scrollDirection: UICollectionView.ScrollDirection
    /// - Returns: self
    public func layout(_ layout: Layout,
                       scrollDirection: UICollectionView.ScrollDirection = .vertical) -> GridSection {
        (self.layout as? WrapperLayout)?.rootLayout = layout
        self.scrollDirection = .vertical
        return self
    }
    
    /// Define layout of Section as flow vertical layout with line and interItem spacing
    /// - Parameters:
    ///   - lineSpacing: lineSpacing default 0
    ///   - interItemSpacing: interItemSpacing default 0
    /// - Returns: self
    public func flowLayout(lineSpacing: CGFloat = 0,
                           interItemSpacing: CGFloat = 0) -> GridSection {
        let layout = FlowLayout(lineSpacing: lineSpacing,
                                interitemSpacing: interItemSpacing)
        (self.layout as? WrapperLayout)?.rootLayout = layout
        scrollDirection = .vertical
        return self
    }
    /// Define layout of Section as flow vertical layout with line and interItem spacing as single value of `spacing`
    /// - Parameters:
    ///   - spacing: line and interItem spacing as single value of `spacing` default 0
    /// - Returns: self
    public func flowLayout(spacing: CGFloat = 0) -> GridSection {
        let layout = FlowLayout(spacing: spacing)
        (self.layout as? WrapperLayout)?.rootLayout = layout
        scrollDirection = .vertical
        return self
    }
    
    /// Define layout of Section as horizontal RowLayout with spacing beetween horizontal views
    /// - Parameter spacing: horizontal spacing default 0
    /// - Returns: self
    public func rowLayout(spacing: CGFloat = 0) -> GridSection {
        let layout = RowLayout(spacing: spacing)
        (self.layout as? WrapperLayout)?.rootLayout = layout
        scrollDirection = .horizontal
        return self
    }
    
    /// Insets concrete Section within a FormView
    /// - Parameter insets: UIEdgeInsets, default .zero
    /// - Returns: self
    public func inset(by insets: UIEdgeInsets) -> GridSection {
        (layout as? InsetLayout)?.insets = insets
        return self
    }
    
    /// Provides Section to use Shared system ReuseManager, use carefully cause Section may have undefined behaviour with this modifier. By default each Section use own ReuseManager instance
    /// - Parameter use: flag to use SharedReuseManager
    /// - Returns: self
    public func useSharedReuseManager(_ use: Bool) -> GridSection {
        viewSource.reuseManager = use ? .shared : .init()
        return self
    }
    
    /// Dummy view class to show shimmers if section data is not setted
    /// - Parameter dummyClass: ViewModelConfigurable.Type
    /// - Returns: self
    public func dummyViewClass(_ dummyClass: ViewModelConfigurable.Type) -> GridSection {
        viewSource.nilDataDummyViewClass = dummyClass
        return self
    }
    
    /// Main init of FormSection
    /// - Parameters:
    ///   - data: ViewModelBuilder closure to provide models in section
    public convenience init(forceReassignLayout: Bool = false,
                            @ViewModelBuilder _ data: () -> [ViewModelWithViewClass?],
                            line: Int = #line,
                            file: String = #file) {
        self.init(data: data(), id: "Section_at_\(line)_in_\(file)", forceReassignLayout: forceReassignLayout)
    }
    
    /// Conveniense init with GridSection as BuildBlock parameter
    /// - Parameters:
    ///   - data: ViewModelBuilder closure to provide models in section (with GridSection as parameter)
    public convenience init(@ViewModelBuilder _ data: (GridSection) -> [ViewModelWithViewClass?],
                                              line: Int = #line,
                                              file: String = #file) {
        self.init(data: [], id: "Section_at_\(line)_in_\(file)")
        self.data = data(self)
    }
}

extension FibGrid {
    
    @available(*, message: "Use native if")
    public static func `if`(_ condition: Bool,
                            @SectionBuilder append sections: () -> [GridSection],
                            @SectionBuilder elseAppend elseSections: () -> [GridSection] = {[]})
    -> [GridSection] {
        if condition {
            return sections()
        } else {
            return elseSections()
        }
    }

    public static func `guard`(_ condition: Bool,
                               @SectionBuilder elseReturn sections: () -> [GridSection])
    -> [GridSection] {
        if !condition {
            let s = sections()
            s.forEach({ $0.isGuard = true })
            return s
        } else {
            return []
        }
    }

    public static func `guard`(_ condition: Bool,
                               @SectionBuilder elseAppend sections: () -> [GridSection])
    -> [GridSection] {
        if !condition {
            let s = sections()
            s.forEach({ $0.isGuardAppend = true })
            return s
        } else {
            return []
        }
    }
    
}

extension GridSection {

    @available(*, message: "Use native if")
    public static func `if`(_ condition: Bool,
                            @ViewModelBuilder _ vms: () -> [ViewModelWithViewClass?])
    -> [ViewModelWithViewClass?] {
        if condition {
            return vms()
        } else {
            return []
        }
    }
}

public class EmptySpacer: GridSection {
    public init() {
        let vm = FormViewSpacer(0)
        super.init(data: [vm],
                   header: FormViewSpacer(0),
                   id: "SpaceSection_\(vm.id ?? "Spacer")")
    }
}

public class SpacerSection: GridSection {

    public init(_ height: CGFloat, color: UIColor = .clear, cornerRadius: CGFloat = 0, maskedCorners: CACornerMask = []) {
        let vm = SpacerCell.ViewModel(height, color: color, cornerRadius: cornerRadius, maskedCorners: maskedCorners)
        super.init(data: [vm], id: "SpaceSection_\(vm.id ?? "Spacer")")
    }
}

public class EmptySection: GridSection {
    public let emptyView = UIView()
    public var viewModel: ViewModelWithViewClass?
    public var height: CGFloat = 0

    public init(viewModel: ViewModelWithViewClass?, id: String = "1234") {
        self.viewModel = viewModel
        super.init(data: [viewModel], id: "EmptySection_\(id)")
    }
}

func deepId(_ object: Any) -> String {
    if let viewModel = object as? ViewModelWithViewClass,
       let id = viewModel.id { return id }
    let mirror = Mirror(reflecting: object)
    if mirror.children.isEmpty { return "\(object)" }
    return mirror.children.map({ "\(String(describing: $0.label)):\(deepId($0.value))" }).joined(separator: ";;")
}
