//
//  File.swift
//  
//
//  Created by Артём Балашов on 18.07.2023.
//

import SkeletonView
import UIKit

struct SkeletonAppearance {
	
	static var mainGradient: SkeletonGradient = .init(baseColor: UIColor.secondarySystemBackground)
}

extension SkeletonGradient {
	static var mainGradient: SkeletonGradient {
		SkeletonAppearance.mainGradient
	}
}
