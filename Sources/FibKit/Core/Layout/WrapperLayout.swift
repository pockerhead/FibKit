//
//  WrapperLayout.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-09-11.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

open class WrapperLayout: Layout {
	
	public override var description: String {
		"""
rootLayout: \(rootLayout.description)
"""
	}
  var rootLayout: Layout

  public init(_ rootLayout: Layout) {
    self.rootLayout = rootLayout
  }

  open override var contentSize: CGSize {
    rootLayout.contentSize
  }

  open override func layout(context: LayoutContext) {
    rootLayout.layout(context: context)
  }

  open override func visibleIndexes(visibleFrame: CGRect, visibleFrameLessInset: CGRect) -> [Int] {
	  rootLayout.visibleIndexes(visibleFrame: visibleFrame, visibleFrameLessInset: visibleFrameLessInset)
  }

  open override func frame(at: Int) -> CGRect {
    rootLayout.frame(at: at)
  }
}
