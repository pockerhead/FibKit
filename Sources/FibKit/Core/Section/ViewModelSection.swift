//
//  AnyHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 27.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit

// swiftlint:disable all

public protocol SectionProtocol: AnyGridSection, AnySectionProtocol, Provider, AnyObject, CustomStringConvertible {
	var isGuard: Bool { get set }
	var isGuardAppend: Bool { get set }
	var isSticky: Bool { get }
	var headerData: ViewModelWithViewClass? { get set }
	var headerTapHandler: ((FibGridHeaderProvider.TapContext) -> Void)? { get set }
}

/// Class that represents data sections in FormView, and provide behaviour to inner views, that representations stored in self.data
open class ViewModelSection:
	FibGridProvider,
	Equatable,
	SectionProtocol,
	AnyGridSection,
	AnySectionProtocol
{
	override public var description: String {
		var id = self.id ?? "Warning no id"
		let splitted = id.components(separatedBy: "/")
		if splitted.count > 1 {
			id = "\(splitted[0])\(splitted[splitted.count-1])"
		}
		return """
GridSection
\(ObjectIdentifier(self))
id: \(self.identifier ?? "")
items: \(data.count),
contentSize: \(self.contentSize),
layout: \(layout.description)
"""
	}
	public static func == (lhs: ViewModelSection, rhs: ViewModelSection) -> Bool {
		lhs.id == rhs.id
		&& Equated(wrappedValue: lhs.data, compare: .dump) == Equated(wrappedValue: rhs.data, compare: .dump)
	}
	
	public var isGuard: Bool = false
	public var isGuardAppend: Bool = false
	
	/// Header viewModel
	open var headerData: ViewModelWithViewClass?
	public var id: String?
	var haveDidReorderSectionsClosure: Bool
	public var isSticky = true
	public var headerTapHandler: ((FibGridHeaderProvider.TapContext) -> Void)?
	
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
		self.haveDidReorderSectionsClosure = didReorderItemsClosure != nil
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
	@discardableResult
	public func didReload(_ closure: @escaping () -> Void) -> Self {
		didReloadClosure = closure
		return self
	}
	
	/// TapHandler of Section, calls when user taps on Section Views (any view e.g. Separator, Spacer, etc...)
	/// - Parameter tapHandler: (TapContext) -> Void, see docs for TapContext
	/// - Returns: self
	public func tapHandler(_ tapHandler: FibGridProvider.TapHandler?) -> Self {
		self.tapHandler = tapHandler
		return self
	}
	
	/// Separator model for whole FormSection, if set, separator will show between cells
	/// - Parameter separator: Separator viewModel
	/// - Returns: self
	public func separator(_ separator: ViewModelWithViewClass?, needLast: Bool = true) -> Self {
		separatorViewModel = separator
		needLastSeparator = needLast
		return self
	}
	
	/// header of Section, ViewModelWithViewClass model, that binded to its view
	/// - Parameter header: ViewModelWithViewClass optional
	/// - Returns: self
	public func header(_ header: ViewModelWithViewClass?) -> Self {
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
	public func isSticky(_ bool: Bool) -> Self {
		self.isSticky = bool
		return self
	}
	
	/// Identifier of Section, if not defined, section may have undefined behaviour
	/// - Parameter id: String identifier of Section, if not defined, section may have undefined behaviour
	/// - Returns: self
	public func id(_ id: String) -> Self {
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
	@available(*, deprecated, renamed: "didReorderItems(context:)")
	public func didReorderItems(_ closure: @escaping ((Int, Int) -> Void)) -> Self {
		self.haveDidReorderSectionsClosure = true
		self.didReorderItemsClosure = closure
		return self
	}
	
	/// Closure that calls when user reorder views in Section, deprecated for now, not worked properly in all cases
	/// - Parameter closure: @escaping ((oldIndex: Int, newIndex: Int) -> Void): old and new indices of reorded data
	/// - Returns: sekf
	public func didReorderItems(context: ReorderContext) -> Self {
		self.haveDidReorderSectionsClosure = true
		self.reorderContext = context
		return self
	}
	
	public struct ReorderContext {
		public init(didBeginReorderSession: (() -> Void)? = nil, didEndReorderSession: @escaping ((Int, Int) -> Void)) {
			self.didEndReorderSession = didEndReorderSession
			self.didBeginReorderSession = didBeginReorderSession
		}
		
		public private(set) var didEndReorderSession: ((Int, Int) -> Void)
		public private(set) var didBeginReorderSession: (() -> Void)?
	}
		
	/// Page direction of reload animation of Section
	/// - Parameter pageDirection: enum left or right
	/// - Returns: self
	@discardableResult
	public func pageDirection(_ pageDirection: AnimatedReloadAnimator.PageDirection?) -> Self {
		(self.animator as? AnimatedReloadAnimator)?.pageDirection = pageDirection
		return self
	}
	
	/// Context of animation that reloads Section
	/// - Parameter context: see AnimationContext doc
	/// - Returns: self
	public func animationContext(_ context: AnimationContext) -> Self {
		(self.animator as? AnimatedReloadAnimator)?.animationContext = context
		return self
	}
	
	/// Attach an specific animator to modified section
	/// - Parameter animator: Animator of section
	/// - Returns: self
	public func animator(_ animator: Animator?) -> Self {
		self.animator = animator
		return self
	}
	
	/// You may provide custom Layout class to Section with custom scrollDirection
	/// - Parameters:
	///   - layout: Layout
	///   - scrollDirection: UICollectionView.ScrollDirection
	/// - Returns: self
	public func layout(_ layout: Layout,
					   scrollDirection: FibGrid.ScrollDirection = .vertical) -> Self {
		(self.layout as? WrapperLayout)?.rootLayout = layout
		self.scrollDirection = scrollDirection
		return self
	}
	
	/// Define layout of Section as flow vertical layout with line and interItem spacing
	/// - Parameters:
	///   - lineSpacing: lineSpacing default 0
	///   - interItemSpacing: interItemSpacing default 0
	/// - Returns: self
	public func flowLayout(lineSpacing: CGFloat = 0,
						   interItemSpacing: CGFloat = 0) -> Self {
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
	public func flowLayout(spacing: CGFloat = 0) -> Self {
		let layout = FlowLayout(spacing: spacing)
		(self.layout as? WrapperLayout)?.rootLayout = layout
		scrollDirection = .vertical
		return self
	}
	
	public func centeringFlowLayout(spacing: CGFloat = 0) -> Self {
		let layout = FlowLayout(spacing: spacing,
								justifyContent: .center,
								alignItems: .center,
								alignContent: .start)
		(self.layout as? WrapperLayout)?.rootLayout = layout
		scrollDirection = .vertical
		return self
	}
	
	/// Define layout of Section as horizontal RowLayout with spacing beetween horizontal views
	/// - Parameter spacing: horizontal spacing default 0
	/// - Returns: self
	public func rowLayout(spacing: CGFloat = 0) -> Self {
		let layout = RowLayout(spacing: spacing)
		(self.layout as? WrapperLayout)?.rootLayout = layout
		scrollDirection = .horizontal
		return self
	}
	
	/// Insets concrete Section within a FormView
	/// - Parameter insets: UIEdgeInsets, default .zero
	/// - Returns: self
	public func inset(by insets: UIEdgeInsets) -> Self {
		(layout as? InsetLayout)?.insets = insets
		return self
	}
	
	/// Insets concrete Section within a FormView
	/// - Parameter insets: UIEdgeInsets, default .zero
	/// - Returns: self
	public func inset(_ inset: UIEdgeInsets.Inset, _ value: CGFloat) -> Self {
		(layout as? InsetLayout)?.insets.apply(inset, value: value)
		return self
	}
	
	/// Provides Section to use Shared system ReuseManager, use carefully cause Section may have undefined behaviour with this modifier. By default each Section use own ReuseManager instance
	/// - Parameter use: flag to use SharedReuseManager
	/// - Returns: self
	public func useSharedReuseManager(_ use: Bool) -> Self {
		viewSource.reuseManager = use ? .shared : .init()
		return self
	}
	
	/// Dummy view class to show shimmers if section data is not setted
	/// - Parameter dummyClass: ViewModelConfigurable.Type
	/// - Returns: self
	public func dummyViewClass(_ dummyClass: ViewModelConfigurable.Type) -> Self {
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
	public convenience init(forceReassignLayout: Bool = false,
							@ViewModelBuilder _ data: (ViewModelSection) -> [ViewModelWithViewClass?],
							line: Int = #line,
							file: String = #file) {
		self.init(data: [], id: "Section_at_\(line)_in_\(file)", forceReassignLayout: forceReassignLayout)
		self.data = data(self)
	}
}

extension ViewModelSection {
	
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

public class EmptySpacer: ViewModelSection {
	public init() {
		let vm = FormViewSpacer(0)
		super.init(data: [vm],
				   header: FormViewSpacer(0),
				   id: "SpaceSection_\(vm.id ?? "Spacer")")
	}
}

public class SpacerSection: ViewModelSection {
	
	override public var description: String {
		"SpacerSection"
	}
	
	public init(_ height: CGFloat, color: UIColor = .clear, cornerRadius: CGFloat = 0, maskedCorners: CACornerMask = []) {
		let vm = SpacerCell.ViewModel(height, color: color, cornerRadius: cornerRadius, maskedCorners: maskedCorners)
		super.init(data: [vm], id: "SpaceSection_\(vm.id ?? "Spacer")")
	}
}

//public class FooterSection: GridSection {
//    let buttonCell = ButtonCell()
//
//    public init(viewModel: ButtonCell.ViewModel) {
//        super.init(data: [], id: "FooterSection")
//        self.buttonCell.configure(with: viewModel)
//    }
//}
//
public class EmptySection: ViewModelSection {
	public var viewModel: ViewModelWithViewClass
	public var height: CGFloat = 0
	
	public init(viewModel: ViewModelWithViewClass, id: String = "1234") {
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



final public class ForEachSection<T>: ViewModelSection {
	
	public init(forceReassignLayout: Bool = false,
				data: [T],
				_ dataMapper: @escaping ((T) -> ViewModelWithViewClass?),
				line: Int = #line,
				file: String = #file) {
		super.init(data: [],
				   id: "Section_at_\(line)_in_\(file)",
				   forceReassignLayout: forceReassignLayout)
		self.dataSource = FibGridForEachDataSource<T>.init(data: data, mapper: dataMapper)
	}
}

extension UIEdgeInsets {
	
	public struct Inset: OptionSet {
		
		public var rawValue: Int8
		public static let top = Inset(rawValue: 1 << 0)
		public static let bottom = Inset(rawValue: 1 << 1)
		public static let left = Inset(rawValue: 1 << 2)
		public static let right = Inset(rawValue: 1 << 3)
		public static let all: Inset = [.top, .bottom, .right, .left]
		public static let horizontal: Inset = [.right, .left]
		public static let vertical: Inset = [.top, .bottom]
		
		public init(rawValue: Int8) {
			self.rawValue = rawValue
		}
	}
	
	mutating public func apply(_ inset: Inset, value: CGFloat) {
		if inset.contains(.left) {
			self.left = value
		}
		if inset.contains(.right) {
			self.right = value
		}
		if inset.contains(.bottom) {
			self.bottom = value
		}
		if inset.contains(.top) {
			self.top = value
		}
	}
}

public struct FibKitDebugDescriptor {
	public static func description(for section: SectionProtocol?) -> String {
		guard let section = section else { return "NO SECTION PROVIDED" }
		return section.description
	}
}
