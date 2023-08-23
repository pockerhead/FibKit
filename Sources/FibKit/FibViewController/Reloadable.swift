//
//  Reloadable.swift
//  
//
//  Created by Артём Балашов on 06.08.2023.
//

import Foundation
import Combine

protocol HaveControllerProp: AnyObject {
	var controller: FibViewController? { get set }
}

@propertyWrapper
public class Reloadable<Value>: HaveControllerProp {
	
	weak var controller: FibViewController?
	private var stored: Value
	public var wrappedValue: Value {
		get { stored }
		set {
			stored = newValue
			guard let controller = controller else { return }
			controller.reload()
		}
	}
	
	public init(wrappedValue stored: Value) {
		self.stored = stored
	}
}

@propertyWrapper
public class ReloadableObject<Value: ObservableObject>: HaveControllerProp {
	
	weak var controller: FibViewController?
	private var stored: Value
	private var cancellable: Set<AnyCancellable> = []
	
	public var wrappedValue: Value {
		get { stored }
		set {
			stored = newValue
			guard let controller = controller else { return }
			controller.reload()
		}
	}
	
	public init(wrappedValue stored: Value) {
		self.stored = stored
		stored.objectWillChange.sink { [weak self] _ in
			self?.controller?.reload()
		}.store(in: &cancellable)
	}
}

@propertyWrapper
public class StateReloadable<Value: Equatable>: HaveControllerProp {
	
	weak var controller: FibViewController?
	private var stored: Value
	public var wrappedValue: Value {
		get { stored }
		set {
			guard newValue != stored else { return }
			stored = newValue
			guard let controller = controller else { return }
			controller.reload()
		}
	}
	
	public init(wrappedValue stored: Value) {
		self.stored = stored
	}
}
