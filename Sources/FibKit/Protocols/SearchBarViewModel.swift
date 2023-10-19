//
//  SearchBarViewModel.swift
//
//
//  Created by Артём Балашов on 19.10.2023.
//

import UIKit

public protocol SearchBarViewModel {
	
	func onSearchBegin(_ closure: ((UISearchBar?) -> Void)?) -> Self
	func onSearchEnd(_ closure: ((UISearchBar?) -> Void)?) -> Self
	func onSearchResults(_ closure: ((String?) -> Void)?) -> Self
	func viewClass() -> SearchBarConfigurable.Type
}

public protocol SearchBarConfigurable: UIView {
	
	func sizeWith(_ data: SearchBarViewModel, targetSize: CGSize) -> CGSize
	func configure(with data: SearchBarViewModel)
}
