//
//  Reloadable.swift
//  
//
//  Created by Артём Балашов on 06.08.2023.
//

import Foundation
import Combine

protocol HaveReloaderProp: AnyObject {
	var reloader: Reloader? { get set }
}

public protocol Reloader: AnyObject {
	func reload()
}

@propertyWrapper
public class Reloadable<Value>: HaveReloaderProp {
	
	weak var reloader: Reloader?
	private var stored: Value
	public var wrappedValue: Value {
		get { stored }
		set {
			stored = newValue
			guard let reloadable = reloader else { return }
			reloadable.reload()
		}
	}
	
	public init(reloadable: Reloader? = nil, wrappedValue stored: Value) {
		self.stored = stored
	}
}

@propertyWrapper
public class ReloadableObject<Value: ObservableObject>: HaveReloaderProp {
	
	weak var reloader: Reloader?
	private var stored: Value
	private var cancellable: Set<AnyCancellable> = []
	
	public var wrappedValue: Value {
		get { stored }
		set {
			stored = newValue
			guard let reloadable = reloader else { return }
			reloadable.reload()
		}
	}
	
	public init(reloadable: Reloader? = nil, wrappedValue stored: Value) {
		self.stored = stored
		stored.objectWillChange.sink { [weak self] _ in
			self?.reloader?.reload()
		}.store(in: &cancellable)
	}
}

@propertyWrapper
public class LazyReloadable<Value: Equatable>: HaveReloaderProp {
	
	weak var reloader: Reloader?
	private var stored: Value
	public var wrappedValue: Value {
		get { stored }
		set {
			guard newValue != stored else { return }
			stored = newValue
			guard let reloadable = reloader else { return }
			reloadable.reload()
		}
	}
	
	public init(reloadable: Reloader? = nil, wrappedValue stored: Value) {
		self.stored = stored
	}
}
