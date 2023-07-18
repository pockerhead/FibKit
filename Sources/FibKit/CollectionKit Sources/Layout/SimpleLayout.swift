//
//  SimpleLayout.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-09-11.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

public class StackLayout: Layout {
    
    private var topSpacing: CGFloat
    public private(set) var frames: [CGRect] = []
    public private(set) var _contentSize: CGSize = .zero


    public override func layout(context: LayoutContext) {
        frames = (0...context.numberOfItems - 1).reduce(into: [CGRect]()) { partialResult, index in
            let inset: CGFloat = 4
            let insetResult = CGFloat((context.numberOfItems - 1) - index) * inset
            let resultedCollectionSizeWidth = context.collectionSize.width - insetResult
            let newCollectionSize = CGSize(width: resultedCollectionSizeWidth, height: context.collectionSize.height)
            var size = context.size(at: index, collectionSize: newCollectionSize)
            size.width = resultedCollectionSizeWidth
            var frame = CGRect.zero
            _contentSize.width = max(_contentSize.width, size.width)
            frame.origin.y = topSpacing * CGFloat(index)
            frame.size = size
            _contentSize.height = frame.maxY
            partialResult.append(frame)
        }
    }

    public override var contentSize: CGSize {
        _contentSize
    }

    public override func frame(at: Int) -> CGRect {
        frames.get(at) ?? .zero
    }

    public override func visibleIndexes(visibleFrame: CGRect) -> [Int] {
        var result = [Int]()
        for (i, frame) in frames.enumerated() {
          if frame.intersects(visibleFrame) {
            result.append(i)
          }
        }
        return result
    }

    public init(topSpacing: CGFloat = 16) {
        self.topSpacing = topSpacing
    }
}

// swiftlint:disable all
open class SimpleLayout: Layout {
  var _contentSize: CGSize = .zero
    public private(set) var frames: [CGRect] = []

  open func simpleLayout(context: LayoutContext) -> [CGRect] {
    fatalError("Subclass should provide its own layout")
  }

  open func doneLayout() {

  }

  public final override func layout(context: LayoutContext) {
    frames = simpleLayout(context: context)
    _contentSize = frames.reduce(CGRect.zero) { old, item in
      old.union(item)
    }.size
    doneLayout()
  }

  public final override var contentSize: CGSize {
    return _contentSize
  }

  public final override func frame(at: Int) -> CGRect {
    return frames.get(at) ?? .zero
  }

  open override func visibleIndexes(visibleFrame: CGRect) -> [Int] {
    var result = [Int]()
    for (i, frame) in frames.enumerated() {
      if frame.intersects(visibleFrame) {
        result.append(i)
      }
    }
    return result
  }
}

open class VerticalSimpleLayout: SimpleLayout {
  private var maxFrameLength: CGFloat = 0

  open override func doneLayout() {
    maxFrameLength = frames.max { $0.height < $1.height }?.height ?? 0
  }

  open override func visibleIndexes(visibleFrame: CGRect) -> [Int] {
    var index = frames.binarySearch { $0.minY < visibleFrame.minY - maxFrameLength }
    var visibleIndexes = [Int]()
    while index < frames.count {
      let frame = frames[index]
      if frame.minY >= visibleFrame.maxY {
        break
      }
      if frame.maxY > visibleFrame.minY {
        visibleIndexes.append(index)
      }
      index += 1
    }
    return visibleIndexes
  }
}

open class HorizontalSimpleLayout: SimpleLayout {
  private var maxFrameLength: CGFloat = 0

  open override func doneLayout() {
    maxFrameLength = frames.max { $0.width < $1.width }?.width ?? 0
  }

  open override func visibleIndexes(visibleFrame: CGRect) -> [Int] {
    var index = frames.binarySearch { $0.minX < visibleFrame.minX - maxFrameLength }
    var visibleIndexes = [Int]()
    while index < frames.count {
      let frame = frames[index]
      if frame.minX >= visibleFrame.maxX {
        break
      }
      if frame.maxX > visibleFrame.minX {
        visibleIndexes.append(index)
      }
      index += 1
    }
    return visibleIndexes
  }
}
