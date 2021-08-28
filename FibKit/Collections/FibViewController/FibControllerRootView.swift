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
        public static var roundedShutterBackground: UIColor = .secondarySystemBackground
        public static var nonRoundedShutterBackground: UIColor = .systemBackground
        public static var backgroundColor: UIColor = .systemBackground
        public static var gradientFirstColor: UIColor = .blue
        public static var gradientSecondColor: UIColor = .systemBackground
    }

    // MARK: Dependencies
    weak open var controller: FibViewController?

    // MARK: Properties

    public let rootFormView = FibGrid()
    private var _rootFormViewTop: NSLayoutConstraint?
    var needTransparentHeader: Bool = false

    public let footer = FibCell()
    private var _footerBottom: NSLayoutConstraint?
    public var _footerHeight: NSLayoutConstraint?
    private var _footerViewModel: ViewModelWithViewClass?
    public weak var proxyDelegate: UIScrollViewDelegate?

    var footerHeight: CGFloat {
        _footerHeight?.constant ?? 0
    }

    var header: FibViewHeader?
    public let shutterView = ShutterView()
    public var shutterBackground: UIColor?
    public var additionalBackground: UIColor?

    var headerHeight: CGFloat {
        _headerHeight?.constant ?? 0
    }

    var needBackgroundGradient: Bool = false
    var customBackgroundView: UIView?
    var roundedShutter: Bool = false
    var transparentNavbar: Bool = false
    var initialNavbarColor: UIColor = .clear

    public let backgroundGradientView = GradientView()

    private var _headerHeight: NSLayoutConstraint?
    private var _headerInitialHeight: CGFloat?
    private var _headerViewModel: FibViewHeaderViewModel?
    lazy var refreshControl: UIRefreshControl = {
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
        observeKeyboard()
        configureFormView()
        configureFooter()
        rootFormView.containedRootView = self
        traitCollectionDidChange(traitCollection)
    }

    func configureFormView() {
        addSubview(rootFormView)
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

    fileprivate func configureShutterViewFrame() {
        let topInset = needFullAnchors ? 0 : safeAreaInsets.top
        let topEdge = topInset - shutterView.layer.cornerRadius
        let height = UIScreen.main.bounds.height
        let shutterViewY = (rootFormView.frame.origin.y - rootFormView.contentOffset.y).clamp(topEdge, .greatestFiniteMagnitude)
        shutterView.frame = CGRect(x: rootFormView.frame.origin.x,
                                   y: shutterViewY,
                                   width: rootFormView.frame.width,
                                   height: height)
        shutterView.backgroundColor = shutterBackground ?? (roundedShutter
                                                                ? Appearance.roundedShutterBackground
                                                                : Appearance.nonRoundedShutterBackground)
        if roundedShutter {
            shutterView.layer.cornerRadius = 16
            shutterView.layer.masksToBounds = false
            shutterView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            shutterView.layer.applySketchShadow()
        } else {
            shutterView.layer.cornerRadius = 0
            shutterView.layer.clearShadow()
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
        if needBackgroundGradient {
            configureBackgroundGradient()
        } else {
            backgroundGradientView.removeFromSuperview()
        }
        if needsConfigureFooter {
            needsConfigureFooter = false
            footer.configure(with: _footerViewModel)
        }
        if needsConfigureHeader {
            needsConfigureHeader = false
            header?.configure(with: _headerViewModel)
        }
    }
    
    private var needsConfigureFooter: Bool = false
    private var needsConfigureHeader: Bool = false

    func configureBackgroundGradient() {
        if let customBackgroundView = customBackgroundView {
            if customBackgroundView.superview == nil {
                addSubview(customBackgroundView)
            }
            sendSubviewToBack(customBackgroundView)
            customBackgroundView.frame = bounds
        } else {
            if backgroundGradientView.superview == nil {
                addSubview(backgroundGradientView)
            }
            sendSubviewToBack(backgroundGradientView)
            backgroundGradientView.frame = bounds
            backgroundGradientView.gradientLocations = [0, 1]
            backgroundGradientView.startPoint = CGPoint(x: 0, y: 1)
            backgroundGradientView.endPoint = CGPoint(x: 0, y: 0.1)
            backgroundGradientView.oneColor = nil
            backgroundGradientView.twoColor = nil
        }
        traitCollectionDidChange(traitCollection)
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        backgroundColor = additionalBackground ?? Appearance.backgroundColor
        rootFormView.backgroundColor = .clear
        shutterView.backgroundColor = shutterBackground ?? (roundedShutter
                                                                ? Appearance.roundedShutterBackground
                                                                : Appearance.nonRoundedShutterBackground)
        if needBackgroundGradient {
            backgroundGradientView.startColor = Appearance.gradientFirstColor
            backgroundGradientView.endColor = Appearance.gradientSecondColor
        }
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
            topConstant = UIApplication.shared.delegate?.window??
                .windowScene?
                .statusBarManager?
                .statusBarFrame.height ?? 0
        }
        _rootFormViewTop = rootFormView.anchorWithReturnAnchors(headerTopAnchor, topConstant: topConstant).first
    }

    var presentingInFormSheet: Bool {
        let viewY = self.superview?.convert(self.frame, to: nil).origin.y
        return viewY == 0 && (controller?.presentingViewController != nil) &&
            (controller?.modalPresentationStyle != .fullScreen
                && controller?.modalPresentationStyle != .custom && controller?.navigationController?.modalPresentationStyle != .fullScreen && controller?.navigationController?.modalPresentationStyle != .custom)
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
        let viewModelHeaderClassName = headerViewModel?.viewClass().className ?? "viewModelHeader"
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
        _headerHeight?.isActive = false
        var headerTopAnchor: NSLayoutYAxisAnchor = safeAreaLayoutGuide.topAnchor
        var headerTopConstant: CGFloat = 0
        if presentingInFormSheet {
            headerTopConstant = UIApplication.shared.delegate?.window??
                .windowScene?
                .statusBarManager?
                .statusBarFrame.height ?? 0
        }
        if needFullAnchors {
            headerTopAnchor = topAnchor
        }
        header.anchor(top: headerTopAnchor,
                      left: leftAnchor,
                      right: rightAnchor,
                      insets: .init(top: headerTopConstant, left: 0, bottom: 0, right: 0))
        let targetSize = bounds.size.insets(by: safeAreaInsets)
        let existedHeight = headerHeightSource[headerViewModel?.sizeHash ?? UUID().uuidString]
        var headerHeight: CGFloat
        if let existedHeight = existedHeight {
            headerHeight = existedHeight
            needsConfigureHeader = true
            setNeedsLayout()
        } else {
            header.configure(with: headerViewModel)
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
            headerHeightSource[headerViewModel?.sizeHash ?? UUID().uuidString] = headerHeight
        }
        var isChangedHeaderHeight = false
        if let oldHeaderHeight = _headerHeight?.constant {
            isChangedHeaderHeight = oldHeaderHeight != headerHeight
        }
        _headerHeight = header.anchorWithReturnAnchors(heightConstant: headerHeight).first
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
            UIView.animate(withDuration: 0.3) {[weak self] in
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
        let headerHeight = self._headerHeight?.constant ?? 0
        let needAdjustContentOffset = absoluteContentOffset.isBeetween(-10, 10)
        self.rootFormView.contentInset.top = headerHeight
        self.rootFormView.verticalScrollIndicatorInsets.top = headerHeight
        if needAdjustContentOffset || (isChangedHeaderHeight && isChangedHeaderViewModel) {
            self.rootFormView.contentOffset.y = -self.rootFormView.contentInset.top
        }
        self.layoutIfNeeded()
    }

    func deleteHeader(animated: Bool) {
        guard _headerViewModel != nil else { return }
        _headerHeight?.constant = 0.5
        _headerInitialHeight = 0
        header?.removeFromSuperview()
        header = nil
        _headerViewModel = nil
        if animated {
            UIView.animate(withDuration: 0.3) {[weak self] in
                guard let self = self else { return }
                self.rootFormView.contentInset.top = self._headerHeight?.constant ?? 0
                self.layoutIfNeeded()
            }
        } else {
            rootFormView.contentInset.top = _headerHeight?.constant ?? 0
            layoutIfNeeded()
        }
    }

    func display(_ sections: [GridSection], animated: Bool = true) {
        if animated == false {
            sections.forEach { $0.animator = nil }
        }
//        if let emptySection = sections.first(where: { $0 is EmptySection }) as? EmptySection {
//            emptySection.height = footerHeight
//            refreshControl.endRefreshing()
//            displayEmptyView(emptySection.viewModel, animated: animated)
//            return
//        }
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
            UIView.animate(withDuration: 0.3) {[weak self] in
                guard let self = self else { return }
                self.layoutIfNeeded()
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
            + rootFormView.contentInset.bottom
            + footerHeight
            + headerHeight
        return min(height, fullEdgesHeight)
    }

//    func displayEmptyView(_ viewModel: InfoMessageView.ViewModel, animated: Bool) {
//        var height = footerHeight
//        if IQKeyboardManager.shared.keyboardShowing {
//            height = lastKeyboardHeight == 0 ? footerHeight : (lastKeyboardHeight - safeAreaInsets.bottom)
//        }
//        rootFormView.refreshControl = nil
//        rootFormView.displayEmptyView(model: viewModel, height: height, animated: animated)
//        self.controller?.viewDidReloadCollection(with: self.fullEdgesHeight)
//    }

    open func shouldDismiss() -> Bool {
        true
    }

    @objc func refreshAction() {
        controller?.refreshAction?()
    }

    public var lastKeyboardHeight: CGFloat = 0

    func observeKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillDisplay(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(kayboardWillChangeWrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    public var keyboardChangeFrameCallback: ((CGFloat) -> Void)?
    
    @objc func kayboardWillChangeWrame(_ notification: Notification) {
        let haveInChildren =
            (UIApplication.topViewController()?.children
                                .contains(self.controller ?? UIViewController()) ?? false) ||
            (UIApplication.topViewController()?.children
                .contains(where: { contr in
                (contr as? UINavigationController)?.viewControllers.last === self.controller
            }) ?? false)
        || (UIApplication.topViewController()?.children
                .contains(where: { contr in
                (contr as? UINavigationController)?.viewControllers.last === self.controller
            }) ?? false)
        guard UIApplication.topViewController() === self.controller || haveInChildren else { return }
        if let info = notification.userInfo,
            let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardChangeFrameCallback?(value.height)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let haveInChildren =
            (UIApplication.topViewController()?.children
                                .contains(self.controller ?? UIViewController()) ?? false) ||
            (UIApplication.topViewController()?.children
                .contains(where: { contr in
                (contr as? UINavigationController)?.viewControllers.last === self.controller
            }) ?? false)
        guard UIApplication.topViewController() === self.controller || haveInChildren else { return }
        controller?.reload()
    }

    @objc func keyboardWillDisplay(_ notification: Notification) {
        let haveInChildren =
            (UIApplication.topViewController()?.children
                                .contains(self.controller ?? UIViewController()) ?? false) ||
            (UIApplication.topViewController()?.children
                .contains(where: { contr in
                (contr as? UINavigationController)?.viewControllers.last === self.controller
            }) ?? false)
        guard UIApplication.topViewController() === self.controller || haveInChildren else { return }
        if let info = notification.userInfo,
            let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            lastKeyboardHeight = value.height
        }
        controller?.reload()
    }
    
}

// MARK: ScrollViewDelegate

extension FibControllerRootView: UIScrollViewDelegate {

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        proxyDelegate?.scrollViewDidScroll?(scrollView)
        
        if controller?.navigationController?.navigationBar.prefersLargeTitles == true {
            rootFormView.loadCellsInBounds = false
        }
        configureShutterViewFrame()
        guard let headerInitialHeight = _headerInitialHeight else { return }
        let offsetY = (scrollView.contentOffset.y + headerInitialHeight)
        let size = headerInitialHeight - offsetY
        if transparentNavbar {
            let sizePercentage = ((headerInitialHeight - size) / headerInitialHeight).clamp(0, 1)
            let shutterBackground = shutterView.backgroundColor ?? Appearance.roundedShutterBackground
            let fadeColor = shutterBackground
                .withAlphaComponent(0)
                .fade(toColor: shutterBackground, withPercentage: sizePercentage)
            controller?.navigationController?.navigationBar.backgroundColor = fadeColor
        }
        guard let headerViewModel = _headerViewModel else { return }
        var minHeight: CGFloat = headerInitialHeight
        var maxHeight: CGFloat = headerInitialHeight
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
        _headerHeight?.constant = size.clamp(minHeight, maxHeight)
        header?.layoutIfNeeded()
        headerObserver.size = CGSize(width: header?.frame.width ?? 0,
                                     height: size.clamp(minHeight, maxHeight))
        headerObserver.initialHeight = headerInitialHeight
        headerObserver.maxHeight = maxHeight
        headerObserver.minHeight = minHeight
        header?.sizeChanged(size: CGSize(width: header?.frame.width ?? 0,
                                         height: size.clamp(minHeight, maxHeight)),
                            initialHeight: headerInitialHeight,
                            maxHeight: maxHeight,
                            minHeight: minHeight)
        self.rootFormView.additionalHeaderInset = size.clamp(minHeight, maxHeight)
        self.rootFormView.verticalScrollIndicatorInsets.top = size.clamp(minHeight, maxHeight)
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

public class GradientView: UIView {

    @IBInspectable public var startColor: UIColor = UIColor.white {
        didSet {
            self.updateView()
        }
    }

    @IBInspectable public var oneColor: UIColor? = UIColor.white.withAlphaComponent(0.9) {
        didSet {
            self.updateView()
        }
    }
    @IBInspectable public var twoColor: UIColor? = UIColor.white.withAlphaComponent(0.7) {
        didSet {
            self.updateView()
        }
    }

    @IBInspectable public var endColor: UIColor = UIColor.clear {
        didSet {
            self.updateView()
        }
    }

    public var startPoint: CGPoint = CGPoint(x: 0, y: 0) {
        didSet {
            self.updateView()
        }
    }

    public var endPoint: CGPoint = CGPoint(x: 0.5, y: 0) {
        didSet {
            self.updateView()
        }
    }

    public var gradientLocations: [NSNumber] = [0.0, 0.23, 0.49, 1.0]

    override public class var layerClass: AnyClass {
        { CAGradientLayer.self }()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateView()
    }

    public func updateView() {
        let layer = self.layer as! CAGradientLayer
        layer.colors = [startColor,
                        oneColor,
                        twoColor,
                        endColor].compactMap { $0 }.map { $0.cgColor }
        layer.startPoint = startPoint
        layer.endPoint = endPoint
        layer.locations = gradientLocations
    }
}
