//
//  Engine.swift
//  FibKit
//
//  Created by Артём Балашов on 30.08.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit
import Threading
import Combine

public struct ThreadPool {
    
    private static let concurrentQueues: [DispatchQueue] = (0...3).map({
        DispatchQueue.init(label: "com.FibKit.ConcurrentQueue_\($0)", qos: .userInteractive, attributes: .concurrent)
    })
    
    private static let syncQueues: [DispatchQueue] = (0...3).map({
        DispatchQueue.init(label: "com.FibKit.SerialQueue_\($0)", qos: .userInteractive)
    })
    
    public static func getSerialQueue() -> DispatchQueue {
        syncQueues.randomElement()!
    }
    
    public static func getConcurrentQueue() -> DispatchQueue {
        concurrentQueues.randomElement()!
    }
}

public struct AsyncLayoutEngine {
    
    public static func processLayout(queue: DispatchQueue = ThreadPool.getSerialQueue(),
                                     _ layout: FibLayoutElement,
                                     view: UIView) {
        mainOrAsync {
            let safeArea = view.safeAreaInsets
            let size = view.bounds.inset(by: safeArea).size
            queue.async {
                let element = layout.layoutThatFits(size: size)
                var insets = element.insets
                insets = insets.applying(safeArea)
                layout.recursiveUpdateViews()
                mainOrAsync {
                    if let subView = layout.findFirstView() {
                        view.addSubview(subView)
                        subView.frame = .init(origin: .init(x: safeArea.left + element.insets.left,
                                                            y: safeArea.top + element.insets.top),
                                              size: element.size)
                    }
                }
            }
        }
    }
}
