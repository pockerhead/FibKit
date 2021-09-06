//
//  FibTextNode.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

final public class FibTextNode: FibViewNode {
    
    public override var viewType: UIView.Type {
        UILabel.self
    }
    
    var numberOfLines: Int = 0
    var textAlignment: NSTextAlignment = .natural
    
    var label: UILabel {
        (view as! UILabel)
    }
    
    public override func layoutThatFits(size: CGSize) -> FibLayout {
        super.layoutThatFits(size: size)
        return .init(size: attributedString.boundingRect(with: size,
                                                         options: .usesLineFragmentOrigin,
                                                         context: nil).size,
                     insets: .zero)
    }
    
    /// Must be called on main thread ONLY!!!
    public override func updateView() {
        super.updateView()
        mainOrAsync {[self] in
            label.numberOfLines = numberOfLines
            label.textAlignment = textAlignment
            label.attributedText = attributedString
            label.layer.masksToBounds = false
            label.clipsToBounds = false
        }
    }
    
    var attributedString: NSMutableAttributedString
    
    public init(attributedString: NSMutableAttributedString) {
        self.attributedString = attributedString
    }
    
    public convenience init(_ text: String) {
        self.init(attributedString: .init(string: text))
    }
    
    public func font(_ font: UIFont) -> Self {
        attributedString.addAttributes([.font: font],
                                       range: .init(location: 0, length: attributedString.string.count))
        return self
    }
    
    public func foregroundColor(_ color: UIColor) -> Self {
        attributedString.addAttributes([.foregroundColor: color],
                                       range: .init(location: 0, length: attributedString.string.count))
        return self
    }
    
    public func textAlignment(_ textAlignment: NSTextAlignment) -> Self {
        self.textAlignment = textAlignment
        return self
    }
}
