//
//  FibVStack.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit
import Threading

final public class FibVStack: FibViewNode {
    
    public enum Alignment {
        case center
        case leading
        case trailing
    }
    
    private var finalFrames = ThreadedArray<CGRect>()
    
    public override func updateView() {
        super.updateView()
        mainOrAsync {[self, finalFrames] in
            sublayouts.enumerated().forEach({ index, element in
                if let subView = element.findFirstView() {
                    addSubview(subView, relatedLayout: element)
                    subView.frame = finalFrames[s: index] ?? .zero
                }
            })
        }
    }
    
    public override func layoutThatFits(size: CGSize) -> FibLayout {
        super.layoutThatFits(size: size)
        let stackFrame = CGRect(origin: .zero, size: size)
        var startOriginY: CGFloat?
        sublayouts.forEach { element in
            let layout = element.layoutThatFits(size: size)
            var itemFrame = CGRect(origin: .init(x: 0 + layout.insets.left,
                                                 y: (startOriginY ?? 0) + layout.insets.top),
                                   size: layout.size)
            if alignment == .center {
                itemFrame.setCenterX(to: stackFrame)
            }
            if startOriginY == nil {
                startOriginY = itemFrame.origin.y
            }
            if spacing + itemFrame.height + startOriginY! > size.height {
                itemFrame.size.height = size.height - spacing - startOriginY!
            }
            let unionFrame = CGRect(origin: itemFrame.origin,
                                    size: .init(width: itemFrame.width + layout.insets.right,
                                                height: itemFrame.height + layout.insets.bottom))
            finalFrames.append(itemFrame)
            self.frame = self.frame.union(unionFrame)
            startOriginY = (frame.maxY + spacing)
        }
        return .init(size: .init(width: size.width, height: frame.height), insets: .zero)
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
