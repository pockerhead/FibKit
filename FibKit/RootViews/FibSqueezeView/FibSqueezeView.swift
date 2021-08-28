//
//  FibSqueezeView.swift
//  FibKit
//
//  Created by Артём Балашов on 28.08.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

open class SqueezeView: UIView {

    open var needUserInteraction: Bool { false }

    var feedback = UISelectionFeedbackGenerator()
    open var squeezeUpDuration: TimeInterval = 0.1
    open var squeezeDownDuration: TimeInterval = 0.2
    open var squeezeDownScale: CGFloat = 0.95

    // MARK: - Touches
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard needUserInteraction, isUserInteractionEnabled else { return }
        UIView.animate(withDuration: squeezeDownDuration) {
            self.transform = CGAffineTransform(scaleX: self.squeezeDownScale, y: self.squeezeDownScale)
        }
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard needUserInteraction, isUserInteractionEnabled else { return }
        DispatchQueue.main.async {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        UIView.animate(withDuration: squeezeUpDuration) {
            self.transform = .identity
        }
    }
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard needUserInteraction, isUserInteractionEnabled else { return }
        UIView.animate(withDuration: squeezeUpDuration) {
            self.transform = .identity
        }
    }
}
