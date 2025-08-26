//
//  FibGrid + Misc.swift
//  
//
//  Created by Денис Садаков on 18.08.2023.
//

import Foundation
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


extension UIView {
	
	func findViewInSuperViews<T: UIView>() -> T? {
		if superview == nil { return nil }
		if let s = superview as? T {
			return s
		} else if let s: T = superview?.findViewInSuperViews() {
			return s
		} else {
			return nil
		}
	}
}

extension CGSize {
	
	var square: CGFloat {
		width * height
	}
}
public enum FibGridError: Error {
	case unableToScroll
}
