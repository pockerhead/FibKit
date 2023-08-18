//
//  FibGrid + SwiftUI.swift
//  
//
//  Created by Денис Садаков on 17.08.2023.
//

import SwiftUI
import Combine

extension FibGrid: UIViewRepresentable {
	
	public func addingScrollToIndexPublisher(_ scrollToIndexPub: PassthroughSubject<IndexPath, Never>) -> FibGrid {
		return FibGrid(provider: self.provider, scrollToIndexPub: scrollToIndexPub)
	}
	
	public func hideScrollIndicators(horizontal: Bool = false,
									 vertical: Bool = false) {
		hidingScrollIndicators = (horizontal, vertical)
		self.showsVerticalScrollIndicator = !vertical
		self.showsHorizontalScrollIndicator = !horizontal
	}
	
	public func hidingScrollIndicators(horizontal: Bool = false,
									   vertical: Bool = false) -> FibGrid {
		return FibGrid(provider: self.provider,
					   scrollToIndexPub: scrollToIndexPub,
					   horizontal: horizontal,
					   vertical: vertical)
	}
	
	public func makeUIView(context: Context) -> FibGrid {
		swiftUIUIView = self
		scrollToIndexPub?.sink(receiveValue: {[weak swiftUIUIView] indexPath in
			delay {
				_ = try? swiftUIUIView?.scroll(to: indexPath, animated: true, considerNearbyItems: true)
			}
		})
		.store(in: &cancellables)
		
		swiftUIUIView?.showsVerticalScrollIndicator = !hidingScrollIndicators.vertical
		swiftUIUIView?.showsHorizontalScrollIndicator = !hidingScrollIndicators.horizontal
		return swiftUIUIView!
	}
	
	public func updateUIView(_ uiView: FibGrid, context: Context) {
		swiftUIUIView = uiView
		uiView.provider = provider
		scrollToIndexPub?.sink(receiveValue: {[weak uiView] indexPath in
			delay {
				_ = try? uiView?.scroll(to: indexPath, animated: true, considerNearbyItems: true)
			}
		})
		.store(in: &cancellables)
		uiView.showsVerticalScrollIndicator = !(hidingScrollIndicators.vertical)
		uiView.showsHorizontalScrollIndicator = !(hidingScrollIndicators.horizontal)
	}
}
