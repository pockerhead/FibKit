//
//  FibHStack.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit
import Threading

final public class FibHStack: FibViewNode {
    
    public enum Alignment {
        case center
        case top
        case bottom
    }
    
    private var finalFrames = ThreadedArray<CGRect>()
    
    public override func updateView() {
        super.updateView()
        mainOrAsync {[self, finalFrames] in
            sublayouts.enumerated().forEach({ index, element in
                if let subView = element.findFirstView() {
                    addSubview(subView, relatedLayout: element)
                    subView.frame = finalFrames[s: index] ?? .zero
                    if alignment == .center {
                        subView.frame.setCenterY(to: self.frame)
                    }
                }
            })
        }
    }
    
    public override func layoutThatFits(size: CGSize) -> FibLayout {
        finalFrames = ThreadedArray<CGRect>()
        super.layoutThatFits(size: size)
        var startOrigin = CGPoint.zero
        var stackSize = size
        sublayouts.forEach { element in
            let layout = element.layoutThatFits(size: stackSize)
            let frame = CGRect(origin: .init(x: startOrigin.x + layout.insets.left, y: startOrigin.y + layout.insets.top), size: layout.size)
            let unionFrame = CGRect(x: frame.origin.x, y: frame.origin.y,
                                    width: frame.width + layout.insets.right,
                                    height: frame.height + layout.insets.bottom)
            self.frame = self.frame.union(unionFrame)
            finalFrames.append(frame)
            startOrigin.x += frame.width + layout.insets.left + spacing
            stackSize.width -= frame.width + layout.insets.left + spacing
        }
        return .init(size: frame.size, insets: .zero)
    }
    
    var spacing: CGFloat
    var alignment: Alignment
    
    public init(spacing: CGFloat = 0, alignment: Alignment = .center, @FibViewBuilder _ views: (() -> [FibLayoutElement])) {
        self.spacing = spacing
        self.alignment = alignment
        super.init()
        self.sublayouts = views()
    }
}
