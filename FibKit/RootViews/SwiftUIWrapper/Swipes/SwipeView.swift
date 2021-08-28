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
                                .fontStyle(.tabbar)
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

public extension UIImage {
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

    func withBackgroundColor(_ color: UIColor, alpha: CGFloat = 1, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        if let alphaColor = color.cgColor.copy(alpha: alpha){
            ctx.setFillColor(alphaColor)
        } else {
            ctx.setFillColor(color.cgColor)
        }
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
      }
}

public extension UIImage {
    static var avatarPlaceholderOval: UIImage {
        UIImage(imageLiteralResourceName: "avatar-2")
    }
}

public extension String {
    var base64ToImage: UIImage? {
        let placeholder: UIImage = .avatarPlaceholderOval
        guard !self.isEmpty,
            let imageData = Data(base64Encoded: self,
                                 options: Data.Base64DecodingOptions.ignoreUnknownCharacters),
            !imageData.isEmpty else { return placeholder }
        return UIImage(data: imageData) ?? placeholder
    }

    var base64PdfToImage: UIImage? {
        let _: UIImage = .avatarPlaceholderOval
        guard !self.isEmpty,
            let pdfdata = Data(base64Encoded: self,
                               options: Data.Base64DecodingOptions.ignoreUnknownCharacters),
            !pdfdata.isEmpty else { return nil }
        let pdfData = pdfdata as CFData
        guard let dataProvider = CGDataProvider(data: pdfData),
            let document = CGPDFDocument(dataProvider),
            let page = document.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.clear.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            ctx.cgContext.drawPDFPage(page)
        }

        return img
    }
}

public extension Data {
    var pdfImage: UIImage? {
        let pdfData = self as CFData
        guard let dataProvider = CGDataProvider(data: pdfData),
            let document = CGPDFDocument(dataProvider),
            let page = document.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.clear.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            ctx.cgContext.drawPDFPage(page)
        }

        return img
    }
}


@objc enum FontStyle: Int {
    case caption1
    case title1
    case footnote1
    case footnote2
    case body1
    case body2
    case button
    case headline1
    case headline2
    case tabbar
    case navbar
    case unknown

    public init(_ font: UIFont) {
        switch font {
        case .systemFont(ofSize: FontStyle.caption1.fontSize, weight: .medium): self = .caption1
        case .systemFont(ofSize: FontStyle.title1.fontSize, weight: .bold): self = .title1
        case .systemFont(ofSize: FontStyle.footnote1.fontSize, weight: .medium): self = .footnote1
        case .systemFont(ofSize: FontStyle.footnote2.fontSize, weight: .semibold): self = .footnote2
        case .systemFont(ofSize: FontStyle.body1.fontSize, weight: .medium): self = .body1
        case .systemFont(ofSize: FontStyle.body2.fontSize, weight: .regular): self = .body2
        case .systemFont(ofSize: FontStyle.button.fontSize, weight: .semibold): self = .button
        case .systemFont(ofSize: FontStyle.headline1.fontSize, weight: .bold): self = .headline1
        case .systemFont(ofSize: FontStyle.headline2.fontSize, weight: .bold): self = .headline2
        case .systemFont(ofSize: FontStyle.tabbar.fontSize, weight: .medium): self = .tabbar
        case .systemFont(ofSize: FontStyle.navbar.fontSize, weight: .semibold): self = .navbar
        default: self = .unknown
        }
    }
    
    public var fontSize: CGFloat {
        switch self {
        case .caption1:     return 12
        case .title1:       return 20
        case .footnote1:    return 14
        case .footnote2:    return 14
        case .body1:        return 16
        case .body2:        return 16
        case .button:       return 18
        case .headline1:    return 30
        case .headline2:    return 24
        case .tabbar:       return 10
        case .navbar:       return 17
        case .unknown:
            #if DEBUG
            fatalError("Dont use .unknown case for labels")
            #else
            return 16
            #endif
        }
    }

    public var uiFont: UIFont {
        switch self {
        case .caption1:     return .systemFont(ofSize: fontSize, weight: .medium)
        case .title1:       return .systemFont(ofSize: fontSize, weight: .bold)
        case .footnote1:    return .systemFont(ofSize: fontSize, weight: .medium)
        case .footnote2:    return .systemFont(ofSize: fontSize, weight: .semibold)
        case .body1:        return .systemFont(ofSize: fontSize, weight: .medium)
        case .body2:        return .systemFont(ofSize: fontSize, weight: .regular)
        case .button:       return .systemFont(ofSize: fontSize, weight: .semibold)
        case .headline1:    return .systemFont(ofSize: fontSize, weight: .bold)
        case .headline2:    return .systemFont(ofSize: fontSize, weight: .bold)
        case .tabbar:       return .systemFont(ofSize: fontSize, weight: .medium)
        case .navbar:       return .systemFont(ofSize: fontSize, weight: .semibold)
        case .unknown:
            #if DEBUG
            fatalError("Dont use .unknown case for labels")
            #else
            return FontStyle.body1.uiFont
            #endif
        }
    }

    public var font: Font {
        switch self {
        case .caption1:     return .system(size: fontSize, weight: .medium)
        case .title1:       return .system(size: fontSize, weight: .bold)
        case .footnote1:    return .system(size: fontSize, weight: .medium)
        case .footnote2:    return .system(size: fontSize, weight: .semibold)
        case .body1:        return .system(size: fontSize, weight: .medium)
        case .body2:        return .system(size: fontSize, weight: .regular)
        case .button:       return .system(size: fontSize, weight: .semibold)
        case .headline1:    return .system(size: fontSize, weight: .bold)
        case .headline2:    return .system(size: fontSize, weight: .bold)
        case .tabbar:       return .system(size: fontSize, weight: .medium)
        case .navbar:       return .system(size: fontSize, weight: .semibold)
        case .unknown:
            #if DEBUG
            fatalError("Dont use .unknown case for labels")
            #else
            return FontStyle.body1.font
            #endif
        }
    }
}

extension View {
    func fontStyle(_ fontStyle: FontStyle) -> some View {
        return self.font(fontStyle.font)
    }
}

@IBDesignable
extension UILabel {

    @IBInspectable
    var fontStyle: FontStyle {
        get {
            return .init(font)
        }
        set {
            font = newValue.uiFont
        }
    }

}
