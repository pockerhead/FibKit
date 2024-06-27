//
//  EmbedCollection.swift
//  FormView
//
//  Created artem on 15.11.2020.
//  Copyright © 2020 DIT Moscow. All rights reserved.
//
//  Template generated by Balashov Artem @pockerhead
//
import UIKit

public protocol EmbedPagerView: UIView {
	var currentPage: Int { get set }
	var numberOfPages: Int { get set }
	var initialSize: CGSize { get set }
	var pageChanged: ((Int) -> Void)? { get set }
}

public class EmbedCollection: UICollectionViewCell, StickyHeaderView, UIScrollViewDelegate, FormViewAppearable {
	
	// MARK: Outlets
	
	// MARK: Properties
	public let formView = FibGrid()
	private var scrollDirection: UICollectionView.ScrollDirection = .horizontal
	private var formViewHeight: CGFloat = 0
	private var formViewBackgroundColor: UIColor?
	private var scrollDidScroll: ((UIScrollView) -> Void)?
	private var pagesCount: Int = 0
	private var offset: CGFloat = 0
	private var formViewBottomConstraintInitialConstant: CGFloat {
		offset
	}
	private var formViewTopConstraint: NSLayoutConstraint?
	private var formViewBottomConstraint: NSLayoutConstraint?
	private var formViewWidthConstraint: NSLayoutConstraint?
	private var pageControlBottomConstraint: NSLayoutConstraint?
	private var pageControlBottomConstant: CGFloat = 12
	
	private var onAppear: ((EmbedCollection) -> Void)?
	private var onDissappear: ((EmbedCollection) -> Void)?
	private var pagerView: EmbedPagerView?
	private var pageControlView: EmbedPagerView?
	private var needAnimation: Bool

	private var pagerViewOffset: (dx: CGFloat,dy: CGFloat) = (0,0)
	private var pageControlViewOffset: (dx: CGFloat,dy: CGFloat) = (0,0)
	private var isPageControlScrolling: Bool = false
	
	// MARK: Initialization
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		configureUI()
	}
	
	// MARK: UI Configuration
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		if let pagerViewSize = pagerView?.initialSize {
			pagerView?.frame = .init(origin: .init(x: bounds.width - pagerViewSize.width, y: 0), size: pagerViewSize).offsetBy(dx: pagerViewOffset.dx, dy: pagerViewOffset.dy)
		}
		
		if let pageControlSize = pageControlView?.initialSize {
			pageControlView?.frame = .init(origin: .init(x: bounds.center.x - pageControlSize.width/2, y: bounds.height - pageControlSize.height), size: pageControlSize).offsetBy(dx: pageControlViewOffset.dx, dy: pageControlViewOffset.dy)
		}
		
		
	}
	
	private func configureUI() {
		contentView.addSubview(formView)
		formView.anchorCenterXToSuperview()
		formViewTopConstraint = formView
			.anchorWithReturnAnchors(contentView.topAnchor, topConstant: 0).first
		formViewBottomConstraint = formView
			.anchorWithReturnAnchors(bottom: contentView.bottomAnchor,
									 bottomConstant: formViewBottomConstraintInitialConstant).first
		formViewWidthConstraint = formView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1)
		formViewWidthConstraint?.isActive = true
		formView.showsHorizontalScrollIndicator = false
		formView.clipsToBounds = false
		formView.layer.masksToBounds = false
		contentView.clipsToBounds = false
		contentView.layer.masksToBounds = false
		clipsToBounds = false
		layer.masksToBounds = false
		formView.delegate = self
	}
	
	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		applyAppearance()
	}
	
	public func onAppear(with formView: FibGrid?) {
		onAppear?(self)
	}
	
	public func onDissappear(with formView: FibGrid?) {
		onDissappear?(self)
	}
	
	public func sizeChanged(size: CGSize, initialHeight: CGFloat, maxHeight: CGFloat?, minHeight: CGFloat?) {
		let percentage = (size.height / initialHeight).clamp(1, .greatestFiniteMagnitude)
		formView.transform = .init(scaleX: percentage,
								   y: percentage)
		let bottomOffset = max((size.height - initialHeight), 0)
		pageControlBottomConstraint?.constant = pageControlBottomConstant
		- formViewBottomConstraintInitialConstant
		+ bottomOffset
		contentView.layoutIfNeeded()
		formViewTopConstraint?.constant = bottomOffset / 2
	}
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		scrollDidScroll?(scrollView)
		guard !isPageControlScrolling else {
			return
		}
		guard scrollView.isPagingEnabled else { return }
		guard scrollView.frame.width > 0 else { return }
		let currentPage = Int((scrollView.contentOffset.x + scrollView.frame.width / 2) / scrollView.frame.width)
			.clamp(0, pagesCount)
		pagerView?.currentPage = currentPage
		pageControlView?.currentPage = currentPage
	}
	
	public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		if isPageControlScrolling {
			isPageControlScrolling = false
		}
	}
}

// MARK: ViewModelConfigurable

extension EmbedCollection: FibViewHeader {
	
	public final class ViewModel: FibViewHeaderViewModel {
		
		public var provider: Provider?
		public var clipsToBounds: Bool = false
		public var backgroundColor: UIColor = .clear
		public var initialHeight: CGFloat? { formViewHeight }
		public var formViewHeight: CGFloat = 0
		public var storedId: String?
		public var scrollDirection: UICollectionView.ScrollDirection = .horizontal
		public var pagingEnabled: Bool = false
		public var pagerView: EmbedPagerView? = nil
		public var pageControlView: EmbedPagerView? = nil
		public var pagerViewOffset: (dx: CGFloat,dy: CGFloat) = (0,0)
		public var pageControlViewOffset: (dx: CGFloat,dy: CGFloat) = (0,0)
		public var needBounce: Bool = true
		public var size: CGSize?
		public var atTop: Bool = true
		public var allowedStretchDirections: Set<StretchDirection> = []
		public var offset: CGFloat = 0
		public var selectedPage: Int?
		public var isScrollEnabled = true
		public var scrollDidScroll: ((UIScrollView) -> Void)?
		public var onAppear: ((EmbedCollection) -> Void)?
		public var onDissappear: ((EmbedCollection) -> Void)?
		public var needAnimation: Bool = true

		public var id: String? {
			storedId
		}
		
		public var storedSizeHash: String?
		
		public func selectedPage(_ page: Int) -> ViewModel {
			self.selectedPage = page
			return self
		}
		
		public func pagerView(_ pager: EmbedPagerView, offset: (dx: CGFloat,dy: CGFloat) = (0,0)) -> ViewModel {
			self.pagingEnabled = true
			self.pagerView = pager
			self.pagerViewOffset = offset
			return self
		}
		
		public func pageControlView(_ pager: EmbedPagerView, offset: (dx: CGFloat,dy: CGFloat) = (0,0)) -> ViewModel {
			self.pagingEnabled = true
			self.pageControlView = pager
			self.pageControlViewOffset = offset
			return self
		}
		
		public func paging(_ enabled: Bool, selectedPage: Int? = nil) -> ViewModel {
			self.pagingEnabled = enabled
			self.selectedPage = selectedPage
			return self
		}
		
		public var sizeHash: String? {
			storedSizeHash
		}
		
		public init(provider: Provider?) {
			self.provider = provider
		}
		
		public func allowedStretchDirections(_ allowedStretchDirections: Set<StretchDirection>) -> ViewModel {
			self.allowedStretchDirections = allowedStretchDirections
			return self
		}
		
		public func atTop(_ atTop: Bool) -> ViewModel {
			self.atTop = atTop
			return self
		}

		public func scrollEnabled(_ flag: Bool) -> ViewModel {
			self.isScrollEnabled = false
			return self
		}
		
		public func id(_ id: String) -> ViewModel {
			self.storedId = id
			return self
		}
		
		public func bounces(_ needBounce: Bool) -> ViewModel {
			self.needBounce = needBounce
			return self
		}
		
		public func offset(_ offset: CGFloat) -> ViewModel {
			self.offset = offset
			return self
		}
		
		public func size(_ size: CGSize) -> ViewModel {
			self.size = size
			return self
		}
		
		public func height(_ height: CGFloat) -> ViewModel {
			self.formViewHeight = height
			return self
		}
		
		public func sizeHash(_ hash: String) -> ViewModel {
			self.storedSizeHash = hash
			return self
		}
		
		public func clipsToBounds(_ clipsToBounds: Bool) -> ViewModel {
			self.clipsToBounds = clipsToBounds
			return self
		}
		
		public func backgroundColor(_ color: UIColor) -> ViewModel {
			self.backgroundColor = color
			return self
		}
		
		public func scrollDirection(_ direction: UICollectionView.ScrollDirection) -> ViewModel {
			self.scrollDirection = direction
			return self
		}
		
		public func scrollDidScroll(_ closure: ((UIScrollView) -> Void)?) -> Self {
			self.scrollDidScroll = closure
			return self
		}
		
		public func onAppear(_ onAppear: ((EmbedCollection) -> Void)?) -> Self {
			self.onAppear = onAppear
			return self
		}
		
		public func onDissappear(_ onDissappear: ((EmbedCollection) -> Void)?) -> Self {
			self.onDissappear = onDissappear
			return self
		}

		public func needAnimation(_ needAnimation: Bool) -> Self {
			self.needAnimation = needAnimation
			return self
		}

		public func viewClass() -> ViewModelConfigurable.Type {
			EmbedCollection.self
		}
	}
	
	public override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
		var size = targetSize
		if scrollDirection == .horizontal {
			size.height = formViewHeight
		} else {
			size.height = formView.contentSize.height
		}
		return size
	}
	
	public func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize? {
		guard let data = data as? ViewModel else { return nil }
		
		var width = targetSize.width
		var height = targetSize.height
		
		if data.scrollDirection == .horizontal {
			height = data.formViewHeight
		} else {
			if let sizeWidth = data.size?.width {
				width = sizeWidth
			}
			if let sizeHeight = data.size?.height {
				height = sizeHeight
			} else {
				data.provider?.layout(collectionSize: targetSize)
				height = data.provider?.contentSize.height ?? 0
			}
		}
		
		return .init(width: width, height: height)
	}
	
	public func configure(with data: ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else {
			showAnimatedGradientSkeleton(usingGradient: .mainGradient)
			return
		}
		self.needAnimation = data.needAnimation
		self.pagerView = data.pagerView
		if let pagerView = pagerView {
			contentView.addSubview(pagerView)
		}
		self.pageControlView = data.pageControlView
		if let pageControlView = pageControlView {
			contentView.addSubview(pageControlView)
		}
		self.scrollDidScroll = data.scrollDidScroll
		hideSkeleton()
		formView.clipsToBounds = data.clipsToBounds
		formView.layer.masksToBounds = data.clipsToBounds
		self.scrollDirection = data.scrollDirection
		self.formViewHeight = data.formViewHeight
		let isScrollHorizontal = data.scrollDirection == .horizontal
		formView.isScrollEnabled = isScrollHorizontal && data.isScrollEnabled
		offset = data.offset
		onAppear = data.onAppear
		onDissappear = data.onDissappear
		formView.isEmbedCollection = true
		formView.isPagingEnabled = data.pagingEnabled
		formView.bounces = data.needBounce
		formView.contentInsetAdjustmentBehavior = .never
		formViewBackgroundColor = data.backgroundColor
		formView.provider = data.provider
		formView.layoutSubviews()
		pagerViewOffset = data.pagerViewOffset
		pageControlViewOffset = data.pageControlViewOffset
		pagesCount = ((data.provider as? FibKit.FibGridHeaderProvider)?.sections.first as? FibKit.FibGridProvider)?.dataSource.data.count ?? data.provider?.numberOfItems ?? 0
		self.pagerView?.numberOfPages = pagesCount
		self.pageControlView?.numberOfPages = pagesCount
		
		let scrollBlock: ((Int) -> Void)? = { [weak self] page in
			self?.isPageControlScrolling = true
			_ = try? self?.formView.scroll(to: IndexPath(item: page, section: 0), animated: true)
		}
		pageControlView?.pageChanged = scrollBlock
		pagerView?.pageChanged = scrollBlock
		
		if let page = data.selectedPage {
			scroll(to: page)
		}
		applyAppearance()
	}
	
	private func scroll(to page: Int) {
		delay(cyclesCount: 10) {[weak self] in
			guard let self = self else { return }
			do {
				try self.formView.scroll(to: IndexPath(item: page, section: 0), animated: needAnimation, bounce: 8)
			} catch {
				debugPrint("error \(error.localizedDescription)")
			}
		}
	}
	
	func applyAppearance() {
		contentView.backgroundColor = .clear
		formView.backgroundColor = formViewBackgroundColor
	}
}
