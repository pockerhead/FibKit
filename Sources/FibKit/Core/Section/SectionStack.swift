//
//  File.swift
//  
//
//  Created by Артём Балашов on 18.07.2023.
//

import Foundation
import UIKit

public class SectionStack:
	FibGridHeaderProvider,
	SectionProtocol,
	AnyGridSection,
	AnySectionProtocol
{
	override public var description: String {
		
		return """
SectionStack
\(ObjectIdentifier(self))
id:

\(self.identifier ?? ""),

contentSize: \(self.contentSize),
layout: \(layout.description)


Sections: [
\(sections.map({ $0.descriptionString() }).joined(separator: "\n-----------------------\n"))
]
"""
	}
	public var headerTapHandler: ((FibGridHeaderProvider.TapContext) -> Void)?
	
	public var headerData: ViewModelWithViewClass?
	
	
	public var isGuard: Bool = false
	public var isGuardAppend: Bool = false
	
	public convenience init(
		forceReassignLayout: Bool = true,
		@SectionProtocolBuilder _ data: () -> [SectionProtocol],
		line: Int = #line,
		file: String = #file,
		collectionView: FibGrid? = nil
	) {
		self.init(identifier: "Section_at_\(line)_in_\(file)", sections: data(), collectionView: collectionView)
		self.headerData = FormViewSpacer(0.1, color: .clear, width: 0.1)
		self.isSticky = true
	}
	
	public convenience init(
		forceReassignLayout: Bool = true,
		@SectionBuilder viewModelSections: () -> [ViewModelSection],
		line: Int = #line,
		file: String = #file,
		collectionView: FibGrid? = nil
	) {
		self.init(identifier: "Section_at_\(line)_in_\(file)", sections: viewModelSections(), collectionView: collectionView)
		self.headerData = FormViewSpacer(0.1, color: .clear, width: 0.1)
		self.isSticky = true
	}
	
	/// Closure that called when user taps on section header
	/// - Parameter headerTapHandler: see FibGridHeaderProvider.TapContext
	/// - Returns: self
	public func headerTapHandler(_ headerTapHandler: ((FibGridHeaderProvider.TapContext) -> Void)?) -> Self {
		self.headerTapHandler = headerTapHandler
		return self
	}
	
	/// header of Section, ViewModelWithViewClass model, that binded to its view
	/// - Parameter header: ViewModelWithViewClass optional
	/// - Returns: self
	public func header(_ header: ViewModelWithViewClass?) -> Self {
		headerData = header
		return self
	}
	
	/// Handler that calls when section is fully reloaded its data but not started rendering their views
	/// - Parameter closure: handler, excaping closure
	/// - Returns: self
	@discardableResult
	public func didReload(_ closure: @escaping () -> Void) -> Self {
		didReloadClosure = closure
		return self
	}
	
	/// Provides Stickty header behaviour when header sticks to top edge of FormView, default its true
	/// - Parameter bool: need Sticky default true
	/// - Returns: sekf
	public func isSticky(_ bool: Bool) -> Self {
		self.isSticky = bool
		return self
	}
	
	/// TapHandler of Section, calls when user taps on Section Views (any view e.g. Separator, Spacer, etc...)
	/// - Parameter tapHandler: (TapContext) -> Void, see docs for TapContext
	/// - Returns: self
	public func tapHandler(_ tapHandler: FibGridHeaderProvider.TapHandler?) -> Self {
		self.tapHandler = tapHandler
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
		return self
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
	
	public func scrollDirection(_ direction: FibGrid.ScrollDirection) -> Self {
		self.scrollDirection = direction
		return self
	}
	
	/// Provides Section to use Shared system ReuseManager, use carefully cause Section may have undefined behaviour with this modifier. By default each Section use own ReuseManager instance
	/// - Parameter use: flag to use SharedReuseManager
	/// - Returns: self
	public func useSharedReuseManager(_ use: Bool) -> Self {
		headerViewSource.reuseManager = use ? .shared : .init()
		return self
	}
}
