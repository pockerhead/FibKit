//
//  File.swift
//  
//
//  Created by Денис Садаков on 05.09.2023.
//

import Foundation

extension CGRect {
	
	mutating func setCenterOrigin(to rect: CGRect) {
		origin = getCenteringOrigin(to: rect)
	}
	
	mutating func setCenterY(to rect: CGRect) {
		origin.y = getCenteringY(to: rect)
	}
	
	mutating func setCenterX(to rect: CGRect) {
		origin.x = getCenteringX(to: rect)
	}
	
	func getCenteringOrigin(to rect: CGRect) -> CGPoint {
		return .init(x: getCenteringX(to: rect),
					 y: getCenteringY(to: rect))
	}
	
	func getCenteringX(to rect: CGRect) -> CGFloat {
		rect.origin.x + rect.width / 2 - width / 2
	}
	
	func getCenteringY(to rect: CGRect) -> CGFloat {
		rect.origin.y + rect.height / 2 - height / 2
	}
}
