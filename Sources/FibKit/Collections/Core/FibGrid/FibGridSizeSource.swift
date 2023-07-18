//
//  FormViewSizeSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all


import UIKit

public let _fHashToNoStoreSize = "com.pockerhead.formView_fHashToNoStoreSize"

public final class FibGridSizeSource {
	
	public init() {}
	
	var cachedSizes: [String: CGSize] = [:]
	
	func size(at index: Int,
			  data: ViewModelWithViewClass?,
			  collectionSize: CGSize,
			  dummyView: ViewModelConfigurable,
			  direction: UICollectionView.ScrollDirection) -> CGSize {
		let nonNilIdentifier = "\(dummyView.self.className)_sizeAt-\(index)_withId-\(data?.id ?? "noID")-\(UIDevice.current.orientation.rawValue)"
		let hashToFindCachedSize = (data?.sizeHash ?? "") + nonNilIdentifier
		let forcedNoStoreSize = data?.sizeHash == _fHashToNoStoreSize
		var size = CGSize.zero
		if !forcedNoStoreSize, let cachedSize = cachedSizes[hashToFindCachedSize] {
			if direction == .vertical && cachedSize.width == 0 {
				size = CGSize(width: collectionSize.width, height: cachedSize.height)
			} else if direction == .horizontal && cachedSize.height == 0 {
				size = CGSize(width: cachedSize.width, height: collectionSize.height)
			} else {
				size = cachedSize
			}
		} else {
			var horizontalPriority = UILayoutPriority.required
			var verticalPriority = UILayoutPriority.required
			var targetSize = collectionSize
			
			
			if direction == .vertical {
				mainOrSync {
					dummyView.frame.size.width = targetSize.width
				}
				verticalPriority = .fittingSizeLevel
				targetSize.height = .greatestFiniteMagnitude
			} else {
				mainOrSync {
					dummyView.frame.size.height = targetSize.height
				}
				horizontalPriority = .fittingSizeLevel
				targetSize.width = .greatestFiniteMagnitude
			}
			
			if var dummySize = dummyView.backgroundSizeWith(targetSize, data: data, horizontal: horizontalPriority, vertical: verticalPriority) {
				if direction == .horizontal {
					dummySize.height = dummySize.height.rounded(.down)
				} else {
					dummySize.width = dummySize.width.rounded(.down)
				}
				if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
					cachedSizes[hashToFindCachedSize] = dummySize
				}
				size = dummySize
			} else {
				mainOrSync {
					if var dummySize = dummyView.sizeWith(targetSize, data: data, horizontal: horizontalPriority, vertical: verticalPriority) {
						if direction == .horizontal {
							dummySize.height = dummySize.height.rounded(.down)
						} else {
							dummySize.width = dummySize.width.rounded(.down)
						}
						if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
							self.cachedSizes[hashToFindCachedSize] = dummySize
						}
						size = dummySize
					} else if var dummySize = dummyView.sizeWith(targetSize, data: data) {
						if direction == .horizontal {
							dummySize.height = dummySize.height.rounded(.down)
						} else {
							dummySize.width = dummySize.width.rounded(.down)
						}
						if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
							self.cachedSizes[hashToFindCachedSize] = dummySize
						}
						size = dummySize
					} else {
						if let dummyView = dummyView as? ViewModelConfigururableFromSizeWith {
							dummyView.configure(with: data, isFromSizeWith: true)
						} else {
							dummyView.configure(with: data)
						}
						size = dummyView.systemLayoutSizeFitting(targetSize,
																 withHorizontalFittingPriority: horizontalPriority,
																 verticalFittingPriority: verticalPriority)
						if direction == .horizontal {
							size.height = size.height.rounded(.down)
						} else {
							size.width = size.width.rounded(.down)
						}
						if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
							self.cachedSizes[hashToFindCachedSize] = size
						}
					}
				}
			}
		}
		data?.getSizeClosure?(size)
		return size
	}
}
