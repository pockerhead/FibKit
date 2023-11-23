//
//  FlowLayout.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-08-15.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

public class FlowLayout: VerticalSimpleLayout {
	public var lineSpacing: CGFloat
	public var interitemSpacing: CGFloat
	
	public var alignContent: AlignContent
	public var alignItems: AlignItem
	public var justifyContent: JustifyContent
	
	public override var description: String {
  """
FlowLayout:

lineSpacing:\(lineSpacing)
interitemSpacing:\(interitemSpacing)
alignContent: \(alignContent)
alignItems: \(alignItems)
justifyContent: \(justifyContent)
"""
	}
	
	public init(lineSpacing: CGFloat = 0,
				interitemSpacing: CGFloat = 0,
				justifyContent: JustifyContent = .start,
				alignItems: AlignItem = .start,
				alignContent: AlignContent = .start) {
		self.lineSpacing = lineSpacing
		self.interitemSpacing = interitemSpacing
		self.justifyContent = justifyContent
		self.alignItems = alignItems
		self.alignContent = alignContent
		super.init()
	}
	
	public convenience init(spacing: CGFloat,
							justifyContent: JustifyContent = .start,
							alignItems: AlignItem = .start,
							alignContent: AlignContent = .start) {
		self.init(lineSpacing: spacing,
				  interitemSpacing: spacing,
				  justifyContent: justifyContent,
				  alignItems: alignItems,
				  alignContent: alignContent)
	}
	
	public override func simpleLayout(context: LayoutContext) -> [CGRect] {
		var frames: [CGRect] = []
		
		let sizes = (0..<context.numberOfItems).map { index in
			context.size(at: index, collectionSize: context.collectionSize)
		}
		let (totalHeight, lineData) = distributeLines(sizes: sizes, maxWidth: context.collectionSize.width)
		
		var (yOffset, spacing) = LayoutHelper.distribute(justifyContent: alignContent,
														 maxPrimary: context.collectionSize.height,
														 totalPrimary: totalHeight,
														 minimunSpacing: lineSpacing,
														 numberOfItems: lineData.count)
		
		var index = 0
		for (lineSize, count) in lineData {
			let (xOffset, lineInteritemSpacing) =
			LayoutHelper.distribute(justifyContent: justifyContent,
									maxPrimary: context.collectionSize.width,
									totalPrimary: lineSize.width,
									minimunSpacing: interitemSpacing,
									numberOfItems: count)
			
			let lineFrames = LayoutHelper.alignItem(alignItems: alignItems,
													startingPrimaryOffset: xOffset,
													spacing: lineInteritemSpacing,
													sizes: sizes[index..<(index + count)],
													secondaryRange: yOffset...(yOffset + lineSize.height))
			
			frames.append(contentsOf: lineFrames)
			
			yOffset += lineSize.height + spacing
			index += count
		}
		return frames
	}
	
	func distributeLines(sizes: [CGSize], maxWidth: CGFloat) ->
	(totalHeight: CGFloat, lineData: [(lineSize: CGSize, count: Int)]) {
		var lineData: [(lineSize: CGSize, count: Int)] = []
		var currentLineItemCount = 0
		var currentLineWidth: CGFloat = 0
		var currentLineMaxHeight: CGFloat = 0
		var totalHeight: CGFloat = 0
		for size in sizes {
			if currentLineWidth + size.width > maxWidth, currentLineItemCount != 0 {
				lineData.append((lineSize: CGSize(width: currentLineWidth - CGFloat(currentLineItemCount) * interitemSpacing,
												  height: currentLineMaxHeight),
								 count: currentLineItemCount))
				totalHeight += currentLineMaxHeight
				currentLineMaxHeight = 0
				currentLineWidth = 0
				currentLineItemCount = 0
			}
			currentLineMaxHeight = max(currentLineMaxHeight, size.height)
			currentLineWidth += size.width + interitemSpacing
			currentLineItemCount += 1
		}
		if currentLineItemCount > 0 {
			lineData.append((lineSize: CGSize(width: currentLineWidth - CGFloat(currentLineItemCount) * interitemSpacing,
											  height: currentLineMaxHeight),
							 count: currentLineItemCount))
			totalHeight += currentLineMaxHeight
		}
		return (totalHeight, lineData)
	}
}

public class XBaselineCenteringFlowLayout: VerticalSimpleLayout {
	public var lineSpacing: CGFloat
	public var interitemSpacing: CGFloat
	
	public override var description: String {
  """
FlowLayout:

lineSpacing:\(lineSpacing)
interitemSpacing:\(interitemSpacing)
"""
	}
	
	public init(lineSpacing: CGFloat = 0,
				interitemSpacing: CGFloat = 0) {
		self.lineSpacing = lineSpacing
		self.interitemSpacing = interitemSpacing
		super.init()
	}
	
	public convenience init(spacing: CGFloat) {
		self.init(lineSpacing: spacing,
				  interitemSpacing: spacing)
	}
	
	func distribute(minimalXOffset: CGFloat?,
					maxPrimary: CGFloat,
					totalPrimary: CGFloat,
					minimunSpacing: CGFloat,
					numberOfItems: Int) -> (offset: CGFloat, spacing: CGFloat) {
		var offset: CGFloat = 0
		var spacing = minimunSpacing
		guard numberOfItems > 0 else { return (offset, spacing) }
		if totalPrimary + CGFloat(numberOfItems - 1) * minimunSpacing < maxPrimary {
			let leftOverPrimary = maxPrimary - totalPrimary
			offset += (leftOverPrimary - minimunSpacing * CGFloat(numberOfItems - 1)) / 2
			if let minimalXOffset {
				offset = min(minimalXOffset, offset)
			}
		}
		return (offset, spacing)
	}
	
	public override func simpleLayout(context: LayoutContext) -> [CGRect] {
		var frames: [CGRect] = []
		
		let sizes = (0..<context.numberOfItems).map { index in
			context.size(at: index, collectionSize: context.collectionSize)
		}
		let (totalHeight, lineData) = distributeLines(sizes: sizes, maxWidth: context.collectionSize.width)
		
		var (yOffset, spacing) = LayoutHelper.distribute(justifyContent: .start,
														 maxPrimary: context.collectionSize.height,
														 totalPrimary: totalHeight,
														 minimunSpacing: lineSpacing,
														 numberOfItems: lineData.count)
		
		var index = 0
		var minimalXOffset: CGFloat = CGFloat.greatestFiniteMagnitude
		for (lineSize, count) in lineData {
			let (xOffset, _) =
			distribute(minimalXOffset: minimalXOffset,
					   maxPrimary: context.collectionSize.width,
					   totalPrimary: lineSize.width,
					   minimunSpacing: interitemSpacing,
					   numberOfItems: count)
			minimalXOffset = min(minimalXOffset, xOffset)
		}
		for (lineSize, count) in lineData {
			let (_, lineInteritemSpacing) =
			distribute(minimalXOffset: minimalXOffset,
					   maxPrimary: context.collectionSize.width,
					   totalPrimary: lineSize.width,
					   minimunSpacing: interitemSpacing,
					   numberOfItems: count)
			let lineFrames = LayoutHelper.alignItem(alignItems: .start,
													startingPrimaryOffset: minimalXOffset,
													spacing: lineInteritemSpacing,
													sizes: sizes[index..<(index + count)],
													secondaryRange: yOffset...(yOffset + lineSize.height))
			
			frames.append(contentsOf: lineFrames)
			
			yOffset += lineSize.height + spacing
			index += count
		}
		return frames
	}
	
	func distributeLines(sizes: [CGSize], maxWidth: CGFloat) ->
	(totalHeight: CGFloat, lineData: [(lineSize: CGSize, count: Int)]) {
		var lineData: [(lineSize: CGSize, count: Int)] = []
		var currentLineItemCount = 0
		var currentLineWidth: CGFloat = 0
		var currentLineMaxHeight: CGFloat = 0
		var totalHeight: CGFloat = 0
		for size in sizes {
			if currentLineWidth + size.width > maxWidth, currentLineItemCount != 0 {
				lineData.append((lineSize: CGSize(width: currentLineWidth - CGFloat(currentLineItemCount) * interitemSpacing,
												  height: currentLineMaxHeight),
								 count: currentLineItemCount))
				totalHeight += currentLineMaxHeight
				currentLineMaxHeight = 0
				currentLineWidth = 0
				currentLineItemCount = 0
			}
			currentLineMaxHeight = max(currentLineMaxHeight, size.height)
			currentLineWidth += size.width + interitemSpacing
			currentLineItemCount += 1
		}
		if currentLineItemCount > 0 {
			lineData.append((lineSize: CGSize(width: currentLineWidth - CGFloat(currentLineItemCount) * interitemSpacing,
											  height: currentLineMaxHeight),
							 count: currentLineItemCount))
			totalHeight += currentLineMaxHeight
		}
		return (totalHeight, lineData)
	}
}

public class ReversedLayout: VerticalSimpleLayout {
	
	var verticalSpacing: CGFloat
	
	public init(verticalSpacing: CGFloat = 0) {
		self.verticalSpacing = verticalSpacing
	}
	
	public func initialCollectionContentHeight(sizes: [CGSize]) -> CGFloat {
		sizes.enumerated().reduce(0, { accum, el in
			let (offset, size) = el
			if offset == 0 || offset == sizes.count - 1 {
				return accum + size.height
			} else {
				return accum + size.height + verticalSpacing
			}
		})
	}
	
	public override func simpleLayout(context: LayoutContext) -> [CGRect] {
		var frames: [CGRect] = []
		let sizes = (0..<context.numberOfItems).map { context.size(at: $0, collectionSize: context.collectionSize) }
		var initialY = initialCollectionContentHeight(sizes: sizes)
		sizes.enumerated().forEach({ offset, size in
			if offset == sizes.count - 1 {
				initialY -= size.height
				frames.append(CGRect(x: 0, y: initialY, width: size.width, height: size.height))
			} else {
				initialY -= size.height
				frames.append(CGRect(x: 0, y: initialY, width: size.width, height: size.height))
				initialY -= verticalSpacing
			}
		})
		return frames
	}
	
	open override func visibleIndexes(visibleFrame: CGRect, visibleFrameLessInset: CGRect) -> [Int] {
		var index = frames.binarySearch { $0.maxY > visibleFrame.minY } - 1
		var visibleIndexes = [Int]()
		while index >= 0 {
			let frame = frames[index]
			if frame.minY >= (visibleFrame.maxY + UIScreen.main.bounds.height) {
				break
			}
			if frame.maxY > visibleFrame.minY {
				visibleIndexes.append(index)
			}
			index -= 1
		}
		return visibleIndexes
	}
}
