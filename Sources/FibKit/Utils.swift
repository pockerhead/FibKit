//
//  Utils.swift
//  FibKit
//
//  Created by Egor Dadugin on 27.06.2023.
//  Copyright © 2023 DIT Moscow. All rights reserved.
//

import DITLogger
import Foundation

internal func delay(_ delay: Double, closure:@escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

internal func delay(cyclesCount: Int = 1, closure:@escaping () -> Void) {
    if cyclesCount == 0 {
        closure()
    } else {
        DispatchQueue.main.async {
            delay(cyclesCount: cyclesCount - 1, closure: closure)
        }
    }
}

internal func mainOrSync<T>(_ closure: @escaping (() throws -> T)) rethrows -> T {
    if Thread.isMainThread {
        return try closure()
    } else {
        return try DispatchQueue.main.sync {
            return try closure()
        }
    }
}

internal func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

internal prefix func - (inset: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: -inset.top, left: -inset.left, bottom: -inset.bottom, right: -inset.right)
}

internal func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

internal func + (left: CGRect, right: CGPoint) -> CGRect {
    return CGRect(origin: left.origin + right, size: left.size)
}

internal func += (left: inout CGPoint, right: CGPoint) {
    left.x += right.x
    left.y += right.y
}

internal func mainOrAsync(_ closure: @escaping (() -> Void)) {
	if Thread.isMainThread {
		closure()
	} else {
		DispatchQueue.main.async {
			closure()
		}
	}
}

internal func backgroundCurrentOrAsync(on: DispatchQueue, _ closure: @escaping (() -> Void)) {
	if Thread.isMainThread {
		on.async {
			closure()
		}
	} else {
		closure()
	}
}

internal func delay(_ delay: Double, workItem: DispatchWorkItem) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: workItem)
}

internal func printCodeExecutionTime(comment: String = "Block", closure: (() -> Void)?) {
	#if DEBUG
	let start = DispatchTime.now()
	closure?()
	let end = DispatchTime.now()

	let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
	let timeInterval = Double(nanoTime) / 1_000_000_000
	log.warning("[The execution of \(comment) is \(timeInterval)]")
	#endif
}

internal extension Comparable {

	func isBeetween(_ lhs: Self, _ rhs: Self) -> Bool {
		self >= lhs && self <= rhs
	}
}

internal extension Comparable {

	func isOutside(_ lhs: Self, _ rhs: Self) -> Bool {
		self <= lhs || self >= rhs
	}
}
