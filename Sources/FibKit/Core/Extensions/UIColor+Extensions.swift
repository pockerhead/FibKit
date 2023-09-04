//
//  File.swift
//  
//
//  Created by Денис Садаков on 04.09.2023.
//

import UIKit

extension UIColor {
	
	
	static func withStyle(light: UIColor, dark: UIColor) -> UIColor {
		return UIColor { trait in
			switch UIScreen.main.traitCollection.userInterfaceStyle {
				case .light: return light
				case .dark: return dark
				default: return light
			}
		}
	}
	
	public static var tooltipTextColor: UIColor = .withStyle(
		light: #colorLiteral(red: 0.92941177, green: 0.9411765, blue: 1.0, alpha: 1.0),
		dark: #colorLiteral(red: 0.15294118, green: 0.16078432, blue: 0.21176471, alpha: 1.0)
	)
	
	public static var tooltipBackgroundColor: UIColor = .withStyle(
		light: #colorLiteral(red: 0.3529412, green: 0.3529412, blue: 0.3529412, alpha: 1.0),
		dark: #colorLiteral(red: 0.77254903, green: 0.77254903, blue: 0.77254903, alpha: 1.0)
	)
}


