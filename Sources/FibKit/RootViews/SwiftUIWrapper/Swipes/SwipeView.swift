//
//  SwipeView.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import SwiftUI

public struct SwipeView: View, Hashable {
    
    init(isFirst: Bool = false,
         action: @escaping (() -> Void),
         title: String? = nil,
         icon: UIImage? = nil,
         width: CGFloat? = nil,
         background: UIColor,
         secondBackground: UIColor?) {
        self.isFirst = isFirst
        self.action = action
        self.title = title
        self.icon = icon
        self.width = width
        self.background = background
        self.secondBackground = secondBackground ?? background.fade(toColor: .black, withPercentage: 0.25)
    }
    
    /// Ячейка для swipe-to-action
    /// - Parameters:
    ///   - action: перехватчик нажатия на ячейку
    ///   - title: подпись под картинкой, tint = .white
    ///   - icon: картинка, tint = .white
    ///   - width: ширина вьюхи
    ///   - background: левый цвет фона вьюхи, если не выставлен secondBackground, то градиент будет с этим же цветом, с процентом перехода в черный = 25%
    ///   - secondBackground: второй (правый) цвет градиента, опциональный
    public init(action: @escaping (() -> Void),
                title: String? = nil,
                icon: UIImage? = nil,
                width: CGFloat? = nil,
                background: UIColor,
                secondBackground: UIColor? = nil) {
        self.init(isFirst: false,
                  action: action,
                  title: title,
                  icon: icon,
                  width: width,
                  background: background,
                  secondBackground: secondBackground ?? background.fade(toColor: .black, withPercentage: 0.25))
    }
    
    var isFirst = false
    var action: (() -> Void)
    var title: String?
    var icon: UIImage?
    var width: CGFloat?
    var background: UIColor
    var secondBackground: UIColor
    
    public var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 0) {
                Spacer()
                Button(action: { action() }) {
                    VStack(spacing: 4) {
                        if let icon = icon?.ditImageWithTintColor(.white) {
                            Image(uiImage: icon)
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                        if let title = title {
                            Text(title)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
                Spacer()
            }
            Spacer()
        }
        .frame(minWidth: 44)
        .padding(.leading, isFirst ? 8 : 0)
        .background(
            LinearGradient(
                gradient: .init(colors: [
                    Color(secondBackground),
                    Color(background)
                ]),
                startPoint: .trailing,
                endPoint: .leading
            )
        )
        .ignoreSafeAreaIfNedded()
    }
    
    mutating func setFirst(_ first: Bool) {
        self.isFirst = first
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(background)
        hasher.combine(isFirst)
    }
    
    public static func == (lhs: SwipeView, rhs: SwipeView) -> Bool {
        lhs.title == rhs.title
    }
}

fileprivate var lock = NSLock()

internal extension UIImage {
	func ditImageWithTintColor(_ color: UIColor) -> UIImage? {
		lock.lock()
		defer {
			lock.unlock()
		}
		var image: UIImage? = withRenderingMode(.alwaysTemplate)
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		color.set()
		image?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}
