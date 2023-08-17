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
  var collectionView: FibRootGrid? { get set }
  func reloadData()
  func setNeedsReload()
}

extension CollectionReloadable {
  public var collectionView: FibRootGrid? {
    get {
        return CollectionViewManager.shared.collectionView(for: self)
    }
    set {
        ()
    }
  }
  public func reloadData() {
    collectionView?.reloadData()
  }
  public func setNeedsReload() {
    collectionView?.setNeedsReload()
  }
  public func setNeedsInvalidateLayout() {
    collectionView?.setNeedsInvalidateLayout()
  }
}

internal class CollectionViewManager {
  static let shared: CollectionViewManager = {
    FibRootGrid.swizzleAdjustContentOffset() // smartly using dispatch_once
    return CollectionViewManager()
  }()

  var collectionViews = NSHashTable<FibRootGrid>.weakObjects()

  func register(collectionView: FibRootGrid) {
    collectionViews.add(collectionView)
  }

  func collectionView(for reloadable: CollectionReloadable) -> FibRootGrid? {
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
    guard !(self is FibRootGrid) || !isDragging && !isDecelerating else { return }
    self.perform(#selector(FibRootGrid.collectionKitAdjustContentOffsetIfNecessary))
  }

  static func swizzleAdjustContentOffset() {
    let encoded = String("==QeyF2czV2Yl5kZJRXZzZmZPRnblRnbvNEdzVnakF2X".reversed())
    let originalMethodName = String(data: Data(base64Encoded: encoded)!, encoding: .utf8)!
    let originalSelector = NSSelectorFromString(originalMethodName)
    let swizzledSelector = #selector(FibRootGrid.collectionKitAdjustContentOffsetIfNecessary)
    let originalMethod = class_getInstanceMethod(self, originalSelector)
    let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
    method_exchangeImplementations(originalMethod!, swizzledMethod!)
  }
}
