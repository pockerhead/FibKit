//
//  FibSizeLayout.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

public class FibSizeLayout: FibLayoutElement {
    public func layoutThatFits(size: CGSize) -> FibLayout {
        let layout = sublayouts.first!.layoutThatFits(size: size)
        return .init(size: .init(width: width ?? layout.size.width,
                                 height: height ?? layout.size.height),
                     insets: .zero)
    }
    
    var height: CGFloat?
    var width: CGFloat?
    
    public var sublayouts: [FibLayoutElement] = []
    init(width: CGFloat?, height: CGFloat?, child: FibLayoutElement) {
        self.sublayouts.append(child)
        self.width = width
        self.height = height
    }
}
