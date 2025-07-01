//
//  CollectionReloadable.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-07-25.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

// swiftlint:disable all
public protocol CollectionReloadable: AnyObject {
	var collectionView: FibGrid? { get set }
	func reloadData()
	func setNeedsReload()
}

extension CollectionReloadable {
	@MainActor public var collectionView: FibGrid? {
		get {
			return CollectionViewManager.shared.collectionView(for: self)
		}
		set {
			()
		}
	}
	@MainActor public func reloadData() {
		collectionView?.reloadData()
	}
	@MainActor public func setNeedsReload() {
		collectionView?.setNeedsReload()
	}
	@MainActor public func setNeedsInvalidateLayout() {
		collectionView?.setNeedsInvalidateLayout()
	}
}

internal class CollectionViewManager {
	static let shared: CollectionViewManager = {
		FibGrid.swizzleAdjustContentOffset() // smartly using dispatch_once
		return CollectionViewManager()
	}()
	
	var collectionViews = NSHashTable<FibGrid>.weakObjects()
	
	func register(collectionView: FibGrid) {
		collectionViews.add(collectionView)
	}
	
	@MainActor func collectionView(for reloadable: CollectionReloadable) -> FibGrid? {
		for collectionView in collectionViews.allObjects {
			if let provider = collectionView.provider, provider.hasReloadable(reloadable) {
				return collectionView
			}
		}
		return nil
	}
}

// https://github.com/SoySauceLab/CollectionKit/issues/63
// UIScrollView has a weird behavior where its contentOffset resets to .zero when
// frame is assigned.
// this swizzling fixed the issue. where the scrollview would jump during scroll
extension UIScrollView {
	@objc func collectionKitAdjustContentOffsetIfNecessary(_ animated: Bool) {
		guard !(self is FibGrid) || !isDragging && !isDecelerating else { return }
		self.perform(#selector(FibGrid.collectionKitAdjustContentOffsetIfNecessary))
	}
	
	static func swizzleAdjustContentOffset() {
		let encoded = String("==QeyF2czV2Yl5kZJRXZzZmZPRnblRnbvNEdzVnakF2X".reversed())
		let originalMethodName = String(data: Data(base64Encoded: encoded)!, encoding: .utf8)!
		let originalSelector = NSSelectorFromString(originalMethodName)
		let swizzledSelector = #selector(FibGrid.collectionKitAdjustContentOffsetIfNecessary)
		let originalMethod = class_getInstanceMethod(self, originalSelector)
		let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
		method_exchangeImplementations(originalMethod!, swizzledMethod!)
	}
}
