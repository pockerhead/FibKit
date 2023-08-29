//
//  FormVCRootView.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit
import VisualEffectView

private class RootGridViewBackground: UIView {
	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard FibGridPassthroughHelper.nestedInteractiveViews(in: self, contain: point, convertView: self) else {
			return false
		}
		return super.point(inside: point, with: event)
	}
}

open class FibControllerRootView: UIView {
	
	public enum Shutter {
		case rounded
		case `default`
	}
	
	public enum TopInsetStrategy {
		case safeArea
		case statusBar
		case top
		case custom(@autoclosure (() -> CGFloat))
		
		func getTopInset(for view: UIView) -> CGFloat {
			switch self {
			case .safeArea:
				return view.safeAreaInsets.top
			case .statusBar:
				return view.statusBarFrame?.height ?? 0
			case .top:
				return 0
			case .custom(let margin):
				return margin()
			}
		}
	}
	
	public class Configuration {
		public init(
			roundedShutterBackground: UIColor? = nil,
			shutterBackground: UIColor? = nil,
			viewBackgroundColor: UIColor? = nil,
			shutterType: FibControllerRootView.Shutter? = nil,
			backgroundView: (() -> UIView?)? = nil,
			shutterShadowClosure: ((ShutterView) -> Void)? = nil,
			topInsetStrategy: TopInsetStrategy? = nil,
			headerBackgroundViewColor: UIColor? = nil,
			headerBackgroundEffectView: (() -> UIView?)? = nil
		) {
			self.roundedShutterBackground = roundedShutterBackground
			self.shutterBackground = shutterBackground
			self.viewBackgroundColor = viewBackgroundColor
			self.shutterType = shutterType
			self.backgroundView = backgroundView
			self.shutterShadowClosure = shutterShadowClosure
			self.topInsetStrategy = topInsetStrategy
			self.headerBackgroundViewColor = headerBackgroundViewColor
			self.headerBackgroundEffectView = headerBackgroundEffectView
		}
		
		public var roundedShutterBackground: UIColor?
		public var shutterBackground: UIColor?
		public var viewBackgroundColor: UIColor?
		public var headerBackgroundViewColor: UIColor?
		public var headerBackgroundEffectView: (() -> UIView?)?
		public var shutterShadowClosure: ((ShutterView) -> Void)?
		public var shutterType: Shutter?
		public var backgroundView: (() -> UIView?)?
		public var topInsetStrategy: TopInsetStrategy?
	}
		
	private var defaultConfiguration: Configuration { FibViewController.defaultConfiguration.viewConfiguration
	}
	// MARK: - APPEARANCE
	
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
	private var _footerViewModel: ViewModelWithViewClass?
	private let rootFooterBackground = RootGridViewBackground()

	public weak var proxyDelegate: UIScrollViewDelegate?
	
	public private(set) var footerHeight: CGFloat = 0
	
	public var header: FibViewHeader?
	private let rootHeaderBackground = RootGridViewBackground()
	private var rootHeaderBackgroundEffectView: UIView?
	private var _rootHeaderBackgroundViewRef: UIView?

	public let shutterView = ShutterView()
	
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
	
	fileprivate func configureShutterViewFrame() {
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
	
	func layoutFibGrid() {
		rootFormView.frame = bounds
		rootFormView.contentInset.bottom = footerHeight
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		rootGridViewBackground.frame = bounds
		UIView.performWithoutAnimation {
			configureShutterViewFrame()
		}
		configureBackgroundView()
		configureHeaderEffectsBackgroundView()
		calculateHeaderFrame()
		updateHeaderFrame()
		updateFooterFrame()
		if needsConfigureFooter {
			needsConfigureFooter = false
			if let footer = footer as? ViewModelConfigururableFromSizeWith {
				footer.configure(with: _footerViewModel, isFromSizeWith: false)
			} else {
				footer.configure(with: _footerViewModel)
			}
			applyAppearance()
		}
		if needsConfigureHeader {
			needsConfigureHeader = false
			if let header = header as? ViewModelConfigururableFromSizeWith {
				header.configure(with: _headerViewModel, isFromSizeWith: false)
			} else {
				header?.configure(with: _headerViewModel)
			}
		}
		layoutFibGrid()
		let gridMaskTop = shutterType == .default ? 0 : topInsetStrategy.getTopInset(for: self)
		gridMaskView.frame = .init(origin: .init(x: 0, y: gridMaskTop),
								   size: .init(width: bounds.width, height: bounds.height))
	}
	
	func updateFooterFrame() {
		let backgroundHeight = footerHeight + safeAreaInsets.bottom
		rootFooterBackground.frame = .init(x: 0, y: bounds.height - backgroundHeight, width: bounds.width, height: backgroundHeight)
		rootFooterBackground.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
		rootFooterBackground.layer.cornerRadius = footer.formView.layer.cornerRadius
		footer.frame = .init(origin: .zero, size: .init(width: bounds.width, height: footerHeight))
	}
	
	fileprivate func calculateHeaderFrame() {
		headerTopMargin = topInsetStrategy.getTopInset(for: self)
	}
	
	fileprivate func updateHeaderFrame() {
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
			customBackgroundView.frame = bounds
			applyAppearance()
		} else {
			_backgroundViewRef?.removeFromSuperview()
			_backgroundViewRef = nil
		}
	}
	
	func configureHeaderEffectsBackgroundView() {
		if let customBackgroundView = headerBackgroundEffectView?() {
			if rootHeaderBackgroundEffectView !== customBackgroundView {
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
		let existedHeight = headerHeightSource[headerViewModel?.sizeHash ?? UUID().uuidString]
		var headerHeight: CGFloat
		if let existedHeight = existedHeight {
			headerHeight = existedHeight
			needsConfigureHeader = true
			setNeedsLayout()
		} else {
			if let header = header as? ViewModelConfigururableFromSizeWith {
				header.configure(with: headerViewModel, isFromSizeWith: true)
			} else {
				header.configure(with: headerViewModel)
			}
			headerHeight = headerViewModel?.initialHeight
			?? header.sizeWith(targetSize, data: headerViewModel, horizontal: .required, vertical: .fittingSizeLevel)?.height
			?? header
				.sizeWith(targetSize, data: headerViewModel)?
				.height
			?? header
				.systemLayoutSizeFitting(targetSize,
										 withHorizontalFittingPriority: .required,
										 verticalFittingPriority: .fittingSizeLevel)
				.height
				.rounded(.up)
			headerHeightSource[headerViewModel?.sizeHash ?? UUID().uuidString] = headerHeight
		}
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
		self.headerHeight = 0.5
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
		layoutFibGrid()
	}
	
	func display(_ footerViewModel: FibCell.ViewModel?, animated: Bool, secondary: Bool = false) {
		footerViewModel?.storedId = "footer"
		self._footerViewModel = footerViewModel
		let footerHeight = footerViewModel == nil
		? 0
		: self.footer.sizeWith(self.bounds.size, data: footerViewModel)?.height ?? 0
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
	
}

// MARK: ScrollViewDelegate

extension FibControllerRootView: UIScrollViewDelegate {
	
	open func scrollViewDidScroll(_ scrollView: UIScrollView) {
		proxyDelegate?.scrollViewDidScroll?(scrollView)
		configureShutterViewFrame()
		if rootFormView.scrollDirection == .vertical {
			scrollView.contentOffset.x = 0
		} else if rootFormView.scrollDirection == .horizontal {
			scrollView.contentOffset.y = 0
		}
		if controller?.navigationController?.navigationBar.prefersLargeTitles == true {
			calculateHeaderFrame()
			header?.frame.origin.y = headerTopMargin
		}
		guard let headerInitialHeight = _headerInitialHeight else { return }
		let offsetY = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
		let size = headerInitialHeight - offsetY
		var minHeight: CGFloat = headerInitialHeight
		var maxHeight: CGFloat = headerInitialHeight
		defer {
			self.rootFormView.additionalHeaderInset = size.clamp(minHeight, maxHeight)
			self.rootFormView.verticalScrollIndicatorInsets.top = size.clamp(minHeight, maxHeight)
		}
//		if transparentNavbar {
//			let sizePercentage = ((headerInitialHeight - size) / headerInitialHeight).clamp(0, 1)
//			let shutterBackground = getShutterColor() ?? .clear
//			let fadeColor = shutterBackground
//				.withAlphaComponent(0)
//				.fade(toColor: shutterBackground, withPercentage: sizePercentage)
//			controller?.navigationController?.navigationBar.backgroundColor = fadeColor
//		}
		guard let headerViewModel = _headerViewModel else { return }
		if headerViewModel.atTop == false {
			minHeight = 0
		}
		guard headerViewModel.allowedStretchDirections.isEmpty == false else {
			return
		}
		if headerViewModel.allowedStretchDirections.contains(.down) {
			maxHeight = headerViewModel.maxHeight ?? .greatestFiniteMagnitude
		}
		if headerViewModel.allowedStretchDirections.contains(.up) {
			minHeight = headerViewModel.minHeight ?? 0
		}
		guard headerHeight >= minHeight && headerHeight <= maxHeight else {
			return
		}
		self.headerHeight = size.clamp(minHeight, maxHeight)
		header?.layoutIfNeeded()
		updateHeaderFrame()
		header?.sizeChanged(size: CGSize(width: header?.frame.width ?? 0,
										 height: size.clamp(minHeight, maxHeight)),
							initialHeight: headerInitialHeight,
							maxHeight: maxHeight,
							minHeight: minHeight)
	}
	
	public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
										  withVelocity velocity: CGPoint,
										  targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		proxyDelegate?.scrollViewWillEndDragging?(scrollView,
												  withVelocity: velocity,
												  targetContentOffset: targetContentOffset)
	}
	
	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		proxyDelegate?.scrollViewWillBeginDragging?(scrollView)
	}
}

public class HeaderObserver: ObservableObject {
	@Published public var size: CGSize
	@Published public var initialHeight: CGFloat
	@Published public var maxHeight: CGFloat?
	@Published public var minHeight: CGFloat?
	
	public init(size: CGSize = .init(width: 1, height: 1), initialHeight: CGFloat = 1) {
		self.size = size
		self.initialHeight = initialHeight
	}
}

public class ShutterView: UIView {}

extension UIView {
	
	func applyIdentityRecursive() {
		transform = .identity
		subviews.forEach { $0.applyIdentityRecursive() }
	}
}

internal extension UIView {
	
	var fullEdgesHeight: CGFloat {
		let safeArea = ((statusBarFrame?.height ?? 0) + self.safeAreaInsets.bottom)
		return UIScreen.main.bounds.height - safeArea
	}
}
