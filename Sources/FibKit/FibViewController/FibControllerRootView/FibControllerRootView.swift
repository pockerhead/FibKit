//
//  FormVCRootView.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit
import VisualEffectView

open class FibControllerRootView: UIView {
		
	private var defaultConfiguration: Configuration { FibViewController.defaultConfiguration.viewConfiguration
	}
	// MARK: - APPEARANCE
	
	var navigationConfiguration: FibControllerRootView.NavigationConfiguration? {
		controller?.configuration?.navigationConfiguration ?? FibViewController.defaultConfiguration.navigationConfiguration
	}
	
	var headerBackgroundViewColor: UIColor? {
		controller?.configuration?.viewConfiguration.headerBackgroundViewColor ?? defaultConfiguration.headerBackgroundViewColor
	}
	var headerBackgroundEffectView: (() -> UIView?)? {
		controller?.configuration?.viewConfiguration.headerBackgroundEffectView ?? defaultConfiguration.headerBackgroundEffectView
	}
	var roundedShutterBackground: UIColor? {
		controller?.configuration?.viewConfiguration.roundedShutterBackground ?? defaultConfiguration.roundedShutterBackground
	}
	var shutterBackground: UIColor? {
		controller?.configuration?.viewConfiguration.shutterBackground ?? defaultConfiguration.shutterBackground
	}
	var viewBackgroundColor: UIColor? {
		controller?.configuration?.viewConfiguration.viewBackgroundColor ?? defaultConfiguration.viewBackgroundColor
	}
	var shutterType: Shutter {
		controller?.configuration?.viewConfiguration.shutterType ?? defaultConfiguration.shutterType ?? .default
	}
	var backgroundView: (() -> UIView?)? {
		controller?.configuration?.viewConfiguration.backgroundView ?? defaultConfiguration.backgroundView
	}
	var backgroundViewInsets: UIEdgeInsets {
		controller?.configuration?.viewConfiguration.backgroundViewInsets ?? defaultConfiguration.backgroundViewInsets
	}
	
	var topInsetStrategy: TopInsetStrategy {
		controller?.configuration?.viewConfiguration.topInsetStrategy ?? defaultConfiguration.topInsetStrategy ?? .safeArea
	}
	var shutterShadowClosure: ((ShutterView) -> Void)? {
		controller?.configuration?.viewConfiguration.shutterShadowClosure ?? defaultConfiguration.shutterShadowClosure
	}
	
	// MARK: Dependencies
	weak open var controller: FibViewController?
	
	// MARK: Properties
	
	public let rootFormView = FibGrid()
	private let rootGridViewBackground = RootGridViewBackground()
	private var _backgroundViewRef: UIView?
	
	public let footer = FibCell()
	private let _sizeWithFooter = FibCell()
	private var _footerViewModel: ViewModelWithViewClass?
	private let rootFooterBackground = RootGridViewBackground()

	public weak var proxyDelegate: UIScrollViewDelegate?
	
	public private(set) var footerHeight: CGFloat = 0
	
	public var header: FibViewHeader?
	private let rootNavigationHeaderBackground = RootGridViewBackground()
	private let rootNavigationHeaderMask = UIView().backgroundColor(.black)
	private weak var largeViewRef: ViewModelConfigurable?
	private let rootHeaderBackground = RootGridViewBackground()
	private var rootHeaderBackgroundEffectView: UIView?
	private var _rootHeaderBackgroundViewRef: UIView?
	private let headerViewSource = FibGridViewSource()
	private let headerSizeSource = FibGridSizeSource()
	public let shutterView = ShutterView()
	
	public private(set) var isSearching = false
	private lazy var searchBar = UISearchBar()
	private var navItemLeftItemsRef: [UIBarButtonItem]? = []
	private var navItemRightItemsRef: [UIBarButtonItem]? = []
	private var navItemTitleView: UIView?
	var headerHeight: CGFloat = 0
	var headerTopMargin: CGFloat = 0
	let gridMaskView = UIView()
			
	internal var _headerInitialHeight: CGFloat?
	var _headerViewModel: FibViewHeaderViewModel?
	public lazy var refreshControl: UIRefreshControl = {
		let control = UIRefreshControl()
		control.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
		return control
	}()
	
	public let headerObserver = HeaderObserver()
	
	var scrollView: UIScrollView? {
		rootFormView
	}
	
	// MARK: Initialization
	
	public init(controller: FibViewController?) {
		super.init(frame: .zero)
		self.controller = controller
		configureUI()
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	// MARK: UI Configuration
	
	private func configureUI() {
		configureFormView()
		configureFooter()
		configureHeaderBackground()
		rootFormView.containedRootView = self
		applyAppearance()
	}
	
	func configureHeaderBackground() {
		addSubview(rootHeaderBackground)
		bringSubviewToFront(rootHeaderBackground)
	}
	
	func configureFormView() {
		addSubview(rootGridViewBackground)
		rootGridViewBackground.addSubview(rootFormView)
		rootFormView.clipsToBounds = true
		rootFormView.layer.masksToBounds = true
		rootFormView.contentInsetAdjustmentBehavior = .always
		rootGridViewBackground.insertSubview(shutterView, belowSubview: rootFormView)
		rootFormView.delegate = self
		assignRefreshControlIfNeeded()
		rootFormView.didReload {[weak self] in
			guard let self = self else { return }
			self.controller?.viewDidReloadCollection(with: self.fullContentHeight())
		}
		gridMaskView.backgroundColor = .black
		rootGridViewBackground.mask = gridMaskView
	}
	
	func assignRefreshControlIfNeeded() {
		if controller?.refreshAction != nil {
			rootFormView.refreshControl = refreshControl
		} else {
			rootFormView.refreshControl = nil
		}
	}
	
	public func getShutterColor() -> UIColor? {
		switch shutterType {
		case .default:
			return shutterBackground
		case .rounded:
			return roundedShutterBackground
		}
	}
	
	internal func configureShutterViewFrame() {
		let topInset = topInsetStrategy.getTopInset(for: self)
		let topEdge = topInset - shutterView.layer.cornerRadius
		let height = UIScreen.main.bounds.height * 2
		let shutterViewY = (rootFormView.frame.origin.y - rootFormView.contentOffset.y).clamp(topEdge, .greatestFiniteMagnitude)
		shutterView.frame = CGRect(x: rootFormView.frame.origin.x,
								   y: shutterViewY,
								   width: rootFormView.frame.width,
								   height: height)
		shutterView.backgroundColor = getShutterColor()
		switch shutterType {
		case .default:
			shutterView.layer.cornerRadius = 0
			shutterView.layer.clearShadow()
		case .rounded:
			shutterView.layer.cornerRadius = 16
			shutterView.layer.masksToBounds = false
			shutterView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
			shutterShadowClosure?(shutterView)
		}
		let mask = CAShapeLayer()
		let maskOriginY = min(rootFormView.frame.origin.y - shutterViewY, shutterView.layer.cornerRadius)
		mask.path = UIBezierPath(
			rect: CGRect(x: 0,
						 y: maskOriginY,
						 width: UIScreen.main.bounds.width,
						 height: UIScreen.main.bounds.height * 2)
		).cgPath
		shutterView.layer.mask = mask
	}
	
	func layoutFibGrid(animated: Bool) {
		if !animated {
			UIView.performWithoutAnimation {
				rootFormView.frame = bounds
				rootFormView.contentInset.bottom = footerHeight
			}
		}
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		UIView.performWithoutAnimation {
			rootGridViewBackground.frame = bounds
			configureShutterViewFrame()
		}
		configureNavigation()
		configureBackgroundView()
		configureHeaderEffectsBackgroundView()
		calculateHeaderFrame()
		updateHeaderFrame()
		updateFooterFrame()
		if needsConfigureFooter {
			needsConfigureFooter = false
			DispatchQueue.main.async {[weak self] in
				guard let self = self else { return }
				if let footer = footer as? ViewModelConfigururableFromSizeWith {
					footer.configure(with: _footerViewModel, isFromSizeWith: false)
				} else {
					footer.configure(with: _footerViewModel)
				}
			}
			applyAppearance()
		}
		if needsConfigureHeader {
			needsConfigureHeader = false
			DispatchQueue.main.async {[weak self] in
				guard let self = self else { return }
				if let header = header as? ViewModelConfigururableFromSizeWith {
					header.configure(with: _headerViewModel, isFromSizeWith: false)
				} else {
					header?.configure(with: _headerViewModel)
				}
			}
		}
		layoutFibGrid(animated: false)
		let gridMaskTop = shutterType == .default ? 0 : topInsetStrategy.getTopInset(for: self)
		// #crutch need maskTop + 0.01, because full view mask and blur
		// background is not friends at all
		gridMaskView.frame = .init(origin: .init(x: 0, y: gridMaskTop + 0.01),
								   size: .init(width: bounds.width, height: bounds.height))
	}
	
	func configureNavigation() {
		guard let nav = controller?.navigationController else { return }
		var needUpdateContentInsets = false
		rootHeaderBackground.addSubview(rootNavigationHeaderBackground)
		if let header = header {
			rootHeaderBackground.insertSubview(rootNavigationHeaderBackground, belowSubview: header)
		} else {
			rootHeaderBackground.bringSubviewToFront(rootNavigationHeaderBackground)
		}
		if let largeTitleViewModel = navigationConfiguration?.largeTitleViewModel {
			if let largeViewRef = largeViewRef {
				if String(describing: largeTitleViewModel.viewClass()) != String(describing: type(of: largeViewRef)) {
					largeViewRef.removeFromSuperview()
					if let newLargeView = largeTitleViewModel.getView() {
						self.largeViewRef = newLargeView
						rootNavigationHeaderBackground.addSubview(newLargeView)
						needUpdateContentInsets = true
					}
				} else {
					largeViewRef.configure(with: largeTitleViewModel)
				}
			} else if let newLargeView = largeTitleViewModel.getView() {
				self.largeViewRef = newLargeView
				rootNavigationHeaderBackground.addSubview(newLargeView)
				needUpdateContentInsets = true
			}
			
		} else if let title = navigationConfiguration?.title {
			if largeViewRef?.superview != nil {
				largeViewRef?.removeFromSuperview()
				needUpdateContentInsets = true
			}
			controller?.setNavbarTitle(title)
		}
		if let context = navigationConfiguration?.searchContext {
			searchBar.delegate = self
			searchBar.placeholder = context.placeholder
			searchBar.backgroundColor = .clear
			searchBar.backgroundImage = UIImage()
			if let force = context.isForceActive {
				if force && !searchBar.isFirstResponder {
					isSearching = true
					searchBar.becomeFirstResponder()
					searchBarTextDidBeginEditing(searchBar)
				} else if !force && searchBar.isFirstResponder {
					isSearching = false
					searchBar.resignFirstResponder()
					searchBarCancelButtonClicked(searchBar)
				}
			} else if !isSearching, searchBar.superview == nil {
				rootNavigationHeaderBackground.addSubview(searchBar)
				needUpdateContentInsets = true
			}
		} else if searchBar.superview != nil {
			searchBar.removeFromSuperview()
			needUpdateContentInsets = true
		}
		assignNavigationFramesIfNeeded()
		if needUpdateContentInsets {
			updateFormViewInsets(animated: false)
		}
	}
	
	let searchBarHeight: CGFloat = 66
	
	func assignNavigationFramesIfNeeded() {
		UIView.performWithoutAnimation {
			largeViewRef?.isHidden = isSearching
			let scrollViewShift = max(0.01, rootFormView.contentOffset.y + rootFormView.adjustedContentInset.top)
			if let largeTitleViewModel = navigationConfiguration?.largeTitleViewModel {
				let height = headerSizeSource.size(
					at: 0,
					data: largeTitleViewModel,
					collectionSize: bounds.size,
					dummyView: headerViewSource.getDummyView(data: largeTitleViewModel) as! ViewModelConfigurable,
					direction: .vertical).height
				self.largeViewRef?.frame = .init(origin: .init(x: 0.01, y: 0.01 - scrollViewShift), size: .init(width: bounds.width, height: height))
				if (largeViewRef?.superview?.convert(largeViewRef?.frame ?? .zero, to: self).maxY ?? 0) < safeAreaInsets.top {
					controller?.setNavbarTitle(navigationConfiguration?.title)
				} else {
					controller?.setNavbarTitle(nil)
				}
			}
			if !isSearching,
			   let searchContext = navigationConfiguration?.searchContext, (searchContext.isForceActive ?? false) == false {
				
				let largeViewShift = largeViewRef?.frame.maxY
				var searchBarPositionY: CGFloat = largeViewShift ?? scrollViewShift
				if !searchContext.hideWhenScrolling {
					searchBarPositionY = max(searchBarPositionY, 0.01)
				}
				self.searchBar.frame = .init(
					origin: .init(x: 8, y: searchBarPositionY),
					size: .init(width: self.bounds.width - 16, height: searchBarHeight))
			}
			rootNavigationHeaderBackground.frame = .init(x: 0.01, y: safeAreaInsets.top + 0.01, width: bounds.width, height: getHeaderAdditionalNavigationMargin())
			rootNavigationHeaderMask.frame = .init(x: 0.01, y: 0.01, width: bounds.width, height: bounds.height)
			rootNavigationHeaderBackground.mask = rootNavigationHeaderMask
		}
	}
	
	func updateFooterFrame() {
		let backgroundHeight = footerHeight + safeAreaInsets.bottom
		UIView.performWithoutAnimation {
			rootFooterBackground.frame.size.width = bounds.width
			footer.frame.size.width = bounds.width
		}
		delay {[weak self] in
			guard let self = self else { return }
			rootFooterBackground.frame = .init(x: 0, y: bounds.height - backgroundHeight, width: bounds.width, height: backgroundHeight)
			rootFooterBackground.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
			rootFooterBackground.layer.cornerRadius = footer.formView.layer.cornerRadius
			footer.frame = .init(origin: .zero, size: .init(width: bounds.width, height: footerHeight))
		}
	}
	
	func getHeaderAdditionalNavigationMargin() -> CGFloat {
		guard let navigationConfiguration = navigationConfiguration else { return .zero }
		var largeTitleViewModelHeight: CGFloat = 0
		var searchBarHeight: CGFloat = 0
		if let largeTitleViewModel = navigationConfiguration.largeTitleViewModel {
			largeTitleViewModelHeight = headerSizeSource.size(
				at: 0, 
				data: largeTitleViewModel,
				collectionSize: bounds.size, 
				dummyView: headerViewSource.getDummyView(data: largeTitleViewModel) as! ViewModelConfigurable,
				direction: .vertical).height
			searchBarHeight = 12
		}
		if navigationConfiguration.searchContext != nil {
			searchBarHeight = self.searchBarHeight
		}
		return largeTitleViewModelHeight + searchBarHeight
	}
	
	func getNavigationHeaderScrollShift() -> CGFloat {
		guard let navigationConfiguration = navigationConfiguration else { return .zero }
		if isSearching {
			return 0
		}
		let scrollViewShift = -(largeViewRef?.frame.origin.y ?? 0)
		var minShift: CGFloat = 0
		if navigationConfiguration.searchContext?.hideWhenScrolling == false {
			minShift = self.searchBarHeight
		}
		let result = max(getHeaderAdditionalNavigationMargin() - scrollViewShift, minShift)
		return result
	}
	
	internal func calculateHeaderFrame() {
		headerTopMargin = topInsetStrategy.getTopInset(for: self) + getNavigationHeaderScrollShift()
	}
	
	internal func updateHeaderFrame() {
		UIView.performWithoutAnimation {
			rootHeaderBackground.frame = .init(x: 0,
											   y: 0,
											   width: bounds.width,
											   height: headerTopMargin + headerHeight)
			_rootHeaderBackgroundViewRef?.frame = rootHeaderBackground.bounds
			header?.frame = .init(x: 0,
								  y: headerTopMargin,
								  width: bounds.width,
								  height: headerHeight)
		}
	}
	
	private var needsConfigureFooter: Bool = false
	private var needsConfigureHeader: Bool = false
	
	func configureBackgroundView() {
		if let customBackgroundView = backgroundView?() {
			if _backgroundViewRef !== customBackgroundView {
				_backgroundViewRef?.removeFromSuperview()
				_backgroundViewRef = nil
			}
			if customBackgroundView.superview !== self {
				addSubview(customBackgroundView)
			}
			_backgroundViewRef = customBackgroundView
			sendSubviewToBack(customBackgroundView)
			customBackgroundView.frame = bounds.inset(by: backgroundViewInsets)
			applyAppearance()
		} else {
			_backgroundViewRef?.removeFromSuperview()
			_backgroundViewRef = nil
		}
	}
	
	func configureHeaderEffectsBackgroundView() {
		if let customBackgroundView = headerBackgroundEffectView?() {
			if _rootHeaderBackgroundViewRef !== customBackgroundView {
				_rootHeaderBackgroundViewRef?.removeFromSuperview()
				_rootHeaderBackgroundViewRef = nil
			}
			if customBackgroundView.superview !== self.rootHeaderBackground {
				rootHeaderBackground.addSubview(customBackgroundView)
			}
			
			_rootHeaderBackgroundViewRef = customBackgroundView
			rootHeaderBackground.sendSubviewToBack(customBackgroundView)
			customBackgroundView.frame = rootHeaderBackground.bounds
			applyAppearance()
		} else {
			_rootHeaderBackgroundViewRef?.removeFromSuperview()
			_rootHeaderBackgroundViewRef = nil
		}
	}
	
	override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		applyAppearance()
	}
	
	public func applyAppearance() {
		backgroundColor = viewBackgroundColor
		rootFormView.backgroundColor = .clear
		shutterView.backgroundColor = getShutterColor()
		rootFooterBackground.backgroundColor = footer.formView.backgroundColor
		scrollViewDidScroll(rootFormView)
		rootHeaderBackground.backgroundColor = headerBackgroundViewColor
	}
	
	var presentingInFormSheet: Bool {
		let viewY = self.superview?.convert(self.frame, to: nil).origin.y
		return viewY == 0
		&& (controller?.presentingViewController != nil)
		&& (controller?.modalPresentationStyle != .fullScreen
			&& controller?.modalPresentationStyle != .custom
			&& controller?.navigationController?.modalPresentationStyle != .fullScreen
			&& controller?.navigationController?.modalPresentationStyle != .custom
			&& controller?.navigationController?.modalPresentationStyle != .overFullScreen)
	}
	
	func configureFooter() {
		addSubview(rootFooterBackground)
		rootFooterBackground.clipsToBounds = false
		rootFooterBackground.layer.masksToBounds = false
		rootFooterBackground.addSubview(footer)
		footer.alpha = 1
		footer.needRound = false
	}
	
	// MARK: Controller's output
	func display(_ headerViewModel: FibViewHeaderViewModel?,
				 dummyHeaderClass: FibViewHeader.Type?,
				 animated: Bool) {
		bringSubviewToFront(rootHeaderBackground)
		if headerViewModel == nil && dummyHeaderClass == nil {
			deleteHeader(animated: animated)
			return
		}
		let viewClass = headerViewModel?.viewClass() ?? dummyHeaderClass
		let selfHeaderClassName = self.header?.className ?? "selfHeader"
		let viewModelHeaderClassName = headerViewModel?.viewClass().className ?? dummyHeaderClass?.className ?? "viewModelHeader"
		let headersHasEqualClasses = (selfHeaderClassName == viewModelHeaderClassName)
		let needConfigureExistedHeader =
		(_headerViewModel != nil && type(of: headerViewModel) == type(of: _headerViewModel!))
		|| headersHasEqualClasses
		if !needConfigureExistedHeader && header != nil {
			deleteHeader(animated: false)
			display(headerViewModel, dummyHeaderClass: dummyHeaderClass, animated: true)
			return
		}
		if !needConfigureExistedHeader {
			addHeaderToView(viewClass: viewClass)
		}
		configureExistedHeader(headerViewModel: headerViewModel, animated: animated)
	}
	
	var headerHeightSource: [String: CGFloat] = [:]
	
	// swiftlint:disable function_body_length
	func configureExistedHeader(headerViewModel: FibViewHeaderViewModel?, animated: Bool) {
		guard let header = self.header else { return }
		guard (headerViewModel?.preventFromReload ?? false) == false else { return }
		if headerViewModel?.atTop == true {
			bringSubviewToFront(rootHeaderBackground)
		} else {
			sendSubviewToBack(rootHeaderBackground)
		}
		let targetSize = bounds.size.insets(by: safeAreaInsets)
		let headerHeight = headerSizeSource.size(
			at: 0,
			data: headerViewModel,
			collectionSize: targetSize,
			dummyView: headerViewSource.getDummyView(data: headerViewModel) as! ViewModelConfigurable,
			direction: .vertical
		).height
		needsConfigureHeader = true
		var isChangedHeaderHeight = false
		isChangedHeaderHeight = self._headerInitialHeight != headerHeight
		self.headerHeight = headerHeight
		_headerInitialHeight = headerHeight
		let isChangedViewModel = _headerViewModel?.viewClass().className ?? "-1"
		!= headerViewModel?.viewClass().className ?? "-2"
		_headerViewModel = headerViewModel
		updateFormViewInsets(animated: headerViewModel != nil && frame.height != 0,
							 isChangedHeaderHeight: isChangedHeaderHeight,
							 isChangedHeaderViewModel: isChangedViewModel)
	}
	
	func addHeaderToView(viewClass: ViewModelConfigurable.Type?) {
		guard let viewClass = viewClass,
			  let header = (viewClass.fromDequeuer() as? FibViewHeader)
				?? viewClass.init() as? FibViewHeader else { return }
		header.alpha = 1
		self.header = header
		rootHeaderBackground.addSubview(header)
		rootHeaderBackground.bringSubviewToFront(header)
	}
	
	func updateFormViewInsets(animated: Bool,
							  isChangedHeaderHeight: Bool = false,
							  isChangedHeaderViewModel: Bool = false) {
		if animated && isChangedHeaderHeight {
			withFibSpringAnimation(options: [.allowUserInteraction, .beginFromCurrentState, .allowAnimatedContent, .layoutSubviews]) {[weak self] in
				guard let self = self else { return }
				self._updateFormViewInsets(isChangedHeaderHeight: isChangedHeaderHeight)
			}
		} else {
			_updateFormViewInsets(isChangedHeaderHeight: isChangedHeaderHeight)
		}
	}
	
	private func _updateFormViewInsets(isChangedHeaderHeight: Bool = false,
									   isChangedHeaderViewModel: Bool = false) {
		let absoluteContentOffset = self.rootFormView.contentOffset.y + self.rootFormView.contentInset.top
		var contentInsetTop = self.headerHeight
		if !isSearching {
			contentInsetTop += getHeaderAdditionalNavigationMargin()
		} else {
			contentInsetTop += getNavigationHeaderScrollShift()
		}
		switch topInsetStrategy {
		case .custom(let margin):
			contentInsetTop -= (safeAreaInsets.top - margin())
		case .safeArea: break
		case .statusBar:
			contentInsetTop -= (safeAreaInsets.top - (statusBarFrame?.height ?? 0))
		case .top:
			contentInsetTop -= safeAreaInsets.top
		}
		self.layoutIfNeeded()
		let needAdjustContentOffset = absoluteContentOffset.isBeetween(-10, 10)
		self.rootFormView.contentInset.top = contentInsetTop
		self.rootFormView.verticalScrollIndicatorInsets.top = contentInsetTop
		if needAdjustContentOffset || (isChangedHeaderHeight && isChangedHeaderViewModel) {
			self.rootFormView.contentOffset.y = -self.rootFormView.contentInset.top
		}
		scrollViewDidScroll(rootFormView)
	}
	
	func deleteHeader(animated: Bool) {
		guard _headerViewModel != nil else { return }
		self.headerHeight = 0.01
		_headerInitialHeight = 0
		header?.removeFromSuperview()
		header = nil
		_headerViewModel = nil
		if animated {
			UIView.animate(withDuration: 0.3) {[weak self] in
				guard let self = self else { return }
				self.rootFormView.contentInset.top = self.headerHeight
				setNeedsLayout()
				self.layoutIfNeeded()
			}
		} else {
			rootFormView.contentInset.top = self.headerHeight
			setNeedsLayout()
			layoutIfNeeded()
		}
	}
	
	func display(_ provider: Provider?, animated: Bool = true) {
		var provider = provider
		if animated == false {
			provider?.animator = nil
		}
		if let emptySection = provider as? EmptySection {
			emptySection.height = footerHeight
			refreshControl.endRefreshing()
			displayEmptyView(emptySection.viewModel, animated: animated)
			return
		}
		assignRefreshControlIfNeeded()
		rootFormView.animated = animated
		rootFormView.provider = provider
		layoutFibGrid(animated: animated)
	}
	
	func display(_ footerViewModel: FibCell.ViewModel?, animated: Bool, secondary: Bool = false) {
		footerViewModel?.storedId = "footer"
		self._footerViewModel = footerViewModel
		let footerHeight = footerViewModel == nil
		? 0
		: self._sizeWithFooter.sizeWith(self.bounds.size, data: footerViewModel)?.height ?? 0
		let footerHeightChanged = footerHeight != self.footerHeight
		self.footerHeight = footerHeight
		if footerHeight == 0 {
			rootFooterBackground.alpha = 0
			rootFooterBackground.isUserInteractionEnabled = false
		} else {
			rootFooterBackground.alpha = 1
			rootFooterBackground.isUserInteractionEnabled = true
		}
		if footerViewModel != nil {
			needsConfigureFooter = true
			self.setNeedsLayout()
		}
		if animated && footerHeightChanged {
			delay {
				withFibSpringAnimation {[weak self] in
					guard let self = self else { return }
					self.layoutIfNeeded()
				}
			}
		}
		if !secondary {
			DispatchQueue.main.async {
				self.display(footerViewModel, animated: animated, secondary: true)
			}
		}
	}
	
	func fullContentHeight() -> CGFloat {
		let height = ((controller?.navigationController?.navigationBar.isHidden ?? true)
					  ? 0
					  : controller?.navigationController?.navigationBar.frame.height ?? 0)
		+ rootFormView.contentSize.height.clamp(0, UIScreen.main.bounds.height)
		+ footerHeight
		+ headerHeight
		return min(height, fullEdgesHeight)
	}
	
	func displayEmptyView(_ viewModel: ViewModelWithViewClass, animated: Bool) {
		let height = footerHeight
		rootFormView.refreshControl = nil
		rootFormView.displayEmptyView(model: viewModel, height: height, animated: animated)
		self.controller?.viewDidReloadCollection(with: self.fullEdgesHeight)
	}
	
	open func shouldDismiss() -> Bool {
		true
	}
	
	@objc func refreshAction() {
		controller?.refreshAction?()
	}
	
	public func beginSearch() {
		if let leftBarButtonItems = controller?.navigationItem.leftBarButtonItems {
			navItemLeftItemsRef = leftBarButtonItems
		} else if let single = controller?.navigationItem.leftBarButtonItem {
			navItemLeftItemsRef = [single]
		}
		controller?.navigationItem.leftBarButtonItems = []
		if let rightBarButtonItems = controller?.navigationItem.rightBarButtonItems {
			navItemRightItemsRef = rightBarButtonItems
		} else if let single = controller?.navigationItem.rightBarButtonItem {
			navItemRightItemsRef = [single]
		}
		controller?.navigationItem.rightBarButtonItems = []
		navItemTitleView = controller?.navigationItem.titleView
		searchBar.removeFromSuperview()
		controller?.navigationItem.titleView = searchBar
		searchBar.becomeFirstResponder()
		searchBar.setShowsCancelButton(true, animated: true)
		controller?.reload()
		setNeedsLayout()
		DispatchQueue.main.async {
			self.setNeedsLayout()
			self.searchBar.backgroundColor = .clear
			self.searchBar.backgroundImage = UIImage()
			self.updateFormViewInsets(animated: false)
		}
	}
	
	public func endSearch() {
		if let navItemLeftItemsRef {
			controller?.navigationItem.leftBarButtonItems = navItemLeftItemsRef
		}
		if let navItemRightItemsRef {
			controller?.navigationItem.rightBarButtonItems = navItemRightItemsRef
		}
		controller?.navigationItem.titleView = navItemTitleView
		navItemLeftItemsRef = nil
		navItemRightItemsRef = nil
		navItemTitleView = nil
		searchBar.resignFirstResponder()
		searchBar.removeFromSuperview()
		searchBar.constraints.forEach({ $0.isActive = false })
		searchBar.translatesAutoresizingMaskIntoConstraints = true
		searchBar.setShowsCancelButton(false, animated: false)
		searchBar.text = nil
		controller?.reload()
		setNeedsLayout()
		DispatchQueue.main.async {
			self.setNeedsLayout()
		}
		guard let searchContext = navigationConfiguration?.searchContext, let onSearchResult = searchContext.onSearchResults else { return }
		onSearchResult(nil)
		searchBar.placeholder = searchContext.placeholder
		searchBar.backgroundColor = .clear
		searchBar.backgroundImage = UIImage()
	}
}

extension FibControllerRootView: UISearchBarDelegate {
	
	public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		guard let searchContext = navigationConfiguration?.searchContext, let onSearchResult = searchContext.onSearchResults else { return }
		onSearchResult(searchBar.text)
	}
	
	public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		isSearching = false
		if let searchEndClosure = navigationConfiguration?.searchContext?.onSearchEnd {
			searchEndClosure(searchBar)
			return
		} else {
			endSearch()
		}
	}
	
	public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		isSearching = true
		if let searchBeginClosure = navigationConfiguration?.searchContext?.onSearchBegin {
			searchBeginClosure(searchBar)
			return
		} else {
			beginSearch()
		}
	}
}
