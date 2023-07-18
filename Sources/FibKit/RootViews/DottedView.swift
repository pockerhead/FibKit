//
//  DottedView.swift
//  SmartStaff
//
//  Created by artem on 21.04.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import UIKit

public final class DottedView: UIView {

    public var dotColor: UIColor? {
        didSet {
            createDottedLine()
        }
    }

    func createDottedLine() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let caShapeLayer = CAShapeLayer()
        caShapeLayer.strokeColor = dotColor?.cgColor
        caShapeLayer.lineWidth = bounds.height
        caShapeLayer.lineDashPattern = [2, 4]
        let cgPath = CGMutablePath()
        let cgPoint = [CGPoint(x: 0, y: bounds.height / 2), CGPoint(x: self.frame.width, y: bounds.height / 2)]
        cgPath.addLines(between: cgPoint)
        caShapeLayer.path = cgPath
        layer.addSublayer(caShapeLayer)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        createDottedLine()
    }
}
