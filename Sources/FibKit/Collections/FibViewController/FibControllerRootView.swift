//
//  FormVCRootView.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import IQKeyboardManagerSwift
import UIKit
import VisualEffectView

open class FibControllerRootView: UIView {
	
	public struct Appearance {
		var roundedShutterBackground: UIColor = .secondarySystemBackground
		var shutterBackground: UIColor = .systemBackground
		var backgroundColor: UIColor = .systemBackground
	}
	
	public enum Shutter {
		case rounded
		case `default`
	}
	
	public struct Configuration {
		var appearance = Appearance()
		var shutter: Shutter = .default
		var backgroundView: UIView?
	}
	
	public static var defaultConfiguration = Configuration()
	
	public var configuration = FibControllerRootView.defaultConfiguration
	
	// MARK: Dependencies
	weak open var controller: FibViewController?
	
	// MARK: Properties
	
	public let rootFormView = FibGrid()
	private var _rootFormViewTop: NSLayoutConstraint?
	var needTransparentHeader: Bool = false
	private var _backgroundViewRef: UIView?
	
	public let footer = FibCell()
	private var _footerBottom: NSLayoutConstraint?
	public var _footerHeight: NSLayoutConstraint?
	private var _footerViewModel: ViewModelWithViewClass?
	public weak var proxyDelegate: UIScrollViewDelegate?
	
	var footerHeight: CGFloat {
		_footerHeight?.constant ?? 0
	}
	
	public var header: FibViewHeader?
	public let shutterView = ShutterView()
	
	var headerHeight: CGFloat = 0
	var headerTopMargin: CGFloat = 0
	
	var needBackgroundGradient: Bool = false
	var customBackgroundView: UIView?
	var transparentNavbar: Bool = false
	var initialNavbarColor: UIColor = .clear
		
	private var _headerInitialHeight: CGFloat?
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
		rootFormView.containedRootView = self
	}
	
	func configureFormView() {
		addSubview(rootFormView)
		rootFormView.clipsToBounds = true
		rootFormView.layer.masksToBounds = true
		insertSubview(shutterView, belowSubview: rootFormView)
		assignRootFormViewTop()
		rootFormView.anchor(left: safeAreaLayoutGuide.leftAnchor,
							right: safeAreaLayoutGuide.rightAnchor)
		rootFormView.delegate = self
		assignRefreshControlIfNeeded()
		rootFormView.didReload {[weak self] in
			guard let self = self else { return }
			self.controller?.viewDidReloadCollection(with: self.fullContentHeight())
		}
	}
	
	func assignRefreshControlIfNeeded() {
		if controller?.refreshAction != nil {
			rootFormView.refreshControl = refreshControl
		} else {
			rootFormView.refreshControl = nil
		}
	}
	
	fileprivate func getShutterColor() -> UIColor {
		switch configuration.shutter {
		case .default:
			return configuration.appearance.shutterBackground
			case .rounded:
			return configuration.appearance.roundedShutterBackground
		}
	}
	
	fileprivate func configureShutterViewFrame() {
		let topInset = needFullAnchors ? 0 : safeAreaInsets.top
		let topEdge = topInset - shutterView.layer.cornerRadius
		let height = UIScreen.main.bounds.height
		let shutterViewY = (rootFormView.frame.origin.y - rootFormView.contentOffset.y).clamp(topEdge, .greatestFiniteMagnitude)
		shutterView.frame = CGRect(x: rootFormView.frame.origin.x,
								   y: shutterViewY,
								   width: rootFormView.frame.width,
								   height: height)
		shutterView.backgroundColor = getShutterColor()
		switch configuration.shutter {
		case .default:
			shutterView.layer.cornerRadius = 0
//			shutterView.layer.clearShadow()
		case .rounded:
			shutterView.layer.cornerRadius = 16
			shutterView.layer.masksToBounds = false
			shutterView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//			shutterView.layer.applySketchShadow()
		}
		let mask = CAShapeLayer()
		let maskOriginY = min(rootFormView.frame.origin.y - shutterViewY, shutterView.layer.cornerRadius)
		mask.path = UIBezierPath(
			rect: CGRect(x: 0,
						 y: maskOriginY,
						 width: UIScreen.main.bounds.width,
						 height: UIScreen.main.bounds.height)
		).cgPath
		shutterView.layer.mask = mask
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		UIView.performWithoutAnimation {
			configureShutterViewFrame()
		}
		if configuration.backgroundView != nil {
			configureBackgroundView()
		} else {
			_backgroundViewRef?.removeFromSuperview()
			_backgroundViewRef = nil
		}
		calculateHeaderFrame()
		updateHeaderFrame()
		if needsConfigureFooter {
			needsConfigureFooter = false
			if let footer = footer as? ViewModelConfigururableFromSizeWith {
				footer.configure(with: _footerViewModel, isFromSizeWith: false)
			} else {
				footer.configure(with: _footerViewModel)
			}
		}
		if needsConfigureHeader {
			needsConfigureHeader = false
			if let header = header as? ViewModelConfigururableFromSizeWith {
				header.configure(with: _headerViewModel, isFromSizeWith: false)
			} else {
				header?.configure(with: _headerViewModel)
			}
		}
	}
	
	fileprivate func calculateHeaderFrame() {
		self.headerTopMargin = safeAreaInsets.top
		if needFullAnchors {
			self.headerTopMargin = 0
			if controller?.navigationController?.navigationBar.prefersLargeTitles == true {
				let offsetY = abs(
					rootFormView.contentOffset.y
						.clamp(
							-.greatestFiniteMagnitude, -rootFormView.adjustedContentInset.top
						)
					+ rootFormView.adjustedContentInset.top
				)
				headerTopMargin = safeAreaInsets.top + offsetY.clamp(0, .greatestFiniteMagnitude)
				self.rootFormView.additionalHeaderInset = headerTopMargin + headerHeight
			}
		} else {
			self.headerTopMargin = safeAreaInsets.top
		}
		if presentingInFormSheet {
			self.headerTopMargin += statusBarFrame?.height ?? 0
		}
	}
	
	fileprivate func updateHeaderFrame() {
		header?.frame = .init(x: 0,
							  y: headerTopMargin,
							  width: bounds.width,
							  height: headerHeight)
	}
	
	private var needsConfigureFooter: Bool = false
	private var needsConfigureHeader: Bool = false
	
	func configureBackgroundView() {
		if let customBackgroundView = configuration.backgroundView {
			if customBackgroundView.superview == nil {
				addSubview(customBackgroundView)
			}
			_backgroundViewRef = customBackgroundView
			sendSubviewToBack(customBackgroundView)
			customBackgroundView.frame = bounds
			applyAppearance()
		}
	}
	
	override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		applyAppearance()
	}
	
	func applyAppearance() {
		backgroundColor = configuration.appearance.backgroundColor
		rootFormView.backgroundColor = .clear
		shutterView.backgroundColor = getShutterColor()
		scrollViewDidScroll(rootFormView)
	}
	
	func assignRootFormViewTop() {
		_rootFormViewTop?.isActive = false
		var headerTopAnchor: NSLayoutYAxisAnchor
		if needFullAnchors {
			headerTopAnchor = topAnchor
			if rootFormView.contentInsetAdjustmentBehavior != .always {
				rootFormView.contentInsetAdjustmentBehavior = .never
			}
			//выставляем contentInset по safeArea только снизу
			delay(0.032) {[weak self] in //два кадра
				guard let self = self else { return }
				if self.rootFormView.contentInset.bottom == 0 {
					self.rootFormView.contentInset.bottom = self.safeAreaInsets.bottom
				}
			}
		} else {
			headerTopAnchor = safeAreaLayoutGuide.topAnchor
			rootFormView.contentInsetAdjustmentBehavior = .automatic
		}
		var topConstant: CGFloat = 0
		if presentingInFormSheet {
			topConstant = statusBarFrame?.height ?? 0
		}
		_rootFormViewTop = rootFormView.anchorWithReturnAnchors(headerTopAnchor, topConstant: topConstant).first
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
		addSubview(footer)
		footer._needUserInteraction = false
		footer.alpha = 1
		footer.needRound = false
		footer.anchor(top: rootFormView.bottomAnchor,
					  left: safeAreaLayoutGuide.leftAnchor,
					  bottom: safeAreaLayoutGuide.bottomAnchor,
					  right: safeAreaLayoutGuide.rightAnchor)
		_footerBottom = footer.anchorWithReturnAnchors(bottom: safeAreaLayoutGuide.bottomAnchor).first
		_footerHeight = footer.anchorWithReturnAnchors(heightConstant: 44).first
	}
	
	// MARK: Controller's output
	func display(_ headerViewModel: FibViewHeaderViewModel?,
				 dummyHeaderClass: FibViewHeader.Type?,
				 animated: Bool) {
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
	
	var needFullAnchors: Bool {
		((controller?.navigationController?.navigationBar as? PassThroughNavigationBar) != nil) ||
		needTransparentHeader == true
	}
	
	var headerHeightSource: [String: CGFloat] = [:]
	
	// swiftlint:disable function_body_length
	func configureExistedHeader(headerViewModel: FibViewHeaderViewModel?, animated: Bool) {
		guard let header = self.header else { return }
		guard (headerViewModel?.preventFromReload ?? false) == false else { return }
		if headerViewModel?.atTop == true {
			bringSubviewToFront(header)
		} else {
			sendSubviewToBack(header)
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
		if self._headerInitialHeight ?? 0 > 0 {
			isChangedHeaderHeight = self._headerInitialHeight != headerHeight
		}
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
		addSubview(header)
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
		let headerHeight = self.headerHeight
		self.layoutIfNeeded()
		let needAdjustContentOffset = absoluteContentOffset.isBeetween(-10, 10)
		self.rootFormView.contentInset.top = headerHeight
		self.rootFormView.verticalScrollIndicatorInsets.top = headerHeight
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
				self.layoutIfNeeded()
			}
		} else {
			rootFormView.contentInset.top = self.headerHeight
			layoutIfNeeded()
		}
	}
	
	func display(_ sections: [GridSection], animated: Bool = true) {
		if animated == false {
			sections.forEach { $0.animator = nil }
		}
//		if let emptySection = sections.first(where: { $0 is EmptySection }) as? EmptySection {
//			emptySection.height = footerHeight
//			refreshControl.endRefreshing()
//			displayEmptyView(emptySection.viewModel, animated: animated)
//			return
//		}
		assignRootFormViewTop()
		assignRefreshControlIfNeeded()
		rootFormView.animated = animated
		rootFormView.sections = sections
	}
	
	func display(_ footerViewModel: FibCell.ViewModel?, animated: Bool, secondary: Bool = false) {
		for (index, section) in (footerViewModel?.sections ?? []).enumerated() {
			section.identifier = "FooterSection_at_\(index)"
		}
		footerViewModel?.storedId = "footer"
		footerViewModel?.backgroundColor = .clear
		self._footerViewModel = footerViewModel
		let footerHeight = footerViewModel == nil
		? 0
		: self.footer.sizeWith(self.bounds.size, data: footerViewModel)?.height ?? 0
		let footerHeightChanged = footerHeight != (self._footerHeight?.constant ?? 0)
		self._footerHeight?.constant = footerHeight
		self._footerBottom?.isActive = false
		let footerBottomAnchor: NSLayoutYAxisAnchor
		if footerViewModel == nil {
			footerBottomAnchor = self.bottomAnchor
		} else {
			footerBottomAnchor = self.safeAreaLayoutGuide.bottomAnchor
		}
		self._footerBottom = self.footer.anchorWithReturnAnchors(bottom: footerBottomAnchor).first
		if footerViewModel != nil {
			needsConfigureFooter = true
			self.setNeedsLayout()
		}
		self.footer.isHidden = footerHeight == 0
		if animated && footerHeightChanged {
			delay {
				UIView.animate(withDuration: 0.3) {[weak self] in
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
	
//	func displayEmptyView(_ viewModel: InfoMessageView.ViewModel, animated: Bool) {
//		var height = footerHeight
//		if IQKeyboardManager.shared.keyboardShowing {
//			height = lastKeyboardHeight == 0 ? footerHeight : (lastKeyboardHeight - safeAreaInsets.bottom)
//		}
//		rootFormView.refreshControl = nil
//		rootFormView.displayEmptyView(model: viewModel, height: height, animated: animated)
//		self.controller?.viewDidReloadCollection(with: self.fullEdgesHeight)
//	}
	
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
		} else {
			scrollView.contentOffset.y = 0
		}
		if controller?.navigationController?.navigationBar.prefersLargeTitles == true {
			calculateHeaderFrame()
			header?.frame.origin.y = headerTopMargin
		}
		guard let headerInitialHeight = _headerInitialHeight else { return }
		let offsetY = (scrollView.contentOffset.y + headerInitialHeight)
		let size = headerInitialHeight - offsetY
		var minHeight: CGFloat = headerInitialHeight
		var maxHeight: CGFloat = headerInitialHeight
		defer {
			self.rootFormView.additionalHeaderInset = size.clamp(minHeight, maxHeight)
			self.rootFormView.verticalScrollIndicatorInsets.top = size.clamp(minHeight, maxHeight)
			if needFullAnchors && controller?.navigationController?.navigationBar.prefersLargeTitles == true {
				self.rootFormView.additionalHeaderInset = size.clamp(minHeight, maxHeight) + safeAreaInsets.top
				self.rootFormView.verticalScrollIndicatorInsets.top = size.clamp(minHeight, maxHeight) + safeAreaInsets.top
			}
		}
		if transparentNavbar {
			let sizePercentage = ((headerInitialHeight - size) / headerInitialHeight).clamp(0, 1)
			let shutterBackground = getShutterColor()
			let fadeColor = shutterBackground
				.withAlphaComponent(0)
				.fade(toColor: shutterBackground, withPercentage: sizePercentage)
			controller?.navigationController?.navigationBar.backgroundColor = fadeColor
		}
		guard let headerViewModel = _headerViewModel else { return }
		if headerViewModel.atTop == false {
			minHeight = 0
			rootFormView.loadCellsInBounds = true
		} else {
			rootFormView.loadCellsInBounds = false
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
