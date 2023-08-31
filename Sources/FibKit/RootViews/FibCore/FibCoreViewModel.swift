//
//  FibCoreViewModel.swift
//  SmartStaff
//
//  Created by Артём Балашов on 05.07.2021.
//  Copyright © 2021 DIT. All rights reserved.
//

import CoreGraphics
import SwiftUI

open class FibCoreViewModel: ViewModelWithViewClass, FibViewHeaderViewModel {
    
    private(set) open var id: String?
    private(set) public var atTop: Bool = false
    private(set) open var sizeHash: String?
    public var userInfo: [AnyHashable : Any]?
    private(set) public var minHeight: CGFloat?
    private(set) public var maxHeight: CGFloat?
    private(set) public var allowedStretchDirections: Set<StretchDirection> = []
	private(set) public var rightSwipeViews: SwipesContainerView.ViewModel?
    private(set) public var leftSwipeViews: SwipesContainerView.ViewModel?
    private(set) public var interactive: Bool = false
    private(set) public var highlight: HighLight = .squeeze
    private(set) public var onAppearClosure: ((UIView) -> Void)?
    private(set) public var onDissappearClosure: ((UIView) -> Void)?
    private(set) public var size: Size? = nil
    private(set) public var contextMenu: FibContextMenu?
    private(set) public var tooltip: Tooltip?
    public private(set) var separator: ViewModelWithViewClass?
    public private(set) var dragItemsProvider: (() -> [UIDragItem])?
    public private(set) var onTap: ((UIView) -> Void)?
    public private(set) var dropDelegate: UIDropInteractionDelegate?
    public var getSizeClosure: ((CGSize) -> Void)?
    public private(set) var longPressContext: LongTapContext?
	public private(set) var corneredOnSwipe = true
	private (set) public var onAnalyticsTap: ((String) -> Void)?
	public var transform: CGAffineTransform?
	
	public init() {}
    
    public struct Tooltip {
		
		public enum TooltipType {
			case text(text: String)
			case custom(view: TooltipViewModel)
		}
        var needShow: Bool
		var tooltipType: TooltipType
		var markerView: ViewModelConfigurable

		public init(needShow: Bool, tooltipType: TooltipType, markerView: ViewModelConfigurable? = TriangleView()) {
			self.needShow = needShow
			self.tooltipType = tooltipType
			self.markerView = markerView ?? TriangleView()
		}
		
		public init(needShow: Bool, text: String) {
			self.needShow = needShow
			self.tooltipType = .text(text: text)
			self.markerView = TriangleView()
		}
    }

    open func viewClass() -> ViewModelConfigurable.Type {
        #if DEBUG
        assert(false, "MUST BE OVERRIDDEN")
        #endif
        return FibCoreView.self
    }
    
    /// ID вьюхи, если не проставить, то выставится UUID + index вьюхи
    /// - Parameter id: ID
    /// - Returns: self
	open func id(_ id: String) -> Self {
		self.id = id
        return self
    }
    
    /// Если вьюха выступает в роли хедера FibRootView то указывает, z-положение в иерархии
    /// - Parameter atTop: индикатор z-положения true - вьюха наверху иерархии, false - вьюха под FibGrid
    /// - Returns: self
    public func atTop(_ atTop: Bool) -> Self {
        self.atTop = atTop
        return self
    }
    
    open func sizeHash(_ sizeHash: String) -> Self {
        self.sizeHash = sizeHash
        return self
    }
    
    public func userInfo(_ userInfo: [AnyHashable: Any]) -> Self {
        if self.userInfo == nil {
            self.userInfo = userInfo
        } else {
            self.userInfo = self.userInfo?
                .merging(userInfo, uniquingKeysWith: { old, new in new })
        }
        return self
    }
    
    public func minHeight(_ height: CGFloat) -> Self {
        self.minHeight = height
        return self
    }
    
    public func maxHeight(_ height: CGFloat) -> Self {
        self.maxHeight = height
        return self
    }
    
    public func allowedStretchDirections(_ allowedStretchDirections: Set<StretchDirection>) -> Self {
        self.allowedStretchDirections = allowedStretchDirections
        return self
    }
    
	public func rightSwipeViews(mainSwipeView: FibSwipeViewModel,
                                secondSwipeView: FibSwipeViewModel? = nil,
                                thirdSwipeView: FibSwipeViewModel? = nil,
                                stretchEmitMainAction: Bool = true) -> Self {
		self.rightSwipeViews = .init(mainSwipeView: mainSwipeView,
									secondSwipeView: secondSwipeView,
									thridSwipeView: thirdSwipeView,
									stretchEmitMainAction: stretchEmitMainAction,
									edge: .right)
        return self
    }
    
    public func leftSwipeViews(mainSwipeView: FibSwipeViewModel,
                               secondSwipeView: FibSwipeViewModel? = nil,
                               thirdSwipeView: FibSwipeViewModel? = nil,
                               stretchEmitMainAction: Bool = true) -> Self {
		self.leftSwipeViews = .init(mainSwipeView: mainSwipeView,
									secondSwipeView: secondSwipeView,
									thridSwipeView: thirdSwipeView,
									stretchEmitMainAction: stretchEmitMainAction,
									edge: .left)
        return self
    }
    
    /// См. енум HighLight
    /// - Parameter highlight: HighLight
    /// - Returns: self
    public func highlight(_ highlight: HighLight = .squeeze) -> Self {
        self.highlight = highlight
        return self
    }
    
    /// Определяет действия для контекст меню UIKit
    /// - Parameter menu: FibContextMenu
    /// - Returns: self
    public func contextMenu(_ menu: FibContextMenu) -> Self {
        self.contextMenu = menu
        return self
    }
    
	public func fibContextMenu(_ menu: ContextMenu?) -> Self {
		guard let menu = menu else {
			return self
		}
		return self.onLongTap(
			.init(
				longTapDuration: 0.4,
				longTapStarted: ({ gesture, view in
					PopoverService.showContextMenu(
						menu,
						view: view,
						needBlurBackground: menu.needBlurBackground,
						gesture: gesture
					)
				}),
				longTapEnded: ({ gesture, view in
				})
			)
		)
	}
    /// Определяет модель для разделителя ячейки
    /// - Parameter separator: ViewModelWithViewClass
    /// - Returns: self
    public func separator(_ separator: ViewModelWithViewClass?) -> Self {
        self.separator = separator
        return self
    }
    
    /// Определяет провайдер для айтемов DragInteraction
    /// - Parameter itemsProvider: (() -> [UIDragItem]))
    /// - Returns: self
    public func onDrag(_ itemsProvider: (() -> [UIDragItem])?) -> Self {
        self.dragItemsProvider = itemsProvider
        return self
    }
    
    /// Определяет делегат для DropInteraction
    /// - Parameter delegate: UIDropInteractionDelegate?
    /// - Returns: self
    public func onDrop(with delegate: UIDropInteractionDelegate?) -> Self {
        self.dropDelegate = delegate
        return self
    }
    
    public func tooltip(_ tooltip: Tooltip) -> Self {
        self.tooltip = tooltip
        return self
    }
    
    /// Определяет кложур для TapAction
    /// - Parameter onTap: (() -> Void))
    /// - Returns: self
    public func onTap(_ onTap: ((UIView) -> Void)?) -> Self {
        self.onTap = onTap
        return self
    }
    
    /// Определяет контекст для LongTapAction
    /// - Parameter longTapDuration: TimeInterval = 3,
    /// - Parameter longTapStarted: ((FibCoreView) -> Void)?
    /// - Parameter longTapEnded: ((FibCoreView) -> Void)?)
    /// - Returns: self
    public func onLongTap(_ context: LongTapContext) -> Self {
        self.longPressContext = context
        return self
    }
    
    /// Указывает, нужна ли интеракция с вьюхой, если указана false то highlight не вызывается
    /// - Parameter int: interaction
    /// - Returns: self
    public func interactive(_ int: Bool) -> Self {
        self.interactive = int
        return self
    }
    
    /// closure that calls when view appears on screen
    /// - Parameter onAppear: closure that calls when view appears on screen
    /// - Returns: SwiftUIWrapper
    public func onAppear(_ onAppear: ((UIView) -> Void)?) -> Self {
        self.onAppearClosure = onAppear
        return self
    }
    
    /// closure that calls when view dissappears off the screen
    /// - Parameter onAppear: closure that calls when view dissappears off the screen
    /// - Returns: SwiftUIWrapper
    public func onDissappear(_ onDissappear: ((UIView) -> Void)?) -> Self {
        self.onDissappearClosure = onDissappear
        return self
    }
	
	public func onAnalyticsTap(_ onAnalyticsTap: ((String) -> Void)?) -> Self {
		self.onAnalyticsTap = onAnalyticsTap
		return self
	}
    
    /// - Parameter size: Nested size, see docs of it
    /// - Returns: FibCoreViewModel
    public func sizeStrategy(_ size: Size) -> Self {
        self.size = size
        return self
    }
    
    /// Closure that updates where sizeWith func called and return actual height of view
    /// - Parameter closure: Closure that updates where sizeWith func called and return actual height of view
    /// - Returns: Self
    public func getSize(_ closure: ((CGSize) -> Void)?) -> Self {
        self.getSizeClosure = closure
        return self
    }
	
	/// Определяет матрицу преобразований для вью
	/// - Parameter transform: CGAffineTransform
	/// - Returns: self
	public func transform(_ transform: CGAffineTransform) -> Self {
		self.transform = transform
		return self
	}
	
	/// Нужно ли скругление при свайпе
	/// - Parameter corneredOnSwipe: Bool
	/// - Returns: self
	@discardableResult
	public func corneredOnSwipe(_ corneredOnSwipe: Bool) -> Self {
		self.corneredOnSwipe = corneredOnSwipe
		return self
	}
	
    public struct LongTapContext {
        public private(set) var longTapDuration: TimeInterval = 0.6
        public private(set) var longTapStarted: ((UIGestureRecognizer, FibCoreView) -> Void)?
        public private(set) var longTapEnded: ((UIGestureRecognizer, FibCoreView) -> Void)?
    }
    
    public struct Menu {
        var actions: [PopoverServiceInstance.Action]
        var needBlurBackground: Bool = true
    }
    
    /// Енум для описания интеракции с вьюхой
    public enum HighLight {
        /// сжатие вьюхи
        case squeeze
        /// изменение фонового цвета с фэйдом (10%) в цвет текста для данной темы
        case coloredBackground
        /// изменение фонового цвета с фэйдом в указанный цвет
        case coloredCustomBackground(color: UIColor)
        /// кастомная интеракция, принимает признак интеракции и вьюху
        case custom(closure: (FibCoreView, Bool) -> Void)
		
		public static var card: HighLight {
			.custom(closure: { view, highlighted in
				guard view.isUserInteractionEnabled else { return }
				view.highlightSqueeze(highlighted: highlighted)
				UIView.animate(withDuration: highlighted ? view.squeezeDownDuration : view.squeezeUpDuration) {
					if highlighted {
						view.contentView.layer.applySketchHighlightedShadow()
					} else {
						view.contentView.layer.applySketchShadow()
					}
				}
			})
		}
    }
    
    /// DTO struct to define size of SwiftUIWrapper
    public struct Size {

		public var width: Strategy = .inherit
		public var height: Strategy = .inherit
        
        public static func height(_ height: FibCoreViewModel.Size.Strategy) -> Size {
            .init(height: height)
        }
        
        public static func width(_ width: FibCoreViewModel.Size.Strategy) -> Size {
            .init(width: width)
        }
        
        /// DTO struct to define size of SwiftUIWrapper
        /// - Parameters:
        ///   - width: Layout strategy for width, enum, see doc of SwiftUIWrapper.Size.Strategy
        ///   - height: Layout strategy form height, enum, see doc of SwiftUIWrapper.Size.Strategy
		public init(width: FibCoreViewModel.Size.Strategy = .inherit,
                    height: FibCoreViewModel.Size.Strategy = .inherit) {
            self.width = width
            self.height = height
        }
		
		public static func width(_ width: FibCoreViewModel.Size.Strategy, height: FibCoreViewModel.Size.Strategy) -> Size {
			return .init(width: width, height: height)
		}
		
		public static func both(_ strategy: FibCoreViewModel.Size.Strategy) -> Size {
			return .init(width: strategy, height: strategy)
		}
        
        /// Layout strategy
        public enum Strategy: Equatable {
            
            /// Inherits dimension from FibKit layout manager
            case inherit
            /// Layouts dimension to instrinsic size
            case selfSized
            /// Absolute value in CGFloat
            case absolute(CGFloat)
            /// lessThan value
            case lessThan(CGFloat)
            /// greaterThan value
            case greaterThan(CGFloat)
            
            public func assignStrategy(to dimension: CGFloat, targetDimension: CGFloat) -> CGFloat {
                switch self {
                case .inherit:
                    return targetDimension
                case .selfSized:
                    return dimension
                case .absolute(let val):
                    return val
                case .greaterThan(let val):
                    return max(dimension, val)
                case .lessThan(let val):
                    return min(dimension, val)
                }
            }
        }
        
        public func assignSize(selfSized size: CGSize, targetSize: CGSize) -> CGSize {
            return .init(width: width.assignStrategy(to: size.width,
                                                     targetDimension: targetSize.width),
                         height: height.assignStrategy(to: size.height,
                                                       targetDimension: targetSize.height))
        }
    }
}
