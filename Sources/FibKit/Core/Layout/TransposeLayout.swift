//
//  TransposeLayout.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-09-08.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

open class TransposeLayout: WrapperLayout {
	struct TransposeLayoutContext: LayoutContext {
		var original: LayoutContext
		
		var collectionSize: CGSize {
			original.collectionSize.transposed
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
			original.size(at: at, collectionSize: collectionSize.transposed).transposed
		}
	}
	
	open override var contentSize: CGSize {
		rootLayout.contentSize.transposed
	}
	
	open override func layout(context: LayoutContext) {
		rootLayout.layout(context: TransposeLayoutContext(original: context))
	}
	
	open override func visibleIndexes(visibleFrame: CGRect, visibleFrameLessInset: CGRect) -> [Int] {
		rootLayout.visibleIndexes(visibleFrame: visibleFrame.transposed, visibleFrameLessInset: visibleFrameLessInset)
	}
	
	open override func frame(at: Int) -> CGRect {
		rootLayout.frame(at: at).transposed
	}
}
