//
//  SwiftUIWrapperPassthroughContainer.swift
//  FormView
//
//  Created by Артём Балашов on 24.02.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//


import SwiftUI
import UIKit

public class PassthroughView: UIControl {

    var tappedHander: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initCommon()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initCommon()
    }

    private func initCommon() {
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @objc func tapped() {
        tappedHander?()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self && tappedHander == nil ? nil : view
    }
}

public class SwiftUIWrapperPassthroughContainer<Content>: PassthroughView, StickyHeaderView, FibViewHeader where Content: View {
    
    var hosting = UIHostingController<SwiftUIWrapperView<Content>>(rootView: SwiftUIWrapperView())
    var hostingView: UIView {
        hosting.view
    }
    var wrapperSize: SwiftUIWrapper<Content>.Size?
    var _needUserInteraction: Bool = false
    weak var swiftUIWrapperModel: SwiftUIWrapper<Content>?

    var needConstraintLayout = true
    var hostingViewConstraintLayouted = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.rasterizationScale = UIScreen.main.scale
        clipsToBounds = false
        layer.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        hostingView.backgroundColor = .clear
        if !needConstraintLayout {
            hostingView.frame = bounds
        }
    }
    
    func configureUI() {
        UIView.performWithoutAnimation {
            hostingView.removeFromSuperview()
            hosting = UIHostingController<SwiftUIWrapperView>(rootView: SwiftUIWrapperView(viewModel: swiftUIWrapperModel))
            addSubview(hostingView)
            hosting.view.layer.shouldRasterize = swiftUIWrapperModel?.needRasterize ?? true
            hosting.view.layer.rasterizationScale = UIScreen.main.scale
            if needConstraintLayout {
                hostingView.fillSuperview()
                hostingViewConstraintLayouted = true
            } else {
                hostingView.frame = bounds
                hostingViewConstraintLayouted = false
            }
        }
    }
    
    public override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                                 withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                                 verticalFittingPriority: UILayoutPriority) -> CGSize {
        frame.size = targetSize
        hostingView.frame = bounds
        var selfSize = hostingView.systemLayoutSizeFitting(targetSize,
                                                           withHorizontalFittingPriority: horizontalFittingPriority,
                                                           verticalFittingPriority: verticalFittingPriority)
        if let size = wrapperSize {
            switch size.width {
            case .absolute(let value): selfSize.width = value
            case .inherit:
                if horizontalFittingPriority == .required { selfSize.width = targetSize.width }
            case .selfSized: break
            }
            switch size.height {
            case .absolute(let value): selfSize.height = value
            case .inherit:
                if verticalFittingPriority == .required { selfSize.height = targetSize.height }
            case .selfSized: break
            }
        }
        return selfSize
    }
    
    public func configure(with data: ViewModelWithViewClass?) {
        guard let data = data as? SwiftUIWrapper<Content> else { return }
        UIView.performWithoutAnimation {
            layer.shouldRasterize = data.needRasterize
            hosting.view.layer.shouldRasterize = data.needRasterize
            self.wrapperSize = data.size
            if let wrapperSize = wrapperSize {
                if wrapperSize.width == .selfSized {
                    needConstraintLayout = false
                    if hostingViewConstraintLayouted {
                        configureUI()
                    }
                } else {
                    needConstraintLayout = true
                    if !hostingViewConstraintLayouted {
                        configureUI()
                    }
                }
            }
            self._needUserInteraction = data.interactive
            self.swiftUIWrapperModel = data
            hosting.rootView.viewModel = data
        }
    }
	
	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		configureUI()
	}
}
