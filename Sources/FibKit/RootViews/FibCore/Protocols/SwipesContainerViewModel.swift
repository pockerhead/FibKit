//
//  SwipesContainerViewModel.swift
//  
//
//  Created by Денис Садаков on 23.08.2023.
//

protocol SwipesContainerViewModel {
	var mainSwipeView: FibSwipeViewModel { get set }
	var secondSwipeView: FibSwipeViewModel? { get set }
	var thridSwipeView: FibSwipeViewModel? { get set }
	var stretchEmitMainAction: Bool  { get set }
	var edge: Edge  { get set }
}

enum Edge {
	case left
	case right
}

open class SwipesContainerViewModelImpl: SwipesContainerViewModel {
	
	init(mainSwipeView: FibSwipeViewModel, secondSwipeView: FibSwipeViewModel? = nil, thridSwipeView: FibSwipeViewModel? = nil, stretchEmitMainAction: Bool = false, edge: Edge = .left) {
		self.mainSwipeView = mainSwipeView
		self.secondSwipeView = secondSwipeView
		self.thridSwipeView = thridSwipeView
		self.stretchEmitMainAction = stretchEmitMainAction
		self.edge = edge
	}
	
	var mainSwipeView: FibSwipeViewModel
	var secondSwipeView: FibSwipeViewModel?
	var thridSwipeView: FibSwipeViewModel?
	var stretchEmitMainAction: Bool
	var edge: Edge
	
	
}
