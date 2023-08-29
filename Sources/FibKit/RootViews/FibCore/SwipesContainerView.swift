//
//  SwipesContainerView.swift
//  SmartStaff
//
//  Created by Артём Балашов on 05.07.2021.
//  Copyright © 2021 DIT. All rights reserved.
//

public class SwipesContainerView: UIView {
	
	var mainSwipeView: FibSwipeView?
	var secondSwipeView: FibSwipeView?
	var thirdSwipeView: FibSwipeView?
	
	var swipeEdge: Edge = .left
	var stretchEmitMainAction: Bool = false
	let swipeViewWidth: CGFloat = 84
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	func configureUI() {

	}
	
	struct ViewModel {
		var mainSwipeView: FibSwipeViewModel
		var secondSwipeView: FibSwipeViewModel?
		var thridSwipeView: FibSwipeViewModel?
		var stretchEmitMainAction: Bool = false
		var edge: Edge = .right
	}
	
	public enum Edge {
		case left
		case right
	}
	
	func getMaxXToStretch() -> CGFloat {
		let visibles: [FibSwipeView] = [mainSwipeView, secondSwipeView, thirdSwipeView].compactMap({ $0 })
			.filter({ !$0.isHidden })
		return (visibles.reduce(into: 0, { acc, n in acc += 84 }) + 60)
	}
	
	func processSwipe(with offset: CGFloat) {
		let visibles: [FibSwipeView] = [mainSwipeView, secondSwipeView, thirdSwipeView].compactMap({ $0 })
		.filter({ !$0.isHidden })
		let perViewOffset = offset / CGFloat(visibles.count)
		func getViewXOffset(from index: Int) -> CGFloat {
			var x: CGFloat = (CGFloat(index + 1) * perViewOffset).clamp(0, (CGFloat(index) + 1) * swipeViewWidth)
			if swipeEdge == .left {
				x = bounds.width - x
			} else {
				x = x - swipeViewWidth
			}
			return x
		}
		visibles
			.enumerated()
			.forEach({ index, view in
				let x = getViewXOffset(from: index)
				let y: CGFloat = 0
				if isStretchedMainView && index == 0 {
					if swipeEdge == .left {
						view.frame = .init(origin: .init(x: bounds.width - offset - 16,
														 y: 0),
										   size: .init(width: offset + 16,
													   height: bounds.height))
					} else {
						view.frame = .init(origin: .init(x: 0,
														 y: 0),
										   size: .init(width: offset + 16,
													   height: bounds.height))
					}
					return
				} else {
					view.frame.origin = CGPoint(x: x, y: y)
				}
			})
		if stretchEmitMainAction, offset > getMaxXToStretch(), !isStretchedMainView {
			isStretchedMainView = true
			DispatchQueue.main.async {
				UISelectionFeedbackGenerator().selectionChanged()
			}
			self.mainSwipeView?.swipeEdge = self.swipeEdge
			UIView.animate(withDuration: 0.2, delay: 0, options: [.layoutSubviews, .allowAnimatedContent, .beginFromCurrentState]) {
				if self.swipeEdge == .left {
					self.mainSwipeView?.frame = .init(origin: .init(x: self.bounds.width - offset - 16, y: 0), size: .init(width: offset + 16, height: self.bounds.height))
					
				} else {
					self.mainSwipeView?.frame = .init(origin: .init(x: 0, y: 0), size: .init(width: offset + 16, height: self.bounds.height))
				}
			}
		} else if stretchEmitMainAction, offset <= getMaxXToStretch(), isStretchedMainView {
			isStretchedMainView = false
			DispatchQueue.main.async {
				UISelectionFeedbackGenerator().selectionChanged()
			}
			self.mainSwipeView?.swipeEdge = nil
			UIView.animate(withDuration: 0.2, delay: 0, options: [.layoutSubviews, .allowAnimatedContent, .beginFromCurrentState]) {
				self.mainSwipeView?.frame = .init(origin: .init(x: getViewXOffset(from: 1), y: 0), size: .init(width: self.swipeViewWidth, height: self.bounds.height))
			}
		}
	}
	
	var isStretchedMainView = false
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		if !isStretchedMainView {
			mainSwipeView?.frame.size = .init(width: swipeViewWidth, height: bounds.height)
		}
		[secondSwipeView, thirdSwipeView].compactMap({$0}).forEach({
			$0.frame.size = .init(width: swipeViewWidth, height: bounds.height)
		})
	}
	
	public func getSwipesWidth() -> CGFloat {
		var width = swipeViewWidth
		if let secondSwipeView = secondSwipeView, secondSwipeView.isHidden == false {
			width += swipeViewWidth
		}
		if let thirdSwipeView = thirdSwipeView, thirdSwipeView.isHidden == false {
			width += swipeViewWidth
		}
		return width
	}
	
	func configure(with viewModel: ViewModel) {
		[mainSwipeView, secondSwipeView, thirdSwipeView].forEach {
			$0?.removeFromSuperview()
		}
		
		mainSwipeView = viewModel.mainSwipeView.getView() as? FibSwipeView
		secondSwipeView = viewModel.secondSwipeView?.getView() as? FibSwipeView
		thirdSwipeView = viewModel.thridSwipeView?.getView() as? FibSwipeView
		
		if let mainSwipeView = mainSwipeView {
			addSubview(mainSwipeView)
		}
		if let secondSwipeView = secondSwipeView {
			addSubview(secondSwipeView)
		}
		if let thirdSwipeView = thirdSwipeView {
			addSubview(thirdSwipeView)
		}
		
		mainSwipeView?.configure(with: viewModel.mainSwipeView)
		stretchEmitMainAction = viewModel.stretchEmitMainAction
		var swipeViewToFillBackground = viewModel.mainSwipeView
		if let second = viewModel.secondSwipeView {
			secondSwipeView?.configure(with: second)
			secondSwipeView?.isHidden = false
			swipeViewToFillBackground = second
		} else {
			secondSwipeView?.isHidden = true
		}
		
		if let third = viewModel.thridSwipeView {
			thirdSwipeView?.configure(with: third)
			thirdSwipeView?.isHidden = false
			swipeViewToFillBackground = third
		} else {
			thirdSwipeView?.isHidden = true
		}
		if viewModel.edge == .left {
			backgroundColor = swipeViewToFillBackground.backgroundColor
		} else {
			backgroundColor = swipeViewToFillBackground.secondGradientColor ?? swipeViewToFillBackground.backgroundColor.fade(toColor: .black, withPercentage: 0.1)
		}
		self.swipeEdge = viewModel.edge
		setNeedsLayout()
	}
}
