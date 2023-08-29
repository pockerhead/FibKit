//
//  FibSwipeViewModel.swift
//  
//
//  Created by Денис Садаков on 23.08.2023.
//

import Foundation


public protocol FibSwipeView: ViewModelConfigurable {
	var swipeEdge: SwipesContainerView.Edge? { get set }
}

public protocol FibSwipeViewModel: ViewModelWithViewClass {
	var title: String? { get set }
	var secondGradientColor: UIColor? { get set }
	var action: (() -> Void)? { get set }
	var image: UIImage? { get set }
	var backgroundColor: UIColor { get set }
}
