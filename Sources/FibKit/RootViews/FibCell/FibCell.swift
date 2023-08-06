//
//  FibCell.swift
//  SmartStaff
//
//  Created artem on 24.04.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
//  Template generated by Balashov Artem @pockerhead
//


import SkeletonView
import UIKit
import VisualEffectView

public final class FibCell: RoundedCell, StickyHeaderView {
	
	public struct Appearance {
		public init(
			backgroundColor: UIColor? = nil,
			contentViewBorderColor: UIColor? = nil
		) {
			self.backgroundColor = backgroundColor
			self.contentViewBorderColor = contentViewBorderColor
		}
		
		public var backgroundColor: UIColor?
		public var contentViewBorderColor: UIColor?
	}

	public static var defaultAppearance = Appearance(
		backgroundColor: .secondarySystemBackground,
		contentViewBorderColor: .separator)
	
	public var appearance: Appearance? {
		nil
	}
	
	var fbBackgroundColor: UIColor? {
		appearance?.backgroundColor ?? FibCell.defaultAppearance.backgroundColor
	}
	
	var contentViewBorderColor: UIColor? {
		appearance?.contentViewBorderColor ?? FibCell.defaultAppearance.contentViewBorderColor
	}
    // MARK: Outlets

    // MARK: Properties
    public let formView = FibGrid()

    var _needUserInteraction: Bool = false
    override public var needUserInteraction: Bool { _needUserInteraction }
    private var _additionalBackgroundColor: UIColor?
    public var needRound: Bool = true
    var needBlurBackground = false
    var insets: UIEdgeInsets = .zero
    var borderStyle: ViewModel.BorderStyle = .shadow
    private lazy var blurView: VisualEffectView = {
        let view = VisualEffectView()
        view.colorTint = UIColor.clear
        view.colorTintAlpha = 0.1
        view.blurRadius = 16
        return view
    }()
    fileprivate var getSize: ((CGSize) -> Void)?

    // MARK: Initialization

    override public  func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureUI()
    }

    // MARK: UI Configuration

    private func configureUI() {
        contentView.addSubview(formView)
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        formView.isScrollEnabled = false
        formView.animated = false
        formView.layer.cornerRadius = 12
        formView.clipsToBounds = true
        formView.layer.masksToBounds = true
        contentView.addSubview(blurView)
        contentView.sendSubviewToBack(blurView)
        blurView.fillSuperview()
        blurView.layer.masksToBounds = true
        blurView.clipsToBounds = true
        blurView.isHidden = !needBlurBackground
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
		if borderStyle == .none {
			self.layer.clearShadow()
			layer.cornerRadius = 12
			contentView.layer.cornerRadius = 12
			formView.layer.cornerRadius = 12
		} else if needRound {
            if borderStyle == .border {
                self.layer.clearShadow()
				contentView.layer.borderColor = contentViewBorderColor?.cgColor
                contentView.layer.borderWidth = 1
            }
            layer.cornerRadius = 12
            contentView.layer.cornerRadius = 12
            formView.layer.cornerRadius = 12
        } else {
            self.layer.clearShadow()
            layer.cornerRadius = 0
            contentView.layer.cornerRadius = 0
            formView.layer.cornerRadius = 0
        }
    }
    
    public func sizeChanged(size: CGSize, initialHeight: CGFloat, maxHeight: CGFloat?, minHeight: CGFloat?) {
        UIView.performWithoutAnimation {
            let clampedChangedHeight = size.height
                .clamp(minHeight ?? -.greatestFiniteMagnitude, maxHeight ?? .greatestFiniteMagnitude)
            let diff = clampedChangedHeight - initialHeight
            formView.setContentOffset(.init(x: formView.contentOffset.x, y: -diff), animated: false)
        }
    }

}

// MARK: ViewModelConfigurable

extension FibCell: FibViewHeader {

    /// View Model for FormViewCell, contains default parameters of ViewModelWithViewClass, and sections for inner FormView
    public final class ViewModel: FibViewHeaderViewModel, CollectionReloadable {

        // MARK: - CornerStyle
        
        public enum BorderStyle {
            case shadow
            case border
			case none
        }
        
        // MARK: - Collection reloadable
        
        public var collectionView: CollectionView? {
            get {
                _grid
            }
            set {
                ()
            }
        }
        weak var _grid: FibGrid?
        public func setNeedsReload() {
            _grid?.setNeedsReload()
        }
        public func reloadData() {
            _grid?.reloadData(contentOffsetAdjustFn: nil)
        }
        
        /// Sections for inner FormView, work equally that default FormView
        public var provider: Provider?
        public var sizeHash: String?
        public var storedId: String?
        public var storedSections: [GridSection] = []
        public var size: NilSize?
        public var backgroundColor: UIColor?
        public var atTop: Bool = false
        public var needRound: Bool = true
        public var delay: TimeInterval?
        public var needBlurBackground = false
        public private(set) var allowedStretchDirections: Set<StretchDirection> = []
        /// if needs squeeze animation
        public var needUserInteraction: Bool = false
        public private(set) var minHeight: CGFloat? = 0
        public var getSizeClosure: ((CGSize) -> Void)?
        public private(set) var insets: UIEdgeInsets = .zero
        public private(set) var borderStyle: BorderStyle = .shadow
		public private(set) var disableMaskToBounds = false

        public func viewClass() -> ViewModelConfigurable.Type {
            FibCell.self
        }

        /// Inits ViewModel with declarative sections
        /// - Parameter sections: Sections for inner FormView
        public init(provider: Provider?) {
            self.provider = provider
        }
        
        /// Inits ViewModel with declarative sections
        /// - Parameter sections: Sections for inner FormView
		public func update(provider: Provider?) {
            self.provider = provider
            _grid?.provider = provider
            reloadData()
        }

        public func allowedStretchDirections(_ allowedStretchDirections: Set<StretchDirection>) -> Self {
            self.allowedStretchDirections = allowedStretchDirections
            return self
        }
        
        public func needBlur(_ need: Bool) -> Self {
            self.needBlurBackground = need
            return self
        }

        public func needRound(_ needRound: Bool) -> Self {
            self.needRound = needRound
            return self
        }
		
		public func disableMaskToBounds(_ isDisabled: Bool) -> Self {
			self.disableMaskToBounds = isDisabled
			return self
		}

        public func delay(_ delay: TimeInterval?) -> Self {
            self.delay = delay
            return self
        }

        public func backgroundColor(_ color: UIColor) -> Self {
            self.backgroundColor = color
            return self
        }

        /// SizeHash modifier
        /// - Parameter hash: sizeHash
        /// - Returns: self
        public func sizeHash(_ hash: String) -> Self {
            self.sizeHash = hash
            return self
        }
        
        public func inset(by insets: UIEdgeInsets) -> Self {
            self.insets = insets
            return self
        }

        /// Id modifier
        /// - Parameter id: unique id
        /// - Returns: self
        public func id(_ id: String) -> Self {
            self.storedId = id
            return self
        }

        public func size(_ size: NilSize) -> Self {
            self.size = size
            return self
        }

        public func atTop(_ atTop: Bool) -> Self {
            self.atTop = atTop
            return self
        }
        
        public func borderStyle(_ borderStyle: BorderStyle) -> Self {
            self.borderStyle = borderStyle
            return self
        }

        /// modifier that allows cell interact to user touches
        /// - Parameter interaction: need interaction
        /// - Returns: self
        public func needUserInteraction(_ interaction: Bool) -> Self {
            self.needUserInteraction = interaction
            return self
        }
        
        public func getSize(_ closure: ((CGSize) -> Void)?) -> Self {
            self.getSizeClosure = closure
            return self
        }
        
        public func minHeight(_ height: CGFloat) -> Self {
            self.minHeight = height
            return self
        }
    }

    public func configure(with data: ViewModelWithViewClass?) {
        guard let data = data as? ViewModel else {
            self.showAnimatedGradientSkeleton(usingGradient: .mainGradient)
            return
        }
        hideSkeleton()
        formView.fillSuperview(data.insets)
        self.insets = data.insets
        self.getSize = data.getSizeClosure
        borderStyle = data.borderStyle
        needRound = data.needRound
        data._grid = formView
		formView.provider?.animator = nil
        formView.isEmbedCollection = true
        _needUserInteraction = data.needUserInteraction
        if let additionalBackground = data.backgroundColor {
            self._additionalBackgroundColor = additionalBackground
			formView.backgroundColor = _additionalBackgroundColor ?? fbBackgroundColor
        }
        formView.isAsync = false
        blurView.isHidden = !data.needBlurBackground
        if let delayInterval = data.delay {
            delay(delayInterval, closure: ({[weak self] in
                self?.formView.provider = data.provider
            }))
        } else {
            formView.provider = data.provider
        }
		applyAppearance()
		contentView.layer.masksToBounds = !data.disableMaskToBounds
		formView.layer.masksToBounds = !data.disableMaskToBounds
    }

    public func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize? {
        guard let data = data as? ViewModel else { return nil }
        defer {
            delay {[weak self] in
                guard let self = self else { return }
                self.getSize?(self.formView.contentSize)
            }
        }
        var width = targetSize.width
        var height = targetSize.height
        if let sizeWidth = data.size?.width {
            width = sizeWidth
        }
        if let sizeHeight = data.size?.height {
            height = sizeHeight
        } else {
            frame.size.width = targetSize.width == 0 ? UIScreen.main.bounds.width : targetSize.width
            configure(with: data.delay(nil))
            layoutIfNeeded()
            formView.layoutIfNeeded()
            height = self.formView.contentSize.height + insets.verticalSum
        }
        return .init(width: width, height: height)
    }
	
	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		applyAppearance()
	}
	
	func applyAppearance() {
		backgroundColor = .clear
		formView.backgroundColor = _additionalBackgroundColor ?? fbBackgroundColor
		blurView.colorTint = .clear
	}
}

public struct NilSize {

    @available(*, deprecated, message: "Use initializer with parameters instead")
    public init() {
        width = nil
        height = nil
    }

    public init(width: CGFloat? = nil,
                height: CGFloat? = nil) {
        self.width = width
        self.height = height
    }

    public let width: CGFloat?
    public let height: CGFloat?
}
