//
//  ViewController.swift
//  FibKitExampleApp
//
//  Created by Артём Балашов on 28.08.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import FibKit

class ViewController: FibAsyncViewController {

    override var body: FibLayoutElement {
        FibVStack {
            cell
            cell
            cell
            cell
            cell
            cell
        }
    }
    
    var button = UIButton()
    
    var cell: FibLayoutElement {
        FibVStack(alignment: .leading) {
            FibHStack(spacing: 16) {
                FibViewNode()
                    .backgroundColor(.green)
                    .size(64)
                FibVStack(spacing: 2, alignment: .leading) {
                    FibTextNode("Hello world!! Hello world!! Hello world!!")
                        .font(.systemFont(ofSize: 16, weight: .medium))
                        .foregroundColor(.black)
                    FibTextNode("Hello world!! Hello world!! Hello world!! Hello world!! Hello world!! Hello world!! Hello world!! Hello world!! Hello world!! Hello world!!")
                        .font(.systemFont(ofSize: 16, weight: .regular))
                        .foregroundColor(.darkGray)
                }
            }
            .inset(by: .init(top: 16, left: 16, bottom: 16, right: 16))
            FibViewNode()
                .backgroundColor(.separator)
                .size(height: 1)
                .inset(by: .init(top: 0, left: 16, bottom: 0, right: 0))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(button)
        button.setTitle("reset", for: .normal)
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(button)
        button.backgroundColor = .blue
        button.frame = .init(x: 100, y: 100, width: 100, height: 100)
    }

    @objc func tap() {
        asyncLayoutViews()
    }
    
}

