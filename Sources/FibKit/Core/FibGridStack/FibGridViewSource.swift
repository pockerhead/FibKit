//
//  FormViewSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all


import UIKit

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(bundle: Bundle = .main,
                                                      at index: Int,
                                                      nibName: String = T.className,
                                                      needRegister: Bool = false) -> T? {
        if needRegister {
            let nib = UINib(nibName: nibName,
                            bundle: bundle)
            register(nib, forCellWithReuseIdentifier: nibName)
        }
        return dequeueReusableCell(withReuseIdentifier: nibName,
                                   for: IndexPath(item: index, section: 0)) as? T
    }
}

extension ViewModelConfigurable where Self: UIView {

    public static func fromDequeuer() -> Self? {
        CollectionViewDequeuer.shared.dequeueReusableCell(viewClass: Self.self) as? Self
    }
}

extension ViewModelWithViewClass {
    public func getView() -> ViewModelConfigurable? {
        let view = viewClass().fromDequeuer()
        if let view = view as? ViewModelConfigururableFromSizeWith {
            view.configure(with: self, isFromSizeWith: false)
        } else {
            view?.configure(with: self)
        }
        view?.alpha = 1
        return view
    }
    
    public func getView<T: ViewModelConfigurable>(type: T.Type = T.self) -> T? {
        let view = viewClass().fromDequeuer() as? T
        if let view = view as? ViewModelConfigururableFromSizeWith {
            view.configure(with: self, isFromSizeWith: false)
        } else {
            view?.configure(with: self)
        }
        view?.alpha = 1
        return view
    }
    
    public func getViewUnsafe<T: ViewModelConfigurable>(type: T.Type = T.self) -> T {
        let view = viewClass().fromDequeuer() as! T
        if let view = view as? ViewModelConfigururableFromSizeWith {
            view.configure(with: self, isFromSizeWith: false)
        } else {
            view.configure(with: self)
        }
        view.alpha = 1
        return view
    }
}

typealias HasNibBool = (moduleBundle: Bool, selfBundle: Bool)

public class CollectionViewDequeuer: NSObject {

    public static let shared = CollectionViewDequeuer()

	private static var hasNibDictionary: [String: HasNibBool] = [:]

    override init() {}

    public func dequeueReusableCell(viewClass: ViewModelConfigurable.Type) -> ViewModelConfigurable? {
        let className = viewClass.className
        guard let hasNib = CollectionViewDequeuer.hasNibDictionary[className] else {
            CollectionViewDequeuer.hasNibDictionary[className] = (viewClass.moduleBundle.path(forResource: className, ofType: "nib") != nil, viewClass.selfBundle.path(forResource: className, ofType: "nib") != nil)
            return dequeReusableCell(hasNib: CollectionViewDequeuer.hasNibDictionary[className]!, viewClass: viewClass)
        }
        return  dequeReusableCell(hasNib: hasNib,
                                  viewClass: viewClass)
    }

    private func dequeReusableCell(hasNib: HasNibBool,
                                   viewClass: ViewModelConfigurable.Type) -> ViewModelConfigurable? {
		guard hasNib.moduleBundle || hasNib.selfBundle else {
			return viewClass.init()
		}
		let cell: ViewModelConfigurable
		if hasNib.selfBundle, let selfCell = viewClass.fromNib(owner: self, bundle: viewClass.selfBundle) as? ViewModelConfigurable {
			cell = selfCell
		} else if hasNib.moduleBundle, let moduleCell = viewClass.fromNib(owner: self, bundle: viewClass.moduleBundle) as? ViewModelConfigurable {
			cell = moduleCell
		} else {
			return viewClass.init()
		}
        cell.alpha = 0
        return cell
    }
}

open class FibGridViewSource {

    static public let shared = FibGridViewSource()
    public lazy var reuseManager = CollectionReuseViewManager()
    var dummyViewSource = GridsReuseManager.shared.dummyViews
    var nilDataDummyViewClass: ViewModelConfigurable.Type?
    var embedCollectionsSource: [String: UIView] = [:]
    var collectionViewDequeuer = CollectionViewDequeuer()

    /// Should return a new view for the given data and index
    public func view(data: ViewModelWithViewClass?,
                     index: Int) -> ViewModelConfigurable {
        let defaultView = { self.getView(at: index, with: data) }
        let view = reuseManager.dequeue(viewClass: NSStringFromClass(data?.viewClass() ?? nilDataDummyViewClass ?? UIView.self), defaultView) as! ViewModelConfigurable
        let configuredDataOrNil: ViewModelWithViewClass? = data?.showDummyView == true ? nil : data
        view.fb_isHeader = false
        update(view: view, data: configuredDataOrNil, index: index)
        return view
    }

    func getView(at index: Int,
                 with data: ViewModelWithViewClass?,
                 defaultClassName: ViewModelConfigurable.Type = SpacerCell.self) -> ViewModelConfigurable {
        guard let data = data else {
            let view = collectionViewDequeuer.dequeueReusableCell(viewClass: nilDataDummyViewClass ?? defaultClassName)
            return view!
        }
        let opType = data.viewClass()
        var cell: ViewModelConfigurable
        if let reusableCell = collectionViewDequeuer.dequeueReusableCell(viewClass: opType) {
            cell = reusableCell
            if dummyViewSource[opType.className] == nil,
                let collectionViewCell = collectionViewDequeuer.dequeueReusableCell(viewClass: opType) {
                dummyViewSource[opType.className] = collectionViewCell
            }
        } else {
            let viewClass = data.viewClass()
            let viewClassString = viewClass.className
            let viewToDequeue = viewClass.init()
            if dummyViewSource[viewClassString] == nil {
                dummyViewSource[viewClassString] = viewClass.init()
            }
            cell = viewToDequeue
        }
        return cell
    }

    func getDummyView(data: ViewModelWithViewClass?) -> UIView {
        guard let data = data else {
            let view = collectionViewDequeuer.dequeueReusableCell(viewClass: nilDataDummyViewClass ?? SpacerCell.self)
            return view ?? UIView()
        }
        let opType = data.viewClass()
        guard dummyViewSource[opType.className] == nil else {
            return dummyViewSource[opType.className]!
        }
        var cell: UIView
        if let reusableCell = collectionViewDequeuer.dequeueReusableCell(viewClass: opType) {
            cell = reusableCell
            if dummyViewSource[opType.className] == nil {
                dummyViewSource[opType.className] = reusableCell
            }
        } else {
            let viewClass = data.viewClass()
            let viewClassString = viewClass.className
            let viewToDequeue = viewClass.init()
            if dummyViewSource[viewClassString] == nil {
                dummyViewSource[viewClassString] = viewToDequeue
            }
            cell = viewToDequeue
        }
        return cell
    }

    /// Should update the given view with the provided data and index
    func update(view: ViewModelConfigurable,
                data: ViewModelWithViewClass?,
                index: Int) {
        if let view = view as? ViewModelConfigururableFromSizeWith {
            view.configure(with: data, isFromSizeWith: false)
        } else {
            view.configure(with: data)
        }
        view.setNeedsLayout()
    }

    public init(dummyViewNilClass: ViewModelConfigurable.Type? = nil,
                useSharedReuseManager: Bool = true) {
        self.nilDataDummyViewClass = dummyViewNilClass
        reuseManager = useSharedReuseManager ? .shared : .init()
    }
}

extension FibGridViewSource: AnyViewSource {
    public final func anyView(data: Any,
                              index: Int) -> UIView {
        return view(data: data as? ViewModelWithViewClass, index: index)
    }

    public final func anyUpdate(view: UIView,
                                data: Any,
                                index: Int) {
        return update(view: view as! ViewModelConfigurable, data: data as? ViewModelWithViewClass, index: index)
    }
}

extension UIView {
    func removeAllGestures() {
        gestureRecognizers?.forEach { gest in
            removeGestureRecognizer(gest)
        }
    }
}
