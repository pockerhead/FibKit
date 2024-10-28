//
//  FormVCRootView.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit
import VisualEffectView
import Combine

open class FibControllerRootView: UIView {
		
	private var defaultConfiguration: Configuration { FibViewController.defaultConfiguration.viewConfiguration
	}
	// MARK: - APPEARANCE
	
	var navigationConfiguration: FibControllerRootView.NavigationConfiguration?
	
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
	
	var footerBackgroundViewColor: UIColor? {
		controller?.configuration?.viewConfiguration.footerBackgroundViewColor ?? defaultConfiguration.footerBackgroundViewColor
	}
	
	var needFooterKeyboardSticks: Bool {
		controller?.configuration?.viewConfiguration.needFooterKeyboardSticks ?? defaultConfiguration.needFooterKeyboardSticks
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
	
	public let footerView = FibCell()
	private let _sizeWithFooter = FibCell()
	private var _footerViewModel: ViewModelWithViewClass?
	private let rootFooterBackground = RootGridViewBackground()

	public weak var proxyDelegate: UIScrollViewDelegate?
	
	public private(set) var footerHeight: CGFloat = 0
	
	public var headerView: FibViewHeader?
	private let rootNavigationHeaderBackground = RootGridViewBackground()
	private let rootNavigationHeaderMask = UIView().backgroundColor(.black)
	private weak var largeViewRef: ViewModelConfigurable?
	private let rootHeaderBackground = RootGridViewBackground()
	private var rootHeaderBackgroundEffectView: UIView?
	private var isKeyboardAppeared: Bool = false
	private var keyboardHeight: CGFloat = 0
	private var _rootHeaderBackgroundViewRef: UIView?
	private let headerViewSource = FibGridViewSource()
	private let headerSizeSource = FibGridSizeSource()
	public let shutterView = ShutterView()
	private let gridMaskLayer = CALayer()
	public private(set) var isSearching = false
	private lazy var activeSearchBar: UISearchBar = {
		let s = UISearchBar()
		s.returnKeyType = .done
		return s
	}()
	private lazy var inactiveSearchBar = UISearchBar()
	private var navItemLeftItemsRef: [UIBarButtonItem]? = []
	private var navItemRightItemsRef: [UIBarButtonItem]? = []
	private var navItemTitleView: UIView?
	var headerHeight: CGFloat = 0
	var headerTopMargin: CGFloat = 0
			
	internal var _headerInitialHeight: CGFloat?
	var _headerViewModel: FibViewHeaderViewModel?
	public lazy var refreshControl: UIRefreshControl = {
		let control = UIRefreshControl()
		control.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
		return control
	}()
	
	var cancellables: Set<AnyCancellable> = []
	
	public let headerObserver = HeaderObserver()
	
	var scrollView: UIScrollView? {
		rootFormView
	}
	
	// MARK: - BODY HEADER FOOTER
	
	open var body: SectionProtocol? { nil }
	open var header: FibViewHeaderViewModel? { nil }
	open var footer: FibCell.ViewModel? { nil }
	
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
		NotificationCenter.default.publisher(for: UIApplication.keyboardWillChangeFrameNotification)
			.sink {[weak self] notification in
				self?.keyboardChangeFrame(notification)
			}
			.store(in: &cancellables)
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
		gridMaskLayer.backgroundColor = UIColor.black.cgColor
		rootGridViewBackground.layer.mask = gridMaskLayer
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
	
	private func keyboardChangeFrame(_ notification: Notification) {
		guard let userInfo: NSDictionary = notification.userInfo as NSDictionary?,
			  let keyboardAnimationCurve = (userInfo.object(forKey: UIResponder.keyboardAnimationCurveUserInfoKey) as? NSValue) as? Int,
			  let keyboardAnimationDuration = (userInfo.object(forKey: UIResponder.keyboardAnimationDurationUserInfoKey) as? NSValue) as? Double,
			  let keyboardIsLocal = (userInfo.object(forKey: UIResponder.keyboardIsLocalUserInfoKey) as? NSValue) as? Bool,
			  let keyboardFrameBegin = (userInfo.object(forKey: UIResponder.keyboardFrameBeginUserInfoKey) as? NSValue)?.cgRectValue,
			  let keyboardFrameEnd = (userInfo.object(forKey: UIResponder.keyboardFrameEndUserInfoKey) as? NSValue)?.cgRectValue,
			  let keyboardFrame = window?.convert(keyboardFrameEnd, to: self)
		else {
			return
		}
		let isHiding = !(convert(bounds, to: window).maxY.rounded() > keyboardFrameEnd.minY)
		isKeyboardAppeared = !isHiding
		keyboardHeight = isKeyboardAppeared ? keyboardFrame.height : 0
		if needFooterKeyboardSticks {
			UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: [.allowUserInteraction]) {
				self.updateFooterFrame(sync: true)
			} completion: { _ in }
		}
	}
	
	internal func configureShutterViewFrame() {
		let topInset = topInsetStrategy.getTopInset(for: self)
		let topEdge = topInset - shutterView.layer.cornerRadius
		let height = UIScreen.main.bounds.height * 2
		let shutterViewY = (rootFormView.frame.origin.y - rootFormView.contentOffset.y).clamp(0, .greatestFiniteMagnitude)
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
				guard !isKeyboardAppeared else {
					rootFormView.contentInset.bottom = keyboardHeight + footerHeight
					return
				}
				rootFormView.contentInset.bottom = footerHeight
			}
		}
	}
	
	private let layoutDebouncer = TaskDebouncer(delayType: .cyclesCount(6))
	
	func _layoutSubviews(){
		configureHeaderEffectsBackgroundView()
		if needsConfigureFooter {
			needsConfigureFooter = false
			DispatchQueue.main.async {[weak self] in
				guard let self = self else { return }
				if let footer = footerView as? ViewModelConfigururableFromSizeWith {
					footer.configure(with: _footerViewModel, isFromSizeWith: false)
				} else {
					footerView.configure(with: _footerViewModel)
				}
				applyAppearance()
			}
		}
		if needsConfigureHeader {
			needsConfigureHeader = false
			DispatchQueue.main.async {[weak self] in
				guard let self = self else { return }
				if let header = headerView as? ViewModelConfigururableFromSizeWith {
					header.configure(with: _headerViewModel, isFromSizeWith: false)
				} else {
					headerView?.configure(with: _headerViewModel)
				}
			}
		}
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		UIView.performWithoutAnimation {
			rootGridViewBackground.frame = bounds
			configureShutterViewFrame()
		}
		layoutFibGrid(animated: false)
		let gridMaskTop = shutterType == .default ? 0 : topInsetStrategy.getTopInset(for: self)
		// #crutch need maskTop + 0.01, because full view mask and blur
		// background is not friends at all
		gridMaskLayer.frame = .init(origin: .init(x: 0, y: gridMaskTop + 0.01),
									size: .init(width: bounds.width, height: bounds.height))
		reloadNavigation()
		configureBackgroundView()
		calculateHeaderFrame()
		updateHeaderFrame()
		updateFooterFrame()
		layoutDebouncer.runDebouncedTask {[weak self] in
			self?._layoutSubviews()
		}
	}
	
	private func createNavItemViewIfNeeded(titleViewModel: ViewModelWithViewClass?,forceSet: Bool = false) {
		guard let titleViewModel = titleViewModel else {
			navItemTitleView = nil
			return
		}
		if let existed = navItemTitleView as? ViewModelConfigurable,
		   type(of: existed) == titleViewModel.viewClass() {
			existed.configure(with: titleViewModel)
			controller?.calculateTitleViewSize(titleView: existed,
											   vm: titleViewModel)
		} else {
			navItemTitleView = titleViewModel.getView()
			if forceSet {
				controller?.setNavbarTitleView(navItemTitleView, vm: navigationConfiguration?.titleViewModel)
			}
		}
	}
	
	public func reloadNavigation() {
		navigationConfiguration = controller?.configuration?.navigationConfiguration ?? FibViewController.defaultConfiguration.navigationConfiguration
		var needUpdateContentInsets = false
		var isChangedHeaderHeight = false
		var isChangedHeaderModel = false
		rootHeaderBackground.addSubview(rootNavigationHeaderBackground)
		if let header = headerView {
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
					needUpdateContentInsets = true
				}
			} else if let newLargeView = largeTitleViewModel.getView() {
				self.largeViewRef = newLargeView
				rootNavigationHeaderBackground.addSubview(newLargeView)
				needUpdateContentInsets = true
			}
			createNavItemViewIfNeeded(titleViewModel: navigationConfiguration?.titleViewModel)
		} else if let titleViewModel = navigationConfiguration?.titleViewModel {
			if largeViewRef?.superview != nil {
				largeViewRef?.removeFromSuperview()
				needUpdateContentInsets = true
			}
			createNavItemViewIfNeeded(titleViewModel: titleViewModel, forceSet: true)
		} else {
			if largeViewRef?.superview != nil {
				largeViewRef?.removeFromSuperview()
				needUpdateContentInsets = true
				isChangedHeaderModel = true
				isChangedHeaderHeight = true
				setNeedsLayout()

			}
			controller?.setNavbarTitleView(nil, vm: navigationConfiguration?.titleViewModel, animated: false)
			navItemTitleView = nil
		}
		if let context = navigationConfiguration?.searchContext {
			[activeSearchBar, inactiveSearchBar].forEach({ searchBar in
				searchBar.delegate = self
				searchBar.placeholder = context.placeholder
				searchBar.backgroundColor = .clear
				searchBar.backgroundImage = UIImage()
			})
			if let force = context.isForceActive {
				if force && !activeSearchBar.isFirstResponder && !isSearching {
					isSearching = true
					activeSearchBar.becomeFirstResponder()
					searchBarTextDidBeginEditing(inactiveSearchBar)
				} else if !force && activeSearchBar.isFirstResponder {
					isSearching = false
					activeSearchBar.resignFirstResponder()
					searchBarCancelButtonClicked(activeSearchBar)
				}
			} else if !isSearching {
				if inactiveSearchBar.superview == nil {
					rootNavigationHeaderBackground.addSubview(inactiveSearchBar)
					needUpdateContentInsets = true
				}
				if inactiveSearchBar.isHidden == true {
					inactiveSearchBar.isHidden = false
					needUpdateContentInsets = true
				}
			} else if isSearching {
				inactiveSearchBar.isHidden = true
			}
		} else if inactiveSearchBar.superview != nil {
			inactiveSearchBar.removeFromSuperview()
			needUpdateContentInsets = true
		}
		assignNavigationFramesIfNeeded()
		if needUpdateContentInsets {
			updateFormViewInsets(animated: false,
								 isChangedHeaderHeight: isChangedHeaderHeight,
								 isChangedHeaderViewModel: isChangedHeaderModel)
		}
	}
	
	var searchBarHeight: CGFloat {
		isSearching ? 0 : 66
	}
	
	func assignNavigationFramesIfNeeded() {
		UIView.performWithoutAnimation {
			largeViewRef?.isHidden = isSearching
			var scrollViewShift = rootFormView.contentOffset.y + rootFormView.adjustedContentInset.top
			if rootFormView.refreshControl != nil {
				scrollViewShift = max(0.01, scrollViewShift)
			}
			if let largeTitleViewModel = navigationConfiguration?.largeTitleViewModel {
				let height = headerSizeSource.size(
					at: 0,
					data: largeTitleViewModel,
					collectionSize: bounds.size,
					dummyView: headerViewSource.getDummyView(data: largeTitleViewModel) as! ViewModelConfigurable,
					direction: .vertical).height
				self.largeViewRef?.frame = .init(origin: .init(x: 0.01, y: 0.01 - scrollViewShift), size: .init(width: bounds.width, height: height))
				if !isSearching, (largeViewRef?.superview?.convert(largeViewRef?.frame ?? .zero, to: self).maxY ?? 0) < safeAreaInsets.top {
					controller?.setNavbarTitleView(navItemTitleView, vm: navigationConfiguration?.titleViewModel)
				} else if !isSearching {
					controller?.setNavbarTitleView(nil, vm: nil)
				}
			}
			if let searchContext = navigationConfiguration?.searchContext, (searchContext.isForceActive ?? false) == false {
				let largeViewShift = largeViewRef?.frame.maxY
				var searchBarPositionY: CGFloat = largeViewShift ?? (0.01 - scrollViewShift)
				if !searchContext.hideWhenScrolling {
					searchBarPositionY = max(searchBarPositionY, 0.01)
				}
				self.inactiveSearchBar.frame = .init(
					origin: .init(x: 8, y: searchBarPositionY),
					size: .init(width: self.bounds.width - 16, height: searchBarHeight)
				)
			}
			rootNavigationHeaderBackground.frame = .init(x: 0.01, y: safeAreaInsets.top + 0.01, width: bounds.width, height: getHeaderAdditionalNavigationMargin())
			rootNavigationHeaderMask.frame = .init(x: 0.01, y: 0.01, width: bounds.width, height: bounds.height)
			rootNavigationHeaderBackground.mask = rootNavigationHeaderMask
		}
	}
	
	func updateFooterFrame(sync: Bool = false) {
		UIView.performWithoutAnimation {
			rootFooterBackground.frame.size.width = bounds.width
			footerView.frame.size.width = bounds.width
		}
		if sync {
			_updateFooterFrame()
		} else {
			delay {[weak self] in
				guard let self = self else { return }
				_updateFooterFrame()
			}
		}
		
	}
	
	func _updateFooterFrame() {
		var backgroundHeight = footerHeight + safeAreaInsets.bottom
		if needFooterKeyboardSticks && isKeyboardAppeared {
			backgroundHeight = footerHeight + keyboardHeight
		}
		rootFooterBackground.frame.origin = .init(x: 0, y: bounds.height - backgroundHeight)
		rootFooterBackground.frame.size.height = backgroundHeight
		rootFooterBackground.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
		rootFooterBackground.layer.cornerRadius = footerView.formView.layer.cornerRadius
		footerView.frame.origin = .zero
		footerView.frame.size.height = footerHeight
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
		if let context = navigationConfiguration.searchContext {
			if let force = context.isForceActive, force {
				searchBarHeight = 0
			} else {
				searchBarHeight = self.searchBarHeight
			}
		}
		return largeTitleViewModelHeight + searchBarHeight
	}
	
	func getNavigationHeaderScrollShift() -> CGFloat {
		guard let navigationConfiguration = navigationConfiguration else { return .zero }
		if isSearching {
			return 0
		}
		var scrollViewShift = (rootFormView.contentOffset.y + rootFormView.adjustedContentInset.top)
		if controller?.refreshAction != nil {
			scrollViewShift = max(0.01, scrollViewShift)
		}
		var minShift: CGFloat = 0
		if navigationConfiguration.searchContext?.hideWhenScrolling == false {
			if
				let force = navigationConfiguration.searchContext?.isForceActive,
				force {
				minShift = 0
			} else {
				minShift = self.searchBarHeight
			}
		}
		if navigationConfiguration.largeTitleViewModel == nil && navigationConfiguration.searchContext == nil {
			return max(getHeaderAdditionalNavigationMargin(), minShift)
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
			headerView?.frame = .init(x: 0,
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
		rootFooterBackground.backgroundColor = footerBackgroundViewColor ?? footerView.formView.backgroundColor
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
		rootFooterBackground.addSubview(footerView)
		footerView.alpha = 1
		footerView.needRound = false
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
		let selfHeaderClassName = self.headerView?.className ?? "selfHeader"
		let viewModelHeaderClassName = headerViewModel?.viewClass().className ?? dummyHeaderClass?.className ?? "viewModelHeader"
		let headersHasEqualClasses = (selfHeaderClassName == viewModelHeaderClassName)
		let needConfigureExistedHeader =
		(_headerViewModel != nil && type(of: headerViewModel) == type(of: _headerViewModel!))
		|| headersHasEqualClasses
		if !needConfigureExistedHeader && headerView != nil {
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
		guard let header = self.headerView else { return }
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
		self.headerView = header
		rootHeaderBackground.addSubview(header)
		rootHeaderBackground.bringSubviewToFront(header)
	}
	
	func updateFormViewInsets(animated: Bool,
							  isChangedHeaderHeight: Bool = false,
							  isChangedHeaderViewModel: Bool = false) {
		if animated && isChangedHeaderHeight {
			withFibSpringAnimation(options: [.allowUserInteraction, .beginFromCurrentState, .allowAnimatedContent, .layoutSubviews]) {[weak self] in
				guard let self = self else { return }
				self._updateFormViewInsets(isChangedHeaderHeight: isChangedHeaderHeight, isChangedHeaderViewModel: isChangedHeaderViewModel)
			}
		} else {
			_updateFormViewInsets(isChangedHeaderHeight: isChangedHeaderHeight,
								  isChangedHeaderViewModel: isChangedHeaderViewModel)
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
		let needAdjustContentOffset = absoluteContentOffset.isBeetween(-10, 10)
		self.rootFormView.contentInset.top = contentInsetTop
		self.rootFormView.verticalScrollIndicatorInsets.top = contentInsetTop
		if needAdjustContentOffset || (isChangedHeaderHeight && isChangedHeaderViewModel) {
			self.rootFormView.contentOffset.y = -self.rootFormView.contentInset.top
		}
		self.layoutIfNeeded()
		scrollViewDidScroll(rootFormView)
	}
	
	func deleteHeader(animated: Bool) {
		guard _headerViewModel != nil else { return }
		self.headerHeight = 0.01
		_headerInitialHeight = 0
		headerView?.removeFromSuperview()
		headerView = nil
		_headerViewModel = nil
		if animated {
			UIView.animate(withDuration: 0.3) {[weak self] in
				guard let self = self else { return }
				updateFormViewInsets(animated: true, isChangedHeaderHeight: true)
			}
		} else {
			updateFormViewInsets(animated: false)
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
		inactiveSearchBar.resignFirstResponder()
		controller?.navigationItem.rightBarButtonItems = []
		navItemTitleView = controller?.navigationItem.titleView
		controller?.navigationItem.titleView = activeSearchBar
		activeSearchBar.setShowsCancelButton(true, animated: true)
		let fadeTextAnimation = CATransition()
		fadeTextAnimation.duration = 0.1
		fadeTextAnimation.type = .fade
		controller?.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
		controller?.reload()
		setNeedsLayout()
		DispatchQueue.main.async {
			self.setNeedsLayout()
			self.controller?.navigationController?.navigationBar.setNeedsLayout()
			self.activeSearchBar.backgroundColor = .clear
			self.activeSearchBar.backgroundImage = UIImage()
			self.updateFormViewInsets(animated: false)
			delay(cyclesCount: 4) {[weak self] in
				guard let self = self else { return }
				activeSearchBar.becomeFirstResponder()
			}
		}
	}
	
	public func endSearch() {
		if let navItemLeftItemsRef {
			controller?.navigationItem.leftBarButtonItems = navItemLeftItemsRef
		}
		if let navItemRightItemsRef {
			controller?.navigationItem.rightBarButtonItems = navItemRightItemsRef
		}
		controller?.navigationItem.titleView = nil
		navItemLeftItemsRef = nil
		navItemRightItemsRef = nil
		navItemTitleView = nil
		activeSearchBar.setShowsCancelButton(false, animated: false)
		activeSearchBar.resignFirstResponder()
		activeSearchBar.text = nil
		let fadeTextAnimation = CATransition()
		fadeTextAnimation.duration = 0.1
		fadeTextAnimation.type = .fade
		controller?.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
		controller?.reload()
		setNeedsLayout()
		DispatchQueue.main.async {
			self.controller?.navigationItem.titleView = self.navItemTitleView
			self.setNeedsLayout()
			self.updateFormViewInsets(animated: true)
		}
		guard let searchContext = navigationConfiguration?.searchContext, let onSearchResult = searchContext.onSearchResults else { return }
		onSearchResult(nil)
		inactiveSearchBar.placeholder = searchContext.placeholder
		inactiveSearchBar.backgroundColor = .clear
		inactiveSearchBar.backgroundImage = UIImage()
	}
}

extension FibControllerRootView: UISearchBarDelegate {
	
	public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		guard let searchContext = navigationConfiguration?.searchContext, let onSearchResult = searchContext.onSearchResults else { return }
		onSearchResult(searchBar.text)
	}
	
	public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let searchContext = navigationConfiguration?.searchContext, let closure = searchContext.onSearchButtonClicked else {
			searchBar.endEditing(true)
			return
		}
		closure(searchBar)
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
		guard searchBar === inactiveSearchBar else { return }
		isSearching = true
		if let searchBeginClosure = navigationConfiguration?.searchContext?.onSearchBegin {
			searchBeginClosure(searchBar)
			return
		} else {
			beginSearch()
		}
	}
}
