//
//  FibGrid + Guard.swift
//  
//
//  Created by Денис Садаков on 18.08.2023.
//

import Foundation

extension FibGrid {
	
	@available(*, message: "Use native if")
	public static func `if`(_ condition: Bool,
							@SectionBuilder append sections: () -> [GridSection],
							@SectionBuilder elseAppend elseSections: () -> [GridSection] = {[]})
	-> [GridSection] {
		if condition {
			return sections()
		} else {
			return elseSections()
		}
	}
	
	public static func `guard`(_ condition: Bool,
							   @SectionBuilder elseReturn sections: () -> [GridSection])
	-> [GridSection] {
		if !condition {
			let s = sections()
			s.forEach({ $0.isGuard = true })
			return s
		} else {
			return []
		}
	}
	
	public static func `guard`(_ condition: Bool,
							   @SectionBuilder elseAppend sections: () -> [GridSection])
	-> [GridSection] {
		if !condition {
			let s = sections()
			s.forEach({ $0.isGuardAppend = true })
			return s
		} else {
			return []
		}
	}
	
}
