//
//  FibCoreView.swift
//  SmartStaff
//
//  Created by Артём Балашов on 05.07.2021.
//  Copyright © 2021 DIT. All rights reserved.
//

import UIKit

open class FibCoreView: UIView,
                        ViewModelConfigururableFromSizeWith,
                        FormViewAppearable,
                        SwipeControlledView,
                        StickyHeaderView,
                        FibViewHeader,
                        CollectionViewReusableView,
                        UIGestureRecognizerDelegate,
                        HighlightableView,
						DragControlledView {
	
	public struct Appearance {
		public init(
			coloredBackgroundDefaultColor: UIColor = .darkText
		) {
			self.coloredBackgroundDefaultColor = coloredBackgroundDefaultColor
		}
		
		public var coloredBackgroundDefaultColor: UIColor
	}
	
	public static let sharedReuseManager: CollectionReuseViewManager = {
		let manager = CollectionReuseViewManager()
		manager.lifeSpan = 30
		manager.removeFromCollectionViewWhenReuse = false
		return manager
	}()

	public static var defaultAppearance = Appearance()
	
	public var appearance: Appearance? {
		nil
	}
	
	private var coloredBackgroundDefaultColor: UIColor {
		appearance?.coloredBackgroundDefaultColor ?? FibCoreView.defaultAppearance.coloredBackgroundDefaultColor
	}
    
    // MARK: - Variables
    
    private lazy var swipeCoordinator = FibCoreSwipeCoordinator(fibCoreView: self)
    private var _needUserInteraction: Bool = false
    open var needUserInteraction: Bool { _needUserInteraction }
    public var haveSwipeAction: Bool { swipeCoordinator.haveSwipeAction }
    public var isSwipeOpen: Bool { swipeCoordinator.isSwipeOpen }
    public var isHighlighted: Bool = false
	public var needAlphaChangeOnDrag: Bool = true
    
    open var tooltipView: UIView {
        contentView
    }
	
	open var canStartDragSession: Bool {
		data?.canStartDragSession ?? true
	}

	public internal(set) var canBeReordered: Bool = true
	private var onAnalyticsTap: ((String) -> Void)?
    private var onAppearClosure: ((UIView) -> Void)?
    private var onTap: ((UIView) -> Void)?
    private var longTapDuration: TimeInterval = 3
    private var longTapStarted: ((UIGestureRecognizer, FibCoreView) -> Void)?
    private var longTapEnded: ((UIGestureRecognizer, FibCoreView) -> Void)?
    private var tapGesture: UITapGestureRecognizer?
    private var longTapGesture: UILongPressGestureRecognizer?
	private let analyticsGesture: UITapGestureRecognizer
    private(set) public var event: UIEvent?
	private(set) public var corneredOnSwipe = true
    private var onDissappearClosure: ((UIView) -> Void)?
    private var highlight: FibCoreViewModel.HighLight = .squeeze
    private var allowSqueeze: Bool = true
    open var getSizeClosure: ((CGSize) -> Void)?
    public weak var data: FibCoreViewModel?
    private lazy var _contentViewBackgroundColor: UIColor? = contentView.backgroundColor
    
    public var contentView = UIView()

	
	public enum Edge {
		case left
		case right
	}
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
		self.analyticsGesture = UITapGestureRecognizer()
        super.init(frame: frame)
		configureAnalyticsGesture()
        configureUI()
    }
    
    public required init?(coder: NSCoder) {
		self.analyticsGesture = UITapGestureRecognizer()
        super.init(coder: coder)
		configureAnalyticsGesture()
        configureUI()
    }
	
	private func configureAnalyticsGesture() {
		self.analyticsGesture
			.addTarget(self,
					   action: #selector(analyticsTap(sender:)))
		self.analyticsGesture.delegate = self
	}
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Configuration
    
    /// Конфигурирует иерархию вью, обязательно вызывать super
    open func configureUI() {
        addSubview(contentView)
        configureAppearance()
        let notification = NSNotification.Name("startSwipeOnSwiftUIWrapper")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveSwipe(_:)),
                                               name: notification,
                                               object: nil)
    }
	
	/// Тап по ячейке для аналитики
	/// пустая реализация, необходимо переопределить в сабклассе
	/// - Parameter sender: экземпляр там жеста
	@objc private func analyticsTap(sender: UITapGestureRecognizer) {
		let name = getAnalyticsMolecule(
			for: sender.location(in: contentView)
		)
		guard let name = name else { return }
		onAnalyticsTap?(name)
	}
	
	/// Вызывается при тапе по ячейке для понимания элемента нажатия,
	/// пустая реализация, необходимо переопределить в сабклассе
	/// - Parameter point: точка касания во внутренней системе координат contentView
	/// - Returns: Название элемента
	open func getAnalyticsMolecule(for point: CGPoint) -> String? { nil }
    
    @objc func receiveSwipe(_ notification: Notification) {
        guard let ref = notification.userInfo?["swipeViewRef"] as? UIView else { return }
        guard ref !== self else { return }
        guard haveSwipeAction, isSwipeOpen else { return }
        swipeCoordinator.animateSwipe(isOpen: false, swipeWidth: nil)
    }
    
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        onTap?(contentView)
    }
	
	open override func removeFromSuperview() {
		if isExperimentalDequeuerEnabled, !isForcedToRemove, superview != nil {
			FibCoreView.sharedReuseManager.queue(view: self)
		}
		super.removeFromSuperview()
	}
	
	var isForcedToRemove = false
	func removeFromSuperviewFinally() {
		isForcedToRemove = true
		removeFromSuperview()
	}
    
    @objc func onLongPress(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            if haveSwipeAction, isSwipeOpen {
                swipeCoordinator.animateSwipe(isOpen: false, swipeWidth: nil) {[weak self] in
                    guard let self = self else { return }
                    self.longTapStarted?(sender, self)
                }
            } else {
                self.longTapStarted?(sender, self)
            }
        case .cancelled, .ended, .failed:
            self.longTapEnded?(sender, self)
        default: break
        }
    }
	
	open func onDragBegin() {}
	
	open func onDragEnd() {}
    
    // MARK: - Public
    
    public func animateSwipe(direction: SwipeType, isOpen: Bool, swipeWidth: CGFloat?, initialVel: CGFloat?, completion: (() -> Void)?) {
        swipeCoordinator.animateSwipe(direction: direction, isOpen: isOpen, swipeWidth: swipeWidth, initialVel: initialVel, completion: completion)
    }
	
	open func backgroundSizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		nil
	}
    
    open func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
        guard let data = data as? FibCoreViewModel else { return nil }
        configure(with: data, isFromSizeWith: true)
        guard let size = data.size else {
            let autoSize = contentView
                .systemLayoutSizeFitting(
                    targetSize,
                    withHorizontalFittingPriority: horizontal,
                    verticalFittingPriority: vertical
                )
			mainOrSync {[weak self] in
				guard let self = self else { return }
				getSizeClosure?(autoSize)
			}
            return autoSize
        }
        var autoSize: CGSize = .zero
        switch size.width {
        case .absolute(let width):
            autoSize.width = width
        case .inherit: autoSize.width = targetSize.width
        case .selfSized:
            autoSize.width = constrainedWidth(targetSize)
        case .greaterThan(let value):
            autoSize.width = constrainedWidth(targetSize)
            if autoSize.width < value {
                autoSize.width = value
            }
        case .lessThan(let value):
            autoSize.width = constrainedWidth(targetSize)
            if autoSize.width > value {
                autoSize.width = value
            }
        }
        switch size.height {
        case .absolute(let height):
            autoSize.height = height
        case .inherit:
            autoSize.height = targetSize.height
        case .selfSized:
            autoSize.height = constrainedHeight(targetSize)
        case .greaterThan(let value):
            autoSize.height = constrainedHeight(targetSize)
            if autoSize.height < value {
                autoSize.height = value
            }
        case .lessThan(let value):
            autoSize.height = constrainedHeight(targetSize)
            if autoSize.height > value {
                autoSize.height = value
            }
        }
		mainOrSync {[weak self] in
			guard let self = self else { return }
			getSizeClosure?(autoSize)
		}
        return autoSize
    }
    
    private func constrainedHeight(_ targetSize: CGSize) -> CGFloat {
        contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
    }
    
    private func constrainedWidth(_ targetSize: CGSize) -> CGFloat {
        contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required).width
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
		maskIfNeeded()
        backgroundColor = .clear
        contentView.frame.origin.y = 0
        contentView.frame.size = bounds.size
        if corneredOnSwipe, !isSwipeOpen {
            contentView.frame.origin.x = self.bounds.origin.x
            contentView.layer.cornerRadius = 0
        }
        if isSwipeOpen, !isAnimating {
            swipeCoordinator.animateSwipe(isOpen: false, swipeWidth: nil)
        }
    }
	
	weak var fb_maskView: FibSectionBackgroundView?
	
	func setMaskView(_ view: FibSectionBackgroundView?) {
		fb_maskView = view
	}
	
	func maskIfNeeded() {
		guard let relativeMaskFrame = fb_maskView?.maskBackgroundView.superview?.convert(fb_maskView?.maskBackgroundView.frame ?? .zero, to: self),
			  relativeMaskFrame != .zero,
			  relativeMaskFrame.size != .zero else {
			return
		}
		let maskLayer = CALayer()
		maskLayer.frame = relativeMaskFrame
		maskLayer.cornerRadius = fb_maskView?.maskBackgroundView.layer.cornerRadius ?? 0
		maskLayer.backgroundColor = .init(red: 0, green: 1, blue: 0, alpha: 1)
		layer.mask = maskLayer
		layer.masksToBounds = true
	}
    
    open func configureAppearance() {
        // point to override
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureAppearance()
    }
    
    /// Подготавливает вью к реюзу в FibGrid, обязательно вызывать super
    open func prepareForReuse() {
        swipeCoordinator.prepareForReuse()
        setHighlighted(highlighted: false)
        // point to override
    }
    
    /// Вызывается когда FibRootVCView пытается сжать хедер, вызывается много раз при скролле
    /// - Parameters:
    ///   - size: размер, под который подгоняется хедер в данный момент
    ///   - initialHeight: начальная высота хедера
    ///   - maxHeight: максимальная высота хедера, конфигурируется в FibHeaderViewModel
    ///   - minHeight: минимальная высота хедера, конфигурируется в FibHeaderViewModel
    open func sizeChanged(size: CGSize, initialHeight: CGFloat, maxHeight: CGFloat?, minHeight: CGFloat?) {
        // point to override
    }
    
    open func configure(with data: ViewModelWithViewClass?, isFromSizeWith: Bool) {
        configure(with: data)
    }
    
    /// обязательно вызывать super
    /// - Parameter data: viewModel
    open func configure(with data: ViewModelWithViewClass?) {
        guard let data = data as? FibCoreViewModel else { return }
        self.data = data
		self.corneredOnSwipe = data.corneredOnSwipe
		self.onAnalyticsTap = data.onAnalyticsTap
		if data.onAnalyticsTap == nil {
			contentView.removeGestureRecognizer(analyticsGesture)
		} else {
			contentView.addGestureRecognizer(analyticsGesture)
		}
		self.needAlphaChangeOnDrag = data.needAlphaChangeOnDrag
        setHighlighted(highlighted: false)
        if let menu = data.contextMenu {
            contentView.addContextMenu(menu)
        }
        if let tooltip = data.tooltip {
            if tooltip.needShow {
				switch tooltip.tooltipType {
					case .text(text: let text):
					ToolTipService.shared.showToolTip(for: self.tooltipView, text: text, completion: tooltip.completion)
					case .custom(view: let view, marker: let marker):
					ToolTipService.shared.showToolTip(for: self.tooltipView, tooltipViewModel: view, markerView: marker, completion: tooltip.completion)
				}
            } else {
//                ToolTipService.shared.hideTooltip(animated: true)
            }
        } else {
//            ToolTipService.shared.hideTooltip(animated: false)
        }
		if let transform = data.transform {
			self.transform = transform
		}
		canBeReordered = data.canBeReordered
        _needUserInteraction = data.interactive
        getSizeClosure = data.getSizeClosure
        highlight = data.highlight
        swipeCoordinator.configure(with: data)
        if let itemsProvider = data.dragItemsProvider {
            contentView.addDrag(itemsProvider: itemsProvider)
        } else {
            contentView.removeDrag()
        }
        if let dropDelegate = data.dropDelegate {
            contentView.addDrop(delegate: dropDelegate)
        } else {
            contentView.removeDrop()
        }
        if let tap = data.onTap {
            self.onTap = tap
            self.tapGesture = .init(target: self, action: #selector(onTap(_:)))
            contentView.addGestureRecognizer(self.tapGesture!)
        } else {
            if let existedTap = self.tapGesture {
                contentView.removeGestureRecognizer(existedTap)
            }
            self.onTap = nil
            self.tapGesture = nil
        }
        if let longTap = data.longPressContext {
            self.longTapStarted = longTap.longTapStarted
            self.longTapEnded = longTap.longTapEnded
            self.allowSqueeze = longTap.allowSqueeze
            self.longTapGesture = .init(target: self, action: #selector(onLongPress(_:)))
            self.longTapGesture?.minimumPressDuration = longTap.longTapDuration
            self.longTapDuration = longTap.longTapDuration
            self.contentView.addGestureRecognizer(self.longTapGesture!)
        } else {
            if let existed = self.longTapGesture {
                contentView.removeGestureRecognizer(existed)
            }
            self.longTapStarted = nil
            self.longTapEnded = nil
            self.longTapDuration = 0
            self.longTapGesture = nil
        }
        onAppearClosure = data.onAppearClosure
        onDissappearClosure = data.onDissappearClosure
        if data.leftSwipeViews != nil || data.rightSwipeViews != nil {
            contentView.layer.masksToBounds = true
            contentView.clipsToBounds = true
        } else {
            contentView.clipsToBounds = true
            contentView.layer.masksToBounds = false
        }
    }
    
    public func onDissappear(with formView: FibGrid?) {
        onDissappearClosure?(self)
    }
    
    public func onAppear(with formView: FibGrid?) {
        onAppearClosure?(self)
    }

    // MARK: - Touches
    
    private var feedback = UISelectionFeedbackGenerator()
    open var squeezeUpDuration: TimeInterval = 0.1
    open var squeezeDownDuration: TimeInterval = 0.2
    open var squeezeDownScale: CGFloat = 0.95
    private var currentShadowDescriptor: ShadowDescriptor?
    
    private var needAnimateLongTapDimming: Bool = false
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.event = event
        if longTapGesture != nil {
            if contentView.gestureRecognizers?.contains(where: { $0 === longTapGesture }) == false {
                contentView.addGestureRecognizer(longTapGesture!)
            }
            needAnimateLongTapDimming = true
            if allowSqueeze {
                let delayDuration = (longTapDuration / 2)
                let animationDuration = 0.4
                currentShadowDescriptor = layer.getShadowDescriptor()
                delay(delayDuration) { [weak self] in
                    guard let self = self else { return }
                    guard self.needAnimateLongTapDimming else { return }
                    withFibSpringAnimation(duration: animationDuration) {
                        self.transform = .init(scaleX: 0.9, y: 0.9)
                        self.layer.applySketchShadow()
                    } completion: { compl in
                        if compl {
                            self.transform = .identity
                        }
                        self.layer.clearShadow()
                    }
                }
            }
        }
        guard needUserInteraction, isUserInteractionEnabled else { return }
        guard let point = touches.first?.location(in: self), contentView.frame.contains(point) else { return }
        setHighlighted(highlighted: true)
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        needAnimateLongTapDimming = false
        setHighlighted(highlighted: false)
        guard needUserInteraction, isUserInteractionEnabled else { return }
        guard let point = touches.first?.location(in: self), contentView.frame.contains(point) else { return }
        DispatchQueue.main.async {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        needAnimateLongTapDimming = false
        setHighlighted(highlighted: false)
        guard needUserInteraction, isUserInteractionEnabled else { return }
        guard let point = touches.first?.location(in: self), contentView.frame.contains(point) else { return }
    }
}

// MARK: - Highlight

extension FibCoreView {
    
    public func setHighlighted(highlighted: Bool) {
        isHighlighted = highlighted
        switch highlight {
        case .squeeze:
            highlightSqueeze(highlighted: highlighted)
        case .coloredBackground:
            highlightColoredBackground(highlighted: highlighted)
        case .coloredCustomBackground(let color):
            highlightColoredBackground(highlighted: highlighted, color: color)
        case .custom(let closure):
            closure(self, highlighted)
        }
    }

    public func highlightSqueeze(highlighted: Bool) {
        if highlighted {
            UIView.animate(withDuration: squeezeDownDuration) {
                self.transform = CGAffineTransform(scaleX: self.squeezeDownScale, y: self.squeezeDownScale)
            }
        } else {
            UIView.animate(withDuration: squeezeUpDuration) {
                self.transform = .identity
            }
        }
    }


    public func highlightColoredBackground(highlighted: Bool, color: UIColor? = nil) {
        if highlighted {
            _contentViewBackgroundColor = contentView.backgroundColor
            UIView.animate(withDuration: squeezeDownDuration) {
				self.contentView.backgroundColor = color ?? self.contentView.backgroundColor?.fade(toColor: self.coloredBackgroundDefaultColor, withPercentage: 0.05)
            }
        } else {
            UIView.animate(withDuration: squeezeUpDuration) {
                self.contentView.backgroundColor = self._contentViewBackgroundColor
            }
        }
    }
}

extension FibCoreView {
	
	open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === analyticsGesture {
			return true
		}
		return false
	}
}

final public class FibSectionBackgroundView: FibCoreView {
	
	var rootBackgroundView = UIView()
	var maskBackgroundView = UIView()
	
	final public class ViewModel: FibCoreViewModel {
		public init(
			backgroundColor: UIColor = .clear,
			insets: UIEdgeInsets = .zero,
			cornerRadius: CGFloat = .zero,
			needInnerCornersMask: Bool = false,
			shadowColor: UIColor = .clear,
			shadowOpacity: CGFloat = .zero,
			shadowRadius: CGFloat = .zero,
			shadowOffset: CGSize = .zero,
			borderColor: UIColor = .clear,
			borderWidth: CGFloat = .zero
		) {
			self.backgroundColor = backgroundColor
			self.insets = insets
			self.cornerRadius = cornerRadius
			self.needInnerCornersMask = needInnerCornersMask
			self.shadowColor = shadowColor
			self.shadowOpacity = shadowOpacity
			self.shadowRadius = shadowRadius
			self.shadowOffset = shadowOffset
			self.borderColor = borderColor
			self.borderWidth = borderWidth
		}
		
		public var backgroundColor: UIColor = .clear
		public var insets: UIEdgeInsets = .zero
		public var cornerRadius: CGFloat = .zero
		public var needInnerCornersMask: Bool = false
		public var shadowColor: UIColor = .clear
		public var shadowOpacity: CGFloat = .zero
		public var shadowRadius: CGFloat = .zero
		public var shadowOffset: CGSize = .zero
		public var borderColor: UIColor = .clear
		public var borderWidth: CGFloat = .zero
		
		override public  func viewClass() -> ViewModelConfigurable.Type {
			FibSectionBackgroundView.self
		}
		
		public func backgroundColor(_ backgroundColor: UIColor) -> Self {
			self.backgroundColor = backgroundColor
			return self
		}
		public func insets(_ insets: UIEdgeInsets) -> Self {
			self.insets = insets
			return self
		}
		public func cornerRadius(_ cornerRadius: CGFloat) -> Self {
			self.cornerRadius = cornerRadius
			return self
		}
		public func needInnerCornersMask(_ needInnerCornersMask: Bool) -> Self {
			self.needInnerCornersMask = needInnerCornersMask
			return self
		}
		public func shadowColor(_ shadowColor: UIColor) -> Self {
			self.shadowColor = shadowColor
			return self
		}
		public func shadowOpacity(_ shadowOpacity: CGFloat) -> Self {
			self.shadowOpacity = shadowOpacity
			return self
		}
		public func shadowRadius(_ shadowRadius: CGFloat) -> Self {
			self.shadowRadius = shadowRadius
			return self
		}
		public func shadowOffset(_ shadowOffset: CGSize) -> Self {
			self.shadowOffset = shadowOffset
			return self
		}
		public func borderColor(_ borderColor: UIColor) -> Self {
			self.borderColor = borderColor
			return self
		}
		public func borderWidth(_ borderWidth: CGFloat) -> Self {
			self.borderWidth = borderWidth
			return self
		}
	}
	
	public override func configureUI() {
		super.configureUI()
		contentView.zStackAddSubviews {
			rootBackgroundView
			maskBackgroundView
		}
	}
	
	override public func layoutSubviews() {
		super.layoutSubviews()
		
		rootBackgroundView.frame = bounds
		guard let data = data as? ViewModel else { return }
		maskBackgroundView.frame = bounds.inset(by: data.insets)
		rootBackgroundView.layer.shadowOffset = data.shadowOffset
		rootBackgroundView.layer.shadowOpacity = Float(data.shadowOpacity)
		rootBackgroundView.layer.shadowRadius = data.shadowRadius
		rootBackgroundView.layer.borderWidth = data.borderWidth
		
		rootBackgroundView.layer.shadowColor = data.shadowColor.cgColor
		rootBackgroundView.layer.borderColor = data.borderColor.cgColor
		rootBackgroundView.backgroundColor = data.backgroundColor
		rootBackgroundView.layer.cornerRadius = data.cornerRadius
		if data.needInnerCornersMask {
			let minimalInset = min(
				data.insets.top, min(
					data.insets.left, min(
						data.insets.right,
						data.insets.bottom)))
			maskBackgroundView.layer.cornerRadius = data.cornerRadius - minimalInset
		}
	}
}
