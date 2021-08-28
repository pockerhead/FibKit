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
        if !forcedNoStoreSize, let cachedSize = cachedSizes[hashToFindCachedSize] {
            if direction == .vertical && cachedSize.width == 0 {
                return CGSize(width: collectionSize.width, height: cachedSize.height)
            } else if direction == .horizontal && cachedSize.height == 0 {
                return CGSize(width: cachedSize.width, height: collectionSize.height)
            }
            return cachedSize
        }
        var horizontalPriority = UILayoutPriority.required
        var verticalPriority = UILayoutPriority.required
        var targetSize = collectionSize

        if direction == .vertical {
            dummyView.frame.size.width = targetSize.width
            verticalPriority = .fittingSizeLevel
            targetSize.height = .greatestFiniteMagnitude
        } else {
            dummyView.frame.size.height = targetSize.height
            horizontalPriority = .fittingSizeLevel
            targetSize.width = .greatestFiniteMagnitude
        }
        
        if var size = dummyView.sizeWith(targetSize, data: data, horizontal: horizontalPriority, vertical: verticalPriority) {
            if direction == .horizontal {
                size.height = size.height - 1
            }
            if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
                cachedSizes[hashToFindCachedSize] = size
            }
            return size
        }
        
        if var size = dummyView.sizeWith(targetSize, data: data) {
            if direction == .horizontal {
                size.height = size.height - 1
            }
            if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
                cachedSizes[hashToFindCachedSize] = size
            }
            return size
        }
        dummyView.configure(with: data)
        var size = dummyView.systemLayoutSizeFitting(targetSize,
                                                     withHorizontalFittingPriority: horizontalPriority,
                                                     verticalFittingPriority: verticalPriority)
        if direction == .horizontal {
            size.height = size.height - 1
        }
        if targetSize.width > 0 && targetSize.height > 0, !forcedNoStoreSize {
            cachedSizes[hashToFindCachedSize] = size
        }
        return size
    }
}
