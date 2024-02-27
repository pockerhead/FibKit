//
//  Reloadable.swift
//  
//
//  Created by Артём Балашов on 06.08.2023.
//

import Foundation
import Combine

protocol HaveReloaderProp: AnyObject {
	var reloader: (() -> Void)? { get set }
}

@propertyWrapper
public class Reloadable<Value>: HaveReloaderProp {
	
	var reloader: (() -> Void)?
	private var stored: Value
	public var wrappedValue: Value {
		get { stored }
		set {
			stored = newValue
			reloader?()
		}
	}
	
	public func setReloader(_ reloader: (() -> Void)?) {
		self.reloader = reloader
	}
	
	public init(wrappedValue stored: Value, reloader: (() -> Void)? = nil) {
		self.stored = stored
		self.reloader = reloader
	}
}

@propertyWrapper
public class ReloadableObject<Value: ObservableObject>: HaveReloaderProp {
	
	var reloader: (() -> Void)?
	private var stored: Value
	private var cancellable: Set<AnyCancellable> = []
	
	public var wrappedValue: Value {
		get { stored }
		set {
			stored = newValue
			reloader?()
		}
	}
	
	public func setReloader(_ reloader: (() -> Void)?) {
		self.reloader = reloader
	}
	
	public init(wrappedValue stored: Value, reloader: (() -> Void)? = nil) {
		self.stored = stored
		self.reloader = reloader
		stored.objectWillChange.sink { [weak self] _ in
			self?.reloader?()
		}.store(in: &cancellable)
	}
}

@propertyWrapper
public class LazyReloadable<Value: Equatable>: HaveReloaderProp {
	
	var reloader: (() -> Void)?
	private var stored: Value
	public var wrappedValue: Value {
		get { stored }
		set {
			guard newValue != stored else { return }
			stored = newValue
			reloader?()
		}
	}
	
	public func setReloader(_ reloader: (() -> Void)?) {
		self.reloader = reloader
	}
	
	public init(wrappedValue stored: Value, reloader: (() -> Void)? = nil) {
		self.stored = stored
		self.reloader = reloader
	}
}
