//
//  FibGrid.swift
//  SmartStaff
//
//  Created by artem on 26.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


@_exported import UIKit
import SwiftUI
import Combine
import Threading

protocol ClassNameProtocol {
	static var className: String { get }
	var className: String { get }
}

extension ClassNameProtocol {
	
	static var className: String {
		String(describing: self)
	}
	
	var className: String {
		type(of: self).className
	}
}

extension NSObject: ClassNameProtocol {}

extension Layout: ClassNameProtocol {}

public struct WeakRef<T: AnyObject> {
	public weak var ref: T?
	
	public init(ref: T? = nil) {
		self.ref = ref
	}
}

final class GridsReuseManager {
	let serialQueue = DispatchQueue(label: "com.fibKit.GridsReuseManager.serialQueue")
	var layouts = ThreadedDictionary<String, Layout>()
	var sizeSources = ThreadedDictionary<String, FibGridSizeSource>()
	var grids = ThreadedDictionary<String, WeakRef<FibGrid>>([:], type: .serial)
	var dummyViews = ThreadedDictionary<String, UIView>()
	private lazy var timer: Timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {[weak self] _ in
		self?.serialQueue.async {
			guard let self = self else { return }
			self.grids = ThreadedDictionary<String, WeakRef<FibGrid>>.init(
				self.grids.unthreaded.filter({ $0.value.ref != nil }),
				type: .serial
			)
		}
	}
	
	static var shared = GridsReuseManager()
	private init() {
		RunLoop.current.add(timer, forMode: .common)
	}
}

/// ScrollView that lay outs views form declarative descirbed sections
final public class FibGrid: CollectionView {
	
	public weak var swiftUIUIView: FibGrid?
	
	/// optional view that contains formView
	weak var containedRootView: FibControllerRootView?
	
	/// need animated reload
	public var animated: Bool = true
	
	public var isEmbedCollection = false
	/// cached structs that contains cached sizes of cells, needs for optimisation
	
	public override var provider: Provider? {
		didSet {
			if let id = provider?.identifier {
				GridsReuseManager.shared.grids[id] = .init(ref: self)
			}
			if let provider = provider as? SectionStack {
				provider.collectionView = self
				self.scrollDirection = provider.scrollDirection
				provider.bindReload {[weak self] in
					self?.didReloadClosure?()
				}
			}
			if let provider = provider as? GridSection {
				provider.collectionView = self
				self.scrollDirection = provider.scrollDirection
				provider.bindReload {[weak self] in
					self?.didReloadClosure?()
				}
			}
			setNeedsReload()
			reloadSections(oldValue)
		}
	}
	public var isAsync = true
	
	fileprivate var cancellables = Set<AnyCancellable>()
	fileprivate weak var scrollToIndexPub: PassthroughSubject<IndexPath, Never>?
	fileprivate var hidingScrollIndicators: (horizontal: Bool, vertical: Bool) = (false, false)
	/// view that fills view and displayed when sections is empty
	//    var emptyView = DITCore.InfoMessageView()
	
	/// display empty view
	/// - Parameters:
	///   - model: empty view ViewModel
	///   - height: optional height of empty view
	///   - animated: needs animate
	    func displayEmptyView(model: ViewModelWithViewClass, height: CGFloat? = nil, animated: Bool) {
			guard let view = model.getView() else { return }
	        let heightStrategy: SimpleViewSizeSource.ViewSizeStrategy
	        if let height = height {
	            heightStrategy = .offset(height)
	        } else {
	            heightStrategy = .fill
	        }
	        let sizeStrategy = (width: SimpleViewSizeSource.ViewSizeStrategy.fill, height: heightStrategy)
	        provider = SimpleViewProvider(identifier: "emptyViewProvider",
	                                      views: [view],
	                                      sizeStrategy: sizeStrategy,
	                                      layout: FlowLayout(),
	                                      animator: animated ? AnimatedReloadAnimator() : nil)
	    }
	
	/// direction of scroll
	public var scrollDirection: ScrollDirection = .vertical
	
	public enum ScrollDirection {
		case vertical
		case horizontal
		case unlocked
	}
	
	/// closure that called when all sections is reloaded, view layouts and fitted contentSize fully
	private var didReloadClosure: (() -> Void)?
	
	public var overrideRootLayout: Layout?
	
	/// Binds didReload closure
	/// - Parameter didReload: closure that called when all sections is reloaded, view layouts and fitted contentSize fully
	/// - Returns: self
	@discardableResult
	public final func didReload(_ didReload: (() -> Void)?) -> FibGrid {
		self.didReloadClosure = didReload
		return self
	}
	
	private var forcedProviderUpdate: Bool = false
	
	public func setForcedProviderUpdate() {
		forcedProviderUpdate = true
	}
	
	private func reloadSections(_ oldValue: Provider?) {
		//        var newLayout: Layout
		//		if let overrideRootLayout = overrideRootLayout {
		//			newLayout = overrideRootLayout
		//		} else if scrollDirection == .vertical {
		//            newLayout = FlowLayout()
		//        } else {
		//            newLayout = RowLayout()
		//        }
		//
		//        if !forcedProviderUpdate,
		//           let provider = self.provider as? FibGridHeaderProvider {
		//            if animated {
		//                if provider.animator == nil {
		//                    provider.animator = AnimatedReloadAnimator()
		//                }
		//            } else {
		//                if provider.animator != nil {
		//                    provider.animator = nil
		//                }
		//            }
		//            if provider.layout.className != newLayout.className {
		//                provider.layout = newLayout
		//            }
		//            provider.isAsync = isAsync
		//            provider.sections = self.sections
		//        } else {
		//            forcedProviderUpdate = false
		//            let provider = FibGridHeaderProvider(identifier: "RootProvider_\(String(reflecting: self))",
		//                                                 layout: newLayout,
		//                                                 animator: animated ? AnimatedReloadAnimator() : nil,
		//                                                 sections: self.sections,
		//                                                 collectionView: self)
		//                .bindReload({
		//                DispatchQueue.main.async {[weak self] in
		//                    self?.didReloadClosure?()
		//                }
		//            })
		//            if let oldRootSizeSource = (self.provider as? FibGridHeaderProvider)?.headerSizeSource {
		//                provider.headerSizeSource = oldRootSizeSource
		//            }
		//            provider.isSticky = true
		//            provider.isAsync = isAsync
		//            self.provider = provider
		//        }
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		delaysContentTouches = false
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		delaysContentTouches = false
	}
	
	// Проверяем позади формвью наличие интерактивных вьюх, нужно чтобы в режиме
	// шторки (наезд на хедер) можно было обрабатывать нажатия на хедер
	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard FibGridPassthroughHelper.nestedInteractiveViews(in: self, contain: point, convertView: self) else {
			return false
		}
		return super.point(inside: point, with: event)
	}
	
	
}

struct FibGridPassthroughHelper {
	static func nestedInteractiveViews(in view: UIView, contain point: CGPoint, convertView: UIView) -> Bool {
		if let formView = view as? FibGrid,
		   let shutter = formView.containedRootView?.shutterView {
			
			if formView.containedRootView?._headerViewModel?.atTop == true {
				return true
			}
			
			if shutter.bounds.contains(convertView.convert(point, to: shutter)) {
				return true
			}
			
			if view is FibGrid == false, view.isPotentiallyInteractive,
			   view.bounds.contains(convertView.convert(point, to: view)) {
				return true
			}
		} else if view.isPotentiallyInteractive, view.bounds.contains(convertView.convert(point, to: view)) {
			return true
		}
		
		for subview in view.subviews {
			if nestedInteractiveViews(in: subview, contain: point, convertView: convertView) {
				return true
			}
		}
		
		return false
	}
}

extension FibGrid: UIViewRepresentable {
	
	
	public convenience init(provider: Provider?,
							scrollToIndexPub: PassthroughSubject<IndexPath, Never>? = nil,
							horizontal: Bool = false,
							vertical: Bool = false) {
		self.init()
		self.provider = provider
		self.scrollToIndexPub = scrollToIndexPub
		self.hidingScrollIndicators = (horizontal, vertical)
		self.showsVerticalScrollIndicator = !vertical
		self.showsHorizontalScrollIndicator = !horizontal
	}
	
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
				try? swiftUIUIView?.scroll(to: indexPath, animated: true, considerNearbyItems: true)
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
				try? uiView?.scroll(to: indexPath, animated: true, considerNearbyItems: true)
			}
		})
		.store(in: &cancellables)
		uiView.showsVerticalScrollIndicator = !(hidingScrollIndicators.vertical)
		uiView.showsHorizontalScrollIndicator = !(hidingScrollIndicators.horizontal)
	}
}
