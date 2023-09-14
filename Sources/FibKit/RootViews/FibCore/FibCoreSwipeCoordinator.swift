//
//  FibCoreSwipeCoordinator.swift
//  SmartStaff
//
//  Created by Артём Балашов on 05.07.2021.
//  Copyright © 2021 DIT. All rights reserved.
//

public class FibCoreSwipeCoordinator: NSObject {
	// MARK: - Namespace Classes
	final class WrapperPanGR: UIPanGestureRecognizer {}
	final class WrapperSwipeGR: UISwipeGestureRecognizer {}
	
	weak var fibCoreView: FibCoreView?
	
	var haveSwipeAction = false
	var isSwipeOpen: Bool = false {
		didSet {
			if oldValue != isSwipeOpen, isSwipeOpen {
				onSwipeOpenClosure?()
			}
		}
	}
	var openedSwipe: SwipeType?
	var rightSwipeViews: SwipesContainerView.ViewModel?
	var leftSwipeViews: SwipesContainerView.ViewModel?
	var onSwipeOpenClosure: (() -> ())?
	lazy var swipeRight: WrapperSwipeGR = {
		let gs = WrapperSwipeGR(target: self, action: #selector(swipeGest(_:)))
		gs.delegate = self
		return gs
	}()
	lazy var swipeLeft: WrapperSwipeGR = {
		let gs = WrapperSwipeGR(target: self, action: #selector(swipeGest(_:)))
		gs.delegate = self
		return gs
	}()
	lazy var pan: WrapperPanGR = {
		let gs = WrapperPanGR(target: self, action: #selector(panGest(_:)))
		gs.delegate = self
		return gs
	}()
	var rightSwipeViewsWidth: CGFloat?
	var leftSwipeViewsWidth: CGFloat?
	lazy var leftSwipesContainer = SwipesContainerView()
	lazy var rightSwipesContainer = SwipesContainerView()
	
	init(fibCoreView: FibCoreView?) {
		self.fibCoreView = fibCoreView
	}
	
	func configure(with viewModel: FibCoreViewModel) {
		rightSwipeViews = viewModel.rightSwipeViews
		leftSwipeViews = viewModel.leftSwipeViews
		if let left = leftSwipeViews {
			leftSwipesContainer.configure(with: left)
			haveSwipeAction = true
		}
		if let right = rightSwipeViews {
			rightSwipesContainer.configure(with: right)
			haveSwipeAction = true
		}
		if haveSwipeAction {
			fibCoreView?.addGestureRecognizer(swipeLeft)
			fibCoreView?.addGestureRecognizer(swipeRight)
			fibCoreView?.addGestureRecognizer(pan)
		}
	}
	
	public func configureUI() {
		
	}
	
	func addSwipeViewsIfNeeded() {
		guard haveSwipeAction else { return }
		guard leftSwipesContainer.superview == nil,
			  rightSwipesContainer.superview == nil else { return }
		if let left = leftSwipeViews {
			leftSwipesContainer.configure(with: left)
			fibCoreView?.addSubview(leftSwipesContainer)
			fibCoreView?.sendSubviewToBack(leftSwipesContainer)
			leftSwipesContainer.frame = fibCoreView?.bounds ?? .zero
			rightSwipeViewsWidth = leftSwipesContainer.getSwipesWidth()
		}
		if let right = rightSwipeViews {
			rightSwipesContainer.configure(with: right)
			fibCoreView?.addSubview(rightSwipesContainer)
			fibCoreView?.sendSubviewToBack(rightSwipesContainer)
			rightSwipesContainer.frame = fibCoreView?.bounds ?? .zero
			leftSwipeViewsWidth = rightSwipesContainer.getSwipesWidth()
		}
	}
	
	func prepareForReuse() {
		haveSwipeAction = false
		isSwipeOpen = false
		leftSwipesContainer.removeFromSuperview()
		rightSwipesContainer.removeFromSuperview()
	}
	
	@objc func swipeGest(_ sender: UISwipeGestureRecognizer) {
		switch sender.state {
			case .began:
				addSwipeViewsIfNeeded()
			case .ended:
				NotificationCenter.default.post(name: NSNotification.Name("startSwipeOnSwiftUIWrapper"),
												object: nil,
												userInfo: ["swipeViewRef": fibCoreView as Any])
				animateSwipe(isOpen: sender === swipeLeft,
							 swipeWidth: rightSwipeViewsWidth,
							 initialVel: max(0, abs(pan.velocity(in: pan.view).x / 100)))
			default: break
		}
	}
	
	var dragInProcess: Bool = false
	
	@objc func panGest(_ sender: UIPanGestureRecognizer) {
		guard let contentView = fibCoreView?.contentView else { return }
		switch sender.state {
			case .began:
				dragInProcess = true
				addSwipeViewsIfNeeded()
				NotificationCenter.default.post(name: NSNotification.Name("startSwipeOnSwiftUIWrapper"),
												object: nil,
												userInfo: ["swipeViewRef": fibCoreView as Any])
			case .changed:
				dragInProcess = true
				let rightSwipeWidth = rightSwipeViewsWidth ?? .zero
				let leftSwipeWidth = leftSwipeViewsWidth ?? .zero
				var swipeType: SwipeType?
				switch contentView.frame.origin.x {
					case (0...):
						swipeType = .right
						leftSwipesContainer.isHidden = true
						rightSwipesContainer.isHidden = false
					case (...0):
						swipeType = .left
						rightSwipesContainer.isHidden = true
						leftSwipesContainer.isHidden = false
					default: break
				}
				let point = sender.translation(in: sender.view)
				var pointX = point.x
				if isSwipeOpen, let swipeType = openedSwipe {
					switch swipeType {
						case .right:
							pointX = point.x - rightSwipeWidth
						case .left:
							pointX = point.x + leftSwipeWidth
					}
				}
				if contentView.frame.origin.x != 0, let swipeType = swipeType {
					switch swipeType {
						case .left:
							if !leftSwipesContainer.stretchEmitMainAction,
							   pointX < -rightSwipeWidth {
								let distance = -rightSwipeWidth - pointX
								let coef = CGFloat(1.05)
								let width = contentView.frame.width * 2
								let divider = (width + coef * distance)
								if divider != 0 {
									let adding = (distance * width * coef) / divider
									pointX += adding
									pointX = pointX.rounded(.down)
								}
							}
							let dist = Distance(x1: -rightSwipeWidth, x2: 0)
							let result = Distance(x1: 12, x2: 0).convertPoint(point: pointX + rightSwipeWidth, from: dist)
							if fibCoreView?.corneredOnSwipe == true {
								fibCoreView?.contentView.layer.cornerRadius = abs(result).clamp(0, 12)
							}
						case .right:
							if !rightSwipesContainer.stretchEmitMainAction,
							   pointX > leftSwipeWidth {
								let distance = pointX - leftSwipeWidth
								let coef = CGFloat(0.9)
								let width = contentView.frame.width * 2
								let divider = (width + coef * distance)
								if divider != 0 {
									let adding = (distance * width * coef) / divider
									pointX -= adding
								}
							}
							let dist = Distance(x1: leftSwipeWidth, x2: 0)
							let result = Distance(x1: 12, x2: 0).convertPoint(point: pointX - leftSwipeWidth, from: dist)
							if fibCoreView?.corneredOnSwipe == true {
								fibCoreView?.contentView.layer.cornerRadius = abs(result).clamp(0, 12)
							}
					}
					
				}
				let minClamp = (rightSwipeViewsWidth ?? 0) == 0 ? 0 : -contentView.frame.width
				let maxClamp = (leftSwipeViewsWidth ?? 0) == 0 ? 0 : contentView.frame.width
				if swipeType == .left {
					leftSwipesContainer.processSwipe(with: abs(pointX.clamp(minClamp, maxClamp)))
				} else {
					rightSwipesContainer.processSwipe(with: abs(pointX.clamp(minClamp, maxClamp)))
				}
				if swipeType == .left,
				   leftSwipeViews?.stretchEmitMainAction == true,
				   abs(pointX.clamp(minClamp, maxClamp)) > leftSwipesContainer.getMaxXToStretch() {
					isStretchedMainLeftView = true
				} else {
					isStretchedMainLeftView = false
				}
				if swipeType == .right,
				   rightSwipeViews?.stretchEmitMainAction == true,
				   abs(pointX.clamp(minClamp, maxClamp)) > rightSwipesContainer.getMaxXToStretch() {
					isStretchedMainRightView = true
				} else {
					isStretchedMainRightView = false
				}
				contentView.frame.origin.x = pointX.clamp(minClamp, maxClamp)
			case .cancelled, .failed, .ended:
				dragInProcess = false
				if isStretchedMainRightView {
					rightSwipeViews?.mainSwipeView.action?()
					animateSwipe(isOpen: false, swipeWidth: nil)
					return
				}
				if isStretchedMainLeftView {
					leftSwipeViews?.mainSwipeView.action?()
					animateSwipe(isOpen: false, swipeWidth: nil)
					return
				}
				let rightSwipeWidth = rightSwipeViewsWidth ?? .zero
				let leftSwipeWidth = leftSwipeViewsWidth ?? .zero
				var swipeType: SwipeType?
				switch contentView.frame.origin.x {
					case (0...): swipeType = .left
					case (...0): swipeType = .right
					default: break
				}
				let point = sender.translation(in: sender.view)
				let diff = sender.velocity(in: sender.view).x
				var pointX = point.x
				if isSwipeOpen, let swipeType = openedSwipe {
					switch swipeType {
						case .right:
							pointX = point.x - rightSwipeWidth
						case .left:
							pointX = point.x + leftSwipeWidth
					}
				}
				var swipeWidth: CGFloat = 0
				var needOpenSwipe = false
				if let swipeType = swipeType {
					switch swipeType {
						case .right:
							needOpenSwipe = pointX + diff < -rightSwipeWidth / 3
							swipeWidth = rightSwipeWidth
						case .left:
							needOpenSwipe = pointX + diff > leftSwipeWidth / 3
							swipeWidth = leftSwipeWidth
					}
					animateSwipe(direction: swipeType, isOpen: needOpenSwipe, swipeWidth: swipeWidth, initialVel: max(0, abs(diff / 100)))
				} else {
					animateSwipe(direction: .right, isOpen: false, swipeWidth: nil)
				}
			default: break
		}
	}
	var isStretchedMainLeftView = false
	var isStretchedMainRightView = false
	
	func animateSwipe(direction: SwipeType = .right,
					  isOpen: Bool,
					  swipeWidth: CGFloat?,
					  initialVel: CGFloat? = nil,
					  completion: (() -> Void)? = nil) {
		var isOpen = isOpen
		isStretchedMainRightView = false
		isStretchedMainLeftView = false
		switch direction {
			case .left:
				if rightSwipeViews.isNil {
					isOpen = false
				}
				if isOpen {
					rightSwipesContainer.isHidden = false
					leftSwipesContainer.isHidden = true
				}
			case .right:
				if leftSwipeViews.isNil {
					isOpen = false
				}
				if isOpen {
					rightSwipesContainer.isHidden = true
					leftSwipesContainer.isHidden = false
				}
		}
		openedSwipe = isOpen ? direction : nil
		self.isSwipeOpen = isOpen
		UIView.animate(
			withDuration: 0.6,
			delay: 0,
			usingSpringWithDamping: 0.9,
			initialSpringVelocity: initialVel ?? 0,
			options: [.allowUserInteraction, .beginFromCurrentState, .allowAnimatedContent],
			animations: {[weak self, weak fibCoreView] in
				if fibCoreView?.corneredOnSwipe == true {
					fibCoreView?.contentView.layer.cornerRadius = isOpen ? 12 : 0
				}
				if isOpen {
					switch direction {
						case .left:
							fibCoreView?.contentView.frame.origin.x = (swipeWidth ?? self?.leftSwipeViewsWidth ?? 0)
							self?.rightSwipesContainer.processSwipe(with: (swipeWidth ?? self?.leftSwipeViewsWidth ?? 0))
						case .right:
							fibCoreView?.contentView.frame.origin.x = -(swipeWidth ?? self?.rightSwipeViewsWidth ?? 0)
							self?.leftSwipesContainer.processSwipe(with: (swipeWidth ?? self?.rightSwipeViewsWidth ?? 0))
					}
				} else {
					fibCoreView?.contentView.frame.origin.x = 0
					self?.leftSwipesContainer.processSwipe(with: 0)
					self?.rightSwipesContainer.processSwipe(with: 0)
				}
			}, completion: {[weak self] completed in
				guard completed, self?.dragInProcess == false else { return }
				if self?.isSwipeOpen == false {
					self?.leftSwipesContainer.removeFromSuperview()
					self?.rightSwipesContainer.removeFromSuperview()
				}
				completion?()
			}
		)
	}
}

extension FibCoreSwipeCoordinator: UIGestureRecognizerDelegate {
	
	
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
								  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if let pan = gestureRecognizer as? WrapperPanGR {
			if otherGestureRecognizer is WrapperSwipeGR {
				return pan.velocity(in: gestureRecognizer.view).x.isBeetween(-300, 300)
			}
			return abs(pan.velocity(in: gestureRecognizer.view).y)
			> abs(pan.velocity(in: gestureRecognizer.view).x)
		} else if gestureRecognizer is WrapperSwipeGR {
			if otherGestureRecognizer is WrapperPanGR {
				return false
			} else if let pan = otherGestureRecognizer as? UIPanGestureRecognizer {
				return abs(pan.velocity(in: gestureRecognizer.view).y)
				< abs(pan.velocity(in: gestureRecognizer.view).x)
			}
		}
		if otherGestureRecognizer is WrapperSwipeGR {
			return false
		}
		return true
	}
	
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if let pan = gestureRecognizer as? WrapperPanGR {
			return abs(pan.velocity(in: gestureRecognizer.view).y)
			< abs(pan.velocity(in: gestureRecognizer.view).x)
		}
		if gestureRecognizer is WrapperSwipeGR {
			return pan.velocity(in: pan.view).x.isOutside(-400, 400)
		}
		return true
	}
}
