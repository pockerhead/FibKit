//
//  FibAsyncViewController.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

open class FibAsyncViewController: UIViewController {
    
    private let queue = ThreadPool.getSerialQueue()
    open var body: FibLayoutElement {
        fatalError("Override this!")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        asyncLayoutViews()
    }
    
    public func asyncLayoutViews() {
        mainOrAsync {[self] in
            let view = view!
            queue.async {
                AsyncLayoutEngine.processLayout(body, view: view)
            }
        }
    }
}
