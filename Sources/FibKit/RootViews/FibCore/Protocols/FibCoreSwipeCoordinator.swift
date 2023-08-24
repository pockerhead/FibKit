//
//  FibCoreSwipeCoordinator.swift
//  
//
//  Created by Денис Садаков on 23.08.2023.
//

import Foundation

protocol FibCoreSwipeCoordinator {
	var haveSwipeAction: Bool { get set }
	var isSwipeOpen: Bool { get set }
	init(fibCoreView: FibCoreView)
	func configure(with viewModel: FibCoreViewModel)
	func prepareForReuse()
	func animateSwipe(direction: SwipeType,
					  isOpen: Bool,
					  swipeWidth: CGFloat?,
					  initialVel: CGFloat?,
					  completion: (() -> Void)?)
}

class FibCoreSwipeCoordinatorImpl: FibCoreSwipeCoordinator {
	var haveSwipeAction: Bool = false
	var isSwipeOpen: Bool = false
	weak var view: FibCoreView?
	
	required init(fibCoreView: FibCoreView) {
		self.view = fibCoreView
	}
	
	func configure(with viewModel: FibCoreViewModel) {}
	func prepareForReuse() {}
	func animateSwipe(direction: SwipeType = .right,
					  isOpen: Bool,
					  swipeWidth: CGFloat?,
					  initialVel: CGFloat? = nil,
					  completion: (() -> Void)? = nil) {}
	
	
}
