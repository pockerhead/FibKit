//
//  CollectionReuseViewManager.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2017-07-21.
//  Copyright © 2017 lkzhao. All rights reserved.
//

import UIKit

// swiftlint:disable all
public protocol CollectionViewReusableView: AnyObject {
    func prepareForReuse()
}

public class CollectionReuseViewManager: NSObject {

    /// Time it takes for CollectionReuseViewManager to
    /// dump all reusableViews to save memory
    public var lifeSpan: TimeInterval = 20.0

    static var shared = CollectionReuseViewManager()

    /// When `removeFromCollectionViewWhenReuse` is enabled,
    /// cells will always be removed from Collection View during reuse.
    /// This is slower but it doesn't influence the `isHidden` property
    /// of individual cells.
    public var removeFromCollectionViewWhenReuse = false

    var reusableViews: [String: [UIView]] = [:]
    var cleanupTimer: Timer?

    public var generateAdditionalViewsForReuse = true
    public var numberOfAdditinalViewsForReuse: Int = 3

    public func prepareReuseIfNeeded<T: UIView>(type: T.Type) {
        let identifier = NSStringFromClass(type)
        guard generateAdditionalViewsForReuse && reusableViews[identifier]?.isEmpty == nil else {return}
        for _ in 0..<numberOfAdditinalViewsForReuse {
            queue(view: dequeue(viewClass: type.className, { FibGridViewSource.shared.getView(at: .max, with: nil, defaultClassName: (type as? ViewModelConfigurable.Type) ?? SpacerCell.self) } ))
        }
    }

    public func queue(view: UIView) {
        let identifier = NSStringFromClass(type(of: view))
        view.reuseManager = nil
        if removeFromCollectionViewWhenReuse {
            view.removeFromSuperview()
        } else {
            view.isHidden = true
        }
        if reusableViews[identifier] != nil && !reusableViews[identifier]!.contains(view) {
            reusableViews[identifier]?.append(view)
        } else {
            reusableViews[identifier] = [view]
        }
        if let cleanupTimer = cleanupTimer {
            cleanupTimer.fireDate = Date().addingTimeInterval(lifeSpan)
        } else {
            cleanupTimer = Timer.scheduledTimer(timeInterval: lifeSpan, target: self,
                                                selector: #selector(cleanup), userInfo: nil, repeats: false)
        }
    }

    public func dequeue<T: UIView> (_ defaultView: @autoclosure () -> T) -> T {
        let identifier = NSStringFromClass(T.self)
        let queuedView = reusableViews[identifier]?.popLast() as? T
        let view = queuedView ?? defaultView()
        if let view = view as? CollectionViewReusableView {
            view.prepareForReuse()
        }
        if !removeFromCollectionViewWhenReuse {
            view.isHidden = false
        }
        view.reuseManager = self
        return view
    }

    public func dequeue<T: UIView> (type: T.Type) -> T {
        return dequeue(type.init())
    }

    @objc func cleanup() {
        for views in reusableViews.values {
            for view in views {
                view.removeFromSuperview()
            }
        }
        reusableViews.removeAll()
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
}

extension CollectionReuseViewManager {

    public func dequeue(viewClass: String, _ defaultView: () -> UIView) -> UIView {
        let identifier = viewClass
        let view: UIView
        if let queuedView = reusableViews[identifier]?.popLast() {
            view = queuedView
        } else {
            view = defaultView()
        }
        if let view = view as? CollectionViewReusableView {
            view.prepareForReuse()
        }
        if !removeFromCollectionViewWhenReuse {
            view.isHidden = false
        }
        view.reuseManager = self
        return view
    }
}
