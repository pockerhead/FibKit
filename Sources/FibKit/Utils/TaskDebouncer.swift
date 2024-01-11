//
//  File.swift
//  
//
//  Created by Артём Балашов on 11.01.2024.
//

import Foundation

final public class TaskDebouncer {
	
	private(set) var task: (() -> Void)?
	private(set) var workItem: DispatchWorkItem?
	private(set) var delayType: DelayType
	
	public enum DelayType {
		case timeInterval(TimeInterval)
		case cyclesCount(Int)
	}
	
	public init(delayType: DelayType, task: (() -> Void)? = nil) {
		self.delayType = delayType
		self.task = task
	}
	
	public func runDebouncedTask(task: (() -> Void)? = nil) {
		var stackTask: (() -> Void)?
		if let task = task {
			stackTask = task
		} else if let task = self.task {
			stackTask = task
		} else {
			return
		}
		workItem?.cancel()
		workItem = nil
		let stackItem = DispatchWorkItem.init(block: stackTask!)
		workItem = stackItem
		switch delayType {
		case .timeInterval(let timeInterval):
			delay(timeInterval) {[weak stackItem] in
				guard let stackItem, stackItem.isCancelled == false else { return }
				stackItem.perform()
			}
		case .cyclesCount(let int):
			delay(cyclesCount: int) {[weak stackItem] in
				guard let stackItem, stackItem.isCancelled == false else { return }
				stackItem.perform()
			}
		}
	}
	
	public func runTaskImmediately() {
		workItem?.cancel()
		workItem = nil
		workItem = .init(block: {[weak self] in
			self?.task?()
		})
		workItem?.perform()
	}
	
	public func setDelayType(to delayType: DelayType) {
		self.delayType = delayType
	}
	
	public func setTask(task: @escaping (() -> Void)) {
		self.task = task
	}
	
	private func delay(_ delay: Double, closure:@escaping () -> Void) {
		DispatchQueue.main.asyncAfter(
			deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
	}

	private func delay(cyclesCount: Int = 1, closure:@escaping () -> Void) {
		if cyclesCount == 0 {
			closure()
		} else {
			DispatchQueue.main.async {[weak self] in
				self?.delay(cyclesCount: cyclesCount - 1, closure: closure)
			}
		}
	}
}
