//
//  SearchBarDefaultImp.swift
//
//
//  Created by Артём Балашов on 19.10.2023.
//

import UIKit

final class SearchBarDefaultImp: UIView, SearchBarConfigurable {
	
	private let searchBar = UISearchBar()
	
	var onSearchBegin: ((UISearchBar?) -> Void)?
	var onSearchEnd: ((UISearchBar?) -> Void)?
	var onSearchResults: ((String?) -> Void)?
	
	func sizeWith(_ data: SearchBarViewModel, targetSize: CGSize) -> CGSize {
		return .zero
	}
	
	func configure(with data: SearchBarViewModel) {
		
	}
	
	
	struct ViewModel: SearchBarViewModel {
		
		var onSearchBegin: ((UISearchBar?) -> Void)?
		var onSearchEnd: ((UISearchBar?) -> Void)?
		var onSearchResults: ((String?) -> Void)?
		
		func onSearchBegin(_ closure: ((UISearchBar?) -> Void)?) -> Self {
			return self
		}
		
		func onSearchEnd(_ closure: ((UISearchBar?) -> Void)?) -> Self {
			return self
		}
		
		func onSearchResults(_ closure: ((String?) -> Void)?) -> Self {
			return self
		}
		
		func viewClass() -> SearchBarConfigurable.Type {
			SearchBarDefaultImp.self
		}
	}
}
