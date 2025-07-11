//
//  ComposedProvider.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-07-20.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

// swiftlint:disable all
open class ComposedProvider: SectionProvider, LayoutableProvider, CollectionReloadable {
  public var description: String {String(describing: ComposedProvider.self)}
  open var identifier: String?
  open var sections: [Provider] { didSet {
	  Task {@MainActor in
		  setNeedsReload()
	  }
  } }
	open var animator: Animator? { didSet { Task {@MainActor in setNeedsReload()} } }
	open var layout: Layout { didSet { Task{@MainActor in setNeedsInvalidateLayout()} } }

  public init(identifier: String? = nil,
              layout: Layout = FlowLayout(),
              animator: Animator? = nil,
              sections: [Provider] = []) {
    self.animator = animator
    self.layout = layout
    self.sections = sections
    self.identifier = identifier
  }

  open var numberOfItems: Int {
    return sections.count
  }

  open func section(at: Int) -> Provider? {
    return sections[at]
  }

  open func identifier(at: Int) -> String {
    return sections[at].identifier ?? "\(at)"
  }

  open func layoutContext(collectionSize: CGSize) -> LayoutContext {
    return CollectionComposerLayoutContext(
      collectionSize: collectionSize,
      sections: sections
    )
  }

  open func animator(at: Int) -> Animator? {
    return animator
  }

  open func willReload() {
    for section in sections {
      section.willReload()
    }
  }

  open func didReload() {
    for section in sections {
      section.didReload()
    }
  }

  open func hasReloadable(_ reloadable: CollectionReloadable) -> Bool {
    return reloadable === self || sections.contains(where: { $0.hasReloadable(reloadable) })
  }
}

struct CollectionComposerLayoutContext: LayoutContext {
  var collectionSize: CGSize
  var sections: [Provider]

  var numberOfItems: Int {
    return sections.count
  }
  func data(at: Int) -> Any {
    return sections[at]
  }
  func identifier(at: Int) -> String {
    return sections[at].identifier ?? "\(at)"
  }
  func size(at: Int, collectionSize: CGSize) -> CGSize {
    sections[at].layout(collectionSize: collectionSize)
    return sections[at].contentSize
  }
}
