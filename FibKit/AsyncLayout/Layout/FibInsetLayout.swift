//
//  InsetLayout.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

public class FibInsetLayout: FibLayoutElement {
    
    public func layoutThatFits(size: CGSize) -> FibLayout {
        let insetRect = CGRect(origin: .zero, size: size).inset(by: insets)
        let layout = sublayouts.first!.layoutThatFits(size: insetRect.size)
        return .init(size: layout.size, insets: layout.insets.applying(self.insets))
    }
    
    public var sublayouts: [FibLayoutElement] = []
    
    public var insets: UIEdgeInsets
    
    init(insets: UIEdgeInsets, child: FibLayoutElement) {
        sublayouts.append(child)
        self.insets = insets
    }
}
