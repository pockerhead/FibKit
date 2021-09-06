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
            Cell()
            Cell()
            Cell()
            Cell()
            Cell()
            Cell()
        }
    }
    
    var button = UIButton()
    
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

class Cell: FibViewNode {
    override var body: FibLayoutElement {
        FibVStack(alignment: .leading) {
            FibHStack(spacing: 16) {
                FibViewNode()
                    .backgroundColor(.green)
                    .radius(32)
                    .size(64)
                FibVStack(spacing: 2, alignment: .leading) {
                    FibTextNode("Рожаем все!")
                        .font(.systemFont(ofSize: 16, weight: .medium))
                        .foregroundColor(.black)
                    FibTextNode("Куча всего и всего и вот это и это тоже и все такие")
                        .font(.systemFont(ofSize: 16, weight: .regular))
                        .foregroundColor(.darkGray)
                }
            }
            .inset(by: .init(top: 8, left: 16, bottom: 8, right: 16))
            FibViewNode()
                .backgroundColor(.separator)
                .size(height: 1)
                .inset(by: .init(top: 0, left: 16, bottom: 0, right: 0))
        }
    }
}
