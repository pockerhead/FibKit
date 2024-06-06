//
//  EmbedCollection.swift
//  FormView
//
//  Created artem on 15.11.2020.
//  Copyright © 2020 DIT Moscow. All rights reserved.
//
//  Template generated by Balashov Artem @pockerhead
//


import SkeletonView
import SwiftUI
import UIKit
import VisualEffectView

public class EmbedCollection: UICollectionViewCell, StickyHeaderView, UIScrollViewDelegate, FormViewAppearable {

    // MARK: Outlets

    // MARK: Properties
	private let pageCounter: UILabel = UILabel()
	private let blurView: VisualEffectView = VisualEffectView(effect: UIBlurEffect(style: .dark))
    private let blurViewContainer = UIView()
	private let counterBlurView: VisualEffectView = VisualEffectView(effect: UIBlurEffect(style: .dark))
	private let counterBlurViewContainer = UIView()
    public let formView = FibGrid()
    private var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    private var formViewHeight: CGFloat = 0
    private var pageControl = UIPageControl()
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
    // MARK: Initialization

    public override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    // MARK: UI Configuration

    public override func layoutSubviews() {
        super.layoutSubviews()
        blurViewContainer.makeOval(clipsBounds: true, animated: false)
        blurView.makeOval(clipsBounds: true, animated: false)
		counterBlurViewContainer.makeOval(clipsBounds: true, animated: false)
		counterBlurView.makeOval(clipsBounds: true, animated: false)
		
    }

    private func configureUI() {
        pageControl.addTarget(self, action: #selector(didChangePage(_:)), for: .valueChanged)
        contentView.addSubview(formView)
        formView.anchorCenterXToSuperview()
        formViewTopConstraint = formView
            .anchorWithReturnAnchors(contentView.topAnchor, topConstant: 0).first
        formViewBottomConstraint = formView
            .anchorWithReturnAnchors(bottom: contentView.bottomAnchor,
                                     bottomConstant: formViewBottomConstraintInitialConstant).first
        formViewWidthConstraint = formView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1)
        formViewWidthConstraint?.isActive = true
        contentView.addSubview(blurViewContainer)
        blurViewContainer.addSubview(blurView)
        blurView.fillSuperview()
		formView.isAsync = false
        blurViewContainer.clipsToBounds = true
        blurViewContainer.layer.masksToBounds = true
		contentView.addSubview(counterBlurViewContainer)
		counterBlurViewContainer.addSubview(counterBlurView)
		counterBlurView.fillSuperview()
		counterBlurViewContainer.clipsToBounds = true
		counterBlurViewContainer.layer.masksToBounds = true
		counterBlurView.colorTint = UIColor.black.withAlphaComponent(0.3)
		counterBlurView.colorTintAlpha = 0.2
		counterBlurView.blurRadius = 16
        contentView.addSubview(pageControl)
        blurView.colorTint = UIColor.black.withAlphaComponent(0.3)
        blurView.colorTintAlpha = 0.2
        blurView.blurRadius = 16
        formView.showsHorizontalScrollIndicator = false
        formView.clipsToBounds = false
        formView.layer.masksToBounds = false
        contentView.clipsToBounds = false
        contentView.layer.masksToBounds = false
        clipsToBounds = false
        layer.masksToBounds = false
		
		contentView.addSubview(pageCounter)
		pageCounter.textColor = .white
		pageCounter.font = .systemFont(ofSize: 12)
		pageCounter.textAlignment = .center
		pageCounter.translatesAutoresizingMaskIntoConstraints = false
//        if #available(iOS 14.0, *) {
//            pageControl.backgroundStyle = .prominent
//        } else {
		blurViewContainer.anchor(top: pageControl.topAnchor,
								 left: pageControl.leftAnchor,
								 bottom: pageControl.bottomAnchor,
								 right: pageControl.rightAnchor ,
								 insets: UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 28))
       // }
		
		counterBlurViewContainer.anchor(top: pageCounter.topAnchor,
								 left: pageCounter.leftAnchor,
								 bottom: pageCounter.bottomAnchor,
								 right: pageCounter.rightAnchor ,
								 insets: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4))
		
        pageControl.anchorCenterXToSuperview()
        pageControl.anchor(size: CGSize(width: 0, height: 24))
        pageControlBottomConstraint = pageControl
            .anchorWithReturnAnchors(bottom: contentView.bottomAnchor,
                                     bottomConstant: pageControlBottomConstant).first
        NSLayoutConstraint.activate([
            pageControl.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 0),
            pageControl.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: 0)
        ])
		
		
		NSLayoutConstraint.activate([
			pageCounter.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
			pageCounter.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
			pageCounter.widthAnchor.constraint(equalToConstant: 32),
			pageCounter.heightAnchor.constraint(equalToConstant: 20)
			
		])
        formView.delegate = self
    }
    @objc private func didChangePage(_ control: UIPageControl) {
		updateCounter()
        _ = try? self.formView.scroll(to: IndexPath(item: self.pageControl.currentPage, section: 0), animated: true)
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
        guard scrollView.isPagingEnabled else { return }
        let currentPage = Int((scrollView.contentOffset.x + scrollView.frame.width / 2) / scrollView.frame.width)
            .clamp(0, pagesCount)
        pageControl.currentPage = currentPage
		updateCounter()
    }
	
	private func updateCounter() {
		pageCounter.text = "\(pageControl.currentPage + 1)/\(pageControl.numberOfPages)"
	}
}

// MARK: ViewModelConfigurable

extension EmbedCollection: FibViewHeader {

    public final class ViewModel: FibViewHeaderViewModel {

        public var provider: Provider?
        public var clipsToBounds: Bool = false
        public var needBlur: Bool = true
        public var backgroundColor: UIColor = .clear
        public var initialHeight: CGFloat? { formViewHeight }
        public var formViewHeight: CGFloat = 0
        public var storedId: String?
        public var scrollDirection: UICollectionView.ScrollDirection = .horizontal
        public var pagingEnabled: Bool = false
        public var needBounce: Bool = true
        public var size: CGSize?
        public var atTop: Bool = true
        public var allowedStretchDirections: Set<StretchDirection> = []
        public var offset: CGFloat = 0
		public var needPageControl = false
		public var pageControlBottomOffset: CGFloat = 12
		public var needPageCounter: Bool = false
		public var selectedPage: Int?
		public var isScrollEnabled = true
        public var scrollDidScroll: ((UIScrollView) -> Void)?
        public var onAppear: ((EmbedCollection) -> Void)?
        public var onDissappear: ((EmbedCollection) -> Void)?
        
        public var id: String? {
            storedId
        }

        public var storedSizeHash: String?

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

		public func paging(_ enabled: Bool, selectedPage: Int? = nil, needPageControl: Bool = true) -> ViewModel {
            self.pagingEnabled = enabled
			self.needPageControl = needPageControl
			self.selectedPage = selectedPage
            return self
        }
		
		public func pageControlBottom(_ offset: CGFloat) -> ViewModel {
			self.pageControlBottomOffset = offset
			return self
		}
		
		public func pageCounter(_ isVisible: Bool) -> ViewModel {
			self.needPageCounter = isVisible
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

        public func needBlur(_ need: Bool) -> ViewModel {
            self.needBlur = need
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
        guard let data = data as? ViewModel else { return .zero }
        var size = targetSize
        if data.scrollDirection == .horizontal {
            size.height = data.formViewHeight
        } else {
            formView.frame.size = targetSize
            configure(with: data)
            formView.reloadData()
            size.height = formView.contentSize.height
        }
        return size
    }

    public func configure(with data: ViewModelWithViewClass?) {
        guard let data = data as? ViewModel else {
            showAnimatedGradientSkeleton(usingGradient: .mainGradient)
            return
        }
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
		pageControlBottomConstant = data.pageControlBottomOffset
		pageControlBottomConstraint?.constant =  pageControlBottomConstant * -1
		pageControl.numberOfPages = data.provider?.numberOfItems ?? 0//data.sections.first?.dataSource.data.count ?? 0
        pagesCount = pageControl.numberOfPages
		pageControl.isHidden = (!data.pagingEnabled || pageControl.numberOfPages <= 1) || !data.needPageControl
        blurView.isHidden = pageControl.isHidden
        blurViewContainer.isHidden = pageControl.isHidden
		pageCounter.isHidden = !data.needPageCounter
		counterBlurViewContainer.isHidden = pageCounter.isHidden
		counterBlurView.isHidden = pageCounter.isHidden
        formViewBottomConstraint?.constant = formViewBottomConstraintInitialConstant
		if let page = data.selectedPage {
			delay(cyclesCount: 2) {[weak self] in
				guard let self = self else { return }
				do {
					try self.formView.scroll(to: IndexPath(item: page, section: 0), animated: true, bounce: 8)
				} catch {
					debugPrint("error \(error.localizedDescription)")
				}
			}
		}
		updateCounter()
        applyAppearance()
    }
	
	func applyAppearance() {
		contentView.backgroundColor = .clear
		formView.backgroundColor = formViewBackgroundColor
	}
}

public struct Embed: UIViewRepresentable {
    public var viewModel: EmbedCollection.ViewModel

    public func makeUIView(context: Context) -> EmbedCollection {
        let view = EmbedCollection.fromDequeuer() ?? EmbedCollection()
        view.alpha = 1
        return view
    }

    public func updateUIView(_ uiView: EmbedCollection, context: Context) {
        uiView.configure(with: viewModel)
    }

    public init(viewModel: EmbedCollection.ViewModel) {
        self.viewModel = viewModel
    }
}
