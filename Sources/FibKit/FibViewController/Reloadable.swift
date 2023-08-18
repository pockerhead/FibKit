//
//  Reloadable.swift
//  
//
//  Created by Артём Балашов on 06.08.2023.
//

import Foundation

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
