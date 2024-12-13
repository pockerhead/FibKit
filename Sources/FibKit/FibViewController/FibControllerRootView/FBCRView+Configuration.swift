//
//  FBCRView+Configuration.swift
//  
//
//  Created by Артём Балашов on 18.10.2023.
//

import UIKit

public extension FibControllerRootView {
	
	public enum Shutter {
		case rounded
		case `default`
	}
	
	public enum TopInsetStrategy {
		case safeArea
		case statusBar
		case top
		case custom(@autoclosure (() -> CGFloat))
		
		func getTopInset(for view: UIView) -> CGFloat {
			switch self {
			case .safeArea:
				return view.safeAreaInsets.top
			case .statusBar:
				return view.statusBarFrame?.height ?? 0
			case .top:
				return 0
			case .custom(let margin):
				return margin()
			}
		}
	}
	
	public class NavigationConfiguration {
		
        public class SearchContext {

            public class SearchBarAppearance {
                public init(
                    font: UIFont? = nil,
                    searchIcon: UIImage? = nil,
                    textColor: UIColor? = nil
                ) {
                    self.font = font
                    self.searchIcon = searchIcon
                    self.textColor = textColor
                }
                
                public var font: UIFont?
                public var searchIcon: UIImage?
                public var textColor: UIColor?
            }

            public init(
                isForceActive: Bool? = nil,
                placeholder: String = "Search...",
                hideWhenScrolling: Bool = false,
                onSearchResults: ((String?) -> Void)? = nil,
                onSearchBegin: ((UISearchBar?) -> Void)? = nil,
                onSearchEnd: ((UISearchBar?) -> Void)? = nil,
                onSearchButtonClicked: ((UISearchBar?) -> Void)? = nil,
                searchBarAppearance: SearchBarAppearance? = nil
            ) {
                self.isForceActive = isForceActive
                self.hideWhenScrolling = hideWhenScrolling
                self.onSearchResults = onSearchResults
                self.placeholder = placeholder
                self.onSearchBegin = onSearchBegin
                self.onSearchEnd = onSearchEnd
                self.onSearchButtonClicked = onSearchButtonClicked
                self.searchBarAppearance = searchBarAppearance
            }

            public var isForceActive: Bool? = nil
            public var hideWhenScrolling: Bool = false
            public var placeholder: String = "Search..."
            public var onSearchResults: ((String?) -> Void)?
            public var onSearchBegin: ((UISearchBar?) -> Void)?
            public var onSearchEnd: ((UISearchBar?) -> Void)?
            public var onSearchButtonClicked: ((UISearchBar?) -> Void)?

            public var searchBarAppearance: SearchBarAppearance?
        }

        public init(
            titleViewModel: ViewModelWithViewClass? = nil,
            largeTitleViewModel: ViewModelWithViewClass? = nil,
            searchContext: FibControllerRootView.NavigationConfiguration.SearchContext? = nil
        ) {
            self.titleViewModel = titleViewModel
            self.largeTitleViewModel = largeTitleViewModel
            self.searchContext = searchContext
        }

        public var titleViewModel: ViewModelWithViewClass? = nil
        public var largeTitleViewModel: ViewModelWithViewClass? = nil
        public var searchContext: SearchContext? = nil
    }
	
	public class Configuration {
		public init(
			roundedShutterBackground: UIColor? = nil,
			shutterBackground: UIColor? = nil,
			viewBackgroundColor: UIColor? = nil,
			shutterType: FibControllerRootView.Shutter? = nil,
			backgroundView: (() -> UIView?)? = nil,
			backgroundViewInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
			shutterShadowClosure: ((ShutterView) -> Void)? = nil,
			topInsetStrategy: TopInsetStrategy? = nil,
			headerBackgroundViewColor: UIColor? = nil,
			headerBackgroundEffectView: (() -> UIView?)? = nil,
			needFooterKeyboardSticks: Bool = false,
			footerBackgroundViewColor: UIColor? = nil
		) {
			self.roundedShutterBackground = roundedShutterBackground
			self.shutterBackground = shutterBackground
			self.viewBackgroundColor = viewBackgroundColor
			self.shutterType = shutterType
			self.needFooterKeyboardSticks = needFooterKeyboardSticks
			self.backgroundView = backgroundView
			self.backgroundViewInsets = backgroundViewInsets
			self.shutterShadowClosure = shutterShadowClosure
			self.topInsetStrategy = topInsetStrategy
			self.headerBackgroundViewColor = headerBackgroundViewColor
			self.headerBackgroundEffectView = headerBackgroundEffectView
			self.footerBackgroundViewColor = footerBackgroundViewColor
		}
		
		public var needFooterKeyboardSticks: Bool
		public var roundedShutterBackground: UIColor?
		public var shutterBackground: UIColor?
		public var viewBackgroundColor: UIColor?
		public var headerBackgroundViewColor: UIColor?
		public var headerBackgroundEffectView: (() -> UIView?)?
		public var shutterShadowClosure: ((ShutterView) -> Void)?
		public var shutterType: Shutter?
		public var backgroundView: (() -> UIView?)?
		public var backgroundViewInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		public var topInsetStrategy: TopInsetStrategy?
		public var footerBackgroundViewColor: UIColor?
	}
}
