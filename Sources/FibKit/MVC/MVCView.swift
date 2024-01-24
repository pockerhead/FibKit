//
//  File.swift
//  
//
//  Created by Артём Балашов on 24.01.2024.
//

import UIKit

open class MVCView<C: FibViewController>: FibControllerRootView {
	
	public weak var controllerRef: C? {
		self.controller as? C
	}
}
