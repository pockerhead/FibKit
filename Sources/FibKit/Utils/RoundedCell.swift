import UIKit

open class RoundedCell: SqueezeCell {
	
	open var isForceDisableRoundCorners: Bool {
		false
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	var shadowClosure: ((UIView) -> Void)?

	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	private func setup() {
		layer.shouldRasterize = false
		layer.rasterizationScale = UIScreen.main.scale
		self.contentView.clipsToBounds = true
		self.clipsToBounds = true
		self.layer.masksToBounds = false
		if !isForceDisableRoundCorners {
			self.contentView.layer.cornerRadius = 12
			self.layer.cornerRadius = 12
		}
	}

	open override func layoutSubviews() {
		super.layoutSubviews()
		shadowClosure?(self)
	}
}

open class SqueezeCell: UICollectionViewCell {

	var feedback = UISelectionFeedbackGenerator()
	open var needUserInteraction: Bool { false }
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
