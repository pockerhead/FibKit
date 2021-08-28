//
//  FormVC.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//



import UIKit
import VisualEffectView

open class FibViewController: UIViewController {

    // MARK: Properties
    
    public static var resolveClosure: ((UIViewController) -> Void)?

    open var shouldLoadViewOnInit: Bool { true }
    open var shouldResolve: Bool { true }

    open var rootView: FibControllerRootView! {
        (view as! FibControllerRootView)
    }

    open var roundedShutter: Bool { false }
    open var transparentNavbar: Bool { false }
    open var haveError: Bool = false
    open var error: Error?

    open var reloadSectionsCompletion: (() -> Void)?

    open var storedSections: [GridSection] = [] {
        didSet {
            reload()
        }
    }

    // swiftlint:disable implicit_return
    /// Point to override
    open var sections: [GridSection] {
        return storedSections
    }

    open var needBackgroundGradient: Bool { false }
    open var customBackgroundView: UIView? { nil }

    private var feedback = UISelectionFeedbackGenerator()

    open lazy var refreshAction: (() -> Void)? = nil

    open var storedFooter: FibCell.ViewModel? = nil {
        didSet {
           reload()
        }
    }

    open var needTransparentHeader: Bool { false }

    /// Point to override
    open var footer: FibCell.ViewModel? {
        storedFooter
    }

    open var storedHeader: FibViewHeaderViewModel? = nil {
        didSet {
            reload()
        }
    }

    /// Point to override
    open var header: FibViewHeaderViewModel? {
        storedHeader
    }

    /// Displayed when header == nil
    open var dummyHeaderClass: FibViewHeader.Type? {
        nil
    }

    // MARK: Initialization

    public init(sections: [GridSection] = []) {
        storedSections = sections
        super.init(nibName: nil, bundle: nil)
        if shouldResolve {
            FibViewController.resolveClosure?(self)
        }
        if shouldLoadViewOnInit && !isViewLoaded {
            loadViewIfNeeded()
        }
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        if shouldResolve {
            FibViewController.resolveClosure?(self)
        }
    }

    override open func loadView() {
        view = FibControllerRootView(controller: self)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        reload(animated: false)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.clear()
    }

    // MARK: View's input

    public func endRefreshing() {
        guard rootView.refreshControl.isRefreshing else {
            let message =
"""
endRefreshing was called when refreshControl is not refreshing!
NOTE: If you should call endRefreshing, refresh control must be in
refreshing state, because one 'endRefreshing' - one feedback 'selectionChanged' call
"""
            log.warning(message)
            return
        }
        rootView.refreshControl.endRefreshing()
        feedback.selectionChanged()
    }

    open func reload(completion: (() -> Void)? = nil, animated: Bool = true) {
        rootView.needTransparentHeader = needTransparentHeader
        rootView.transparentNavbar = transparentNavbar
        rootView.needBackgroundGradient = needBackgroundGradient
        rootView.customBackgroundView = customBackgroundView
        rootView.roundedShutter = roundedShutter
        reloadFooter(animated: animated)
        reloadHeader(animated: animated)
        reloadSections(completion: completion, animated: animated)
    }

    open func reloadFooter(animated: Bool = true) {
        rootView.display(footer, animated: animated)
    }

    public func showContextMenu(_ menu: ContextMenu, for view: UIView) {
        PopoverService.showContextMenu(menu, view: view, controller: self)
    }

    open func reloadHeader(animated: Bool = true) {
        rootView.display(header, dummyHeaderClass: dummyHeaderClass, animated: animated)
    }

    open func reloadSections(completion: (() -> Void)? = nil, animated: Bool = true) {
        var sections = storedSections
        if storedSections.isEmpty {
            sections = self.sections
        }
        rootView.display(sections, animated: animated)
        reloadSectionsCompletion = completion
    }

    public func addRefreshAction(_ refreshAction: @escaping () -> Void) {
        self.refreshAction = refreshAction
    }

//    public func displayEmptyView(_ viewModel: InfoMessageView.ViewModel, animated: Bool = true) {
//        rootView.display(storedFooter ?? footer, animated: animated)
//        rootView.display(header, dummyHeaderClass: dummyHeaderClass, animated: animated)
//        rootView.displayEmptyView(viewModel, animated: animated)
//    }

    open func viewDidReloadCollection(with height: CGFloat) {
        reloadSectionsCompletion?()
        reloadSectionsCompletion = nil
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.rootView.scrollViewDidScroll(self.rootView.rootFormView)
        }
    }

}
