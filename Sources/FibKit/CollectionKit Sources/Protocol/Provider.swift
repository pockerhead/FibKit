//
//  Provider.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-07-23.
//  Copyright © 2017 lkzhao. All rights reserved.
//
// swiftlint:disable all

import UIKit

public protocol Provider: CustomStringConvertible {
    var identifier: String? { get set }

    // data
    var numberOfItems: Int { get }
    var animator: Animator? { get set }

    func identifier(at: Int) -> String

    // layout
    func layout(collectionSize: CGSize)
	func visibleIndexes(visibleFrame: CGRect, visibleFrameLessInset: CGRect) -> [Int]

    var contentSize: CGSize { get }

    func frame(at: Int) -> CGRect

    // event
    func willReload()
    func didReload()

    func animator(at: Int) -> Animator?

    // determines if a context belongs to current provider
    func hasReloadable(_ reloadable: CollectionReloadable) -> Bool

    func flattenedProvider() -> ItemProvider
}

extension Provider {
    public func willReload() {}
    public func didReload() {}
    public var animator: Animator? { get { nil } set {} }
}
