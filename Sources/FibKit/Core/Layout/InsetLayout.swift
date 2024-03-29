//
//  InsetLayout.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-09-08.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

open class InsetLayout: WrapperLayout {
	public var insets: UIEdgeInsets
	public var insetProvider: ((CGSize) -> UIEdgeInsets)?
	
	public override var description: String {
  """
InsetLayout
insets: \(insets)
\(super.description)
"""
	}
	
	struct InsetLayoutContext: LayoutContext {
		var original: LayoutContext
		var insets: UIEdgeInsets
		
		var collectionSize: CGSize {
			original.collectionSize.insets(by: insets)
		}
		var numberOfItems: Int {
			original.numberOfItems
		}
		
		func data(at: Int) -> Any {
			original.data(at: at)
		}
		func identifier(at: Int) -> String {
			original.identifier(at: at)
		}
		func size(at: Int, collectionSize: CGSize) -> CGSize {
			original.size(at: at, collectionSize: collectionSize)
		}
	}
	
	public init(_ rootLayout: Layout, insets: UIEdgeInsets = .zero) {
		self.insets = insets
		super.init(rootLayout)
	}
	
	public init(_ rootLayout: Layout, insetProvider: @escaping ((CGSize) -> UIEdgeInsets)) {
		self.insets = .zero
		self.insetProvider = insetProvider
		super.init(rootLayout)
	}
	
	open override var contentSize: CGSize {
		rootLayout.contentSize.insets(by: -insets)
	}
	
	open override func layout(context: LayoutContext) {
		if let insetProvider = insetProvider {
			insets = insetProvider(context.collectionSize)
		}
		rootLayout.layout(context: InsetLayoutContext(original: context, insets: insets))
	}
	
	open override func visibleIndexes(visibleFrame: CGRect, visibleFrameLessInset: CGRect) -> [Int] {
		rootLayout.visibleIndexes(visibleFrame: visibleFrame.inset(by: -insets), visibleFrameLessInset: visibleFrameLessInset.inset(by: -insets))
	}
	
	open override func frame(at: Int) -> CGRect {
		rootLayout.frame(at: at) + CGPoint(x: insets.left, y: insets.top)
	}
}
