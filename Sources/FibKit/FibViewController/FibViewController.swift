//
//  FormVC.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
import Combine
import UIKit
import VisualEffectView

open class FibViewController: UIViewController {

    // MARK: Properties
	
	public struct Configuration {
		public init(viewConfiguration: FibControllerRootView.Configuration = .init(),
					navigationConfiguration: FibControllerRootView.NavigationConfiguration = .init()) {
			self.viewConfiguration = viewConfiguration
			self.navigationConfiguration = navigationConfiguration
		}
		
		public var viewConfiguration: FibControllerRootView.Configuration = .init()
		public var navigationConfiguration: FibControllerRootView.NavigationConfiguration = .init()
	}
	
	public static var defaultConfiguration: Configuration = .init(
		viewConfiguration: .init(
			roundedShutterBackground: .secondarySystemBackground,
			shutterBackground: .systemBackground,
			viewBackgroundColor: .systemBackground,
			shutterType: .default,
			backgroundView: nil,
			topInsetStrategy: .safeArea
		),
		navigationConfiguration: .init(
			titleViewModel: nil,
			largeTitleViewModel: nil,
			searchContext: nil
		)
	)
	
	public var storedConfiguration = defaultConfiguration
	
	open var configuration: Configuration? {
		nil
	}

    open var rootView: FibControllerRootView! {
        (view as! FibControllerRootView)
    }

    open var haveError: Bool = false
    open var error: Error?
	public var reloadPublisher = PassthroughSubject<Void, Never>()

    open var reloadSectionsCompletion: (() -> Void)?
	
	open var body: SectionProtocol? { rootView.body ?? storedBody }
	open var storedBody: SectionProtocol? = nil {
		didSet {
			reload(animated: false)
		}
	}
	
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
		rootView.footer ?? storedFooter
    }

    open var storedHeader: FibViewHeaderViewModel? = nil {
        didSet {
            reload()
        }
    }

    /// Point to override
    open var header: FibViewHeaderViewModel? {
		rootView.header ?? storedHeader
    }

    /// Displayed when header == nil
    open var dummyHeaderClass: FibViewHeader.Type? {
        nil
    }

    // MARK: Initialization

    public init(provider: SectionProtocol? = nil) {
        storedBody = provider
        super.init(nibName: nil, bundle: nil)
		setReloadable()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
		setReloadable()
    }

    override open func loadView() {
        view = FibControllerRootView(controller: self)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        immediateReload(animated: false)
    }
	
	open override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		reload()
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
		debugPrint(message)
            return
        }
        rootView.refreshControl.endRefreshing()
        feedback.selectionChanged()
    }
	
	private lazy var reloadDebouncer = TaskDebouncer(delayType: .cyclesCount(6))
	
	private func immediateReload(completion: (() -> Void)? = nil, animated: Bool = true) {
		reloadFooter(animated: animated)
		reloadHeader(animated: animated)
		reloadSections(completion: completion, animated: animated)
		rootView.setNeedsLayout()
	}
	
	public func reload() {
		self.reload(completion: nil, animated: true)
	}

    open func reload(completion: (() -> Void)? = nil, animated: Bool = true) {
		reloadDebouncer.runDebouncedTask {[weak self] in
			self?.immediateReload(completion: completion, animated: animated)
		}
    }

    open func reloadFooter(animated: Bool = true) {
        rootView.display(footer, animated: animated)
    }

	public func showContextMenu(
		_ menu: ContextMenu,
		for view: UIView,
		isSecure: Bool = false
	) {
        PopoverService.showContextMenu(menu, view: view, gesture: nil, isSecure: isSecure)
    }

    open func reloadHeader(animated: Bool = true) {
        rootView.display(header, dummyHeaderClass: dummyHeaderClass, animated: animated)
    }

    open func reloadSections(completion: (() -> Void)? = nil, animated: Bool = true) {
        var provider = storedBody
        if storedBody == nil {
            provider = self.body
        }
        rootView.display(provider, animated: animated)
        reloadSectionsCompletion = completion
    }

    public func addRefreshAction(_ refreshAction: @escaping () -> Void) {
        self.refreshAction = refreshAction
    }

    public func displayEmptyView(_ viewModel: ViewModelWithViewClass, animated: Bool = true) {
        rootView.display(storedFooter ?? footer, animated: animated)
        rootView.display(header, dummyHeaderClass: dummyHeaderClass, animated: animated)
        rootView.displayEmptyView(viewModel, animated: animated)
    }

    open func viewDidReloadCollection(with height: CGFloat) {
        reloadSectionsCompletion?()
		reloadPublisher.send(())
        reloadSectionsCompletion = nil
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.rootView.scrollViewDidScroll(self.rootView.rootFormView)
        }
    }

	private func setReloadable() {
		var mir: Mirror? = Mirror(reflecting: self)
		while mir != nil {
			mir?.children.forEach({ child in
				if !(child.value is Any.Type),
				   let val = child.value as? HaveReloaderProp {
					val.reloader = {[weak self] in
						self?.reload()
					}
				}
			})
			mir = mir?.superclassMirror
		}
		
	}
}

fileprivate let session = UUID().uuidString
