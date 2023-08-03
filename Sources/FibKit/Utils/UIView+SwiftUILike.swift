//
//  UI+Modifiers.swift
//  SmartStaff
//
//  Created by Danil Pestov on 15.07.2021.
//  Copyright © 2021 DIT. All rights reserved.
//

import UIKit
import Combine

extension UILabel {
	func font(_ font: UIFont) -> UILabel {
		self.font = font
		return self
	}
	
	func textColor(_ textColor: UIColor) -> UILabel {
		self.textColor = textColor
		return self
	}
	
	func linelimit(_ linelimit: Int) -> UILabel {
		self.numberOfLines = linelimit
		return self
	}
	
	func textAlignment(_ textAlignment: NSTextAlignment) -> UILabel {
		self.textAlignment = textAlignment
		return self
	}
	
	convenience init(text: String) {
		self.init(frame: .zero)
		self.text = text
	}
	
	convenience init(text: Published<String>.Publisher, cancellables: inout Set<AnyCancellable>) {
		self.init(text: text.eraseToAnyPublisher(), cancellables: &cancellables)
	}
	
	convenience init(text: AnyPublisher<String, Never>, cancellables: inout Set<AnyCancellable>) {
		self.init(frame: .zero)
		_ = self.text(publisher: text, cancellables: &cancellables)
	}
	
	func text(publisher: Published<String>.Publisher, cancellables: inout Set<AnyCancellable>) -> UILabel {
		return text(publisher: publisher.eraseToAnyPublisher(),
					cancellables: &cancellables)
	}
	
	func text(publisher: AnyPublisher<String, Never>, cancellables: inout Set<AnyCancellable>) -> UILabel {
		publisher.map { $0 }
			.assign(to: \.text, on: self)
			.store(in: &cancellables)
		return self
	}
	
	func textColor(publisher: Published<UIColor>.Publisher, cancellables: inout Set<AnyCancellable>) -> UILabel {
		return textColor(publisher: publisher.eraseToAnyPublisher(),
						 cancellables: &cancellables)
	}
	
	func textColor(publisher: AnyPublisher<UIColor, Never>, cancellables: inout Set<AnyCancellable>) -> UILabel {
		publisher
			.assign(to: \.textColor, on: self)
			.store(in: &cancellables)
		return self
	}
	
	func minimumScaleFactor(_ minimumScaleFactor: CGFloat) -> UILabel {
		self.minimumScaleFactor = minimumScaleFactor
		return self
	}
	
	func adjustsFontSizeToFitWidth(_ isAdjust: Bool) -> UILabel {
		self.adjustsFontSizeToFitWidth = isAdjust
		return self
	}

	func getNumberOfLines() -> Int {
	  guard let myText = self.text as NSString? else {
		return 0
	  }
	  let rect = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
	  let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: self.font as Any], context: nil)
	  return Int(ceil(CGFloat(labelSize.height) / self.font.lineHeight))
	}
}


extension UIView {
	
	func backgroundColor(_ backgroundColor: UIColor) -> UIView {
		self.backgroundColor = backgroundColor
		return self
	}
	
	func backgroundColor(publisher: Published<UIColor>.Publisher, cancellables: inout Set<AnyCancellable>) -> UIView {
		return backgroundColor(publisher: publisher.eraseToAnyPublisher(),
							   cancellables: &cancellables)
	}
	
	func backgroundColor(publisher: AnyPublisher<UIColor, Never>, cancellables: inout Set<AnyCancellable>) -> UIView {
		publisher.map { $0 }
			.assign(to: \.backgroundColor, on: self)
			.store(in: &cancellables)
		return self
	}
	
	func cornerRadius(_ cornerRadius: CGFloat) -> Self {
		self.layer.cornerRadius = cornerRadius
		return self
	}
	
	func clipToCapsule() -> Self {
		self.makeOval()
		return self
	}
	
	func clipsToBounds(_ clipsToBounds: Bool) -> Self {
		self.clipsToBounds = clipsToBounds
		return self
	}
	
	func contentMode(_ contentMode: ContentMode) -> UIView {
		self.contentMode = contentMode
		return self
	}
	
	func alpha(_ alpha: CGFloat) -> UIView {
		self.alpha = alpha
		return self
	}
	
	func alpha(publisher: Published<CGFloat>.Publisher, cancellables: inout Set<AnyCancellable>) -> UIView {
		return alpha(publisher: publisher.eraseToAnyPublisher(), cancellables: &cancellables)
	}
	
	func alpha(publisher: AnyPublisher<CGFloat, Never>, cancellables: inout Set<AnyCancellable>) -> UIView {
		publisher
			.assign(to: \.alpha, on: self)
			.store(in: &cancellables)
		return self
	}
	
	func isHidden(publisher: Published<Bool>.Publisher, cancellables: inout Set<AnyCancellable>) -> UIView {
		return isHidden(publisher: publisher.eraseToAnyPublisher(), cancellables: &cancellables)
	}
	
	func isHidden(publisher: AnyPublisher<Bool, Never>, cancellables: inout Set<AnyCancellable>) -> UIView {
		publisher
			.assign(to: \.isHidden, on: self)
			.store(in: &cancellables)
		return self
	}
	
	func shadow(color: UIColor? = .black, offset: CGSize = CGSize(width: 0, height: -3), radius: CGFloat = 3, opacity: Float = 0) -> UIView {
		self.layer.shadowColor = color?.cgColor
		self.layer.shadowOffset = offset
		self.layer.shadowRadius = radius
		self.layer.shadowOpacity = opacity
		return self
	}
	
	@discardableResult
	func addTapGestsureRecognizer(target: Any?, action: Selector?) -> Self {
		let tap = UITapGestureRecognizer(target: target, action: action)
		addGestureRecognizer(tap)
		return self
	}
	
	func borderWidth(_ borderWidth: CGFloat) -> UIView {
		layer.borderWidth = borderWidth
		return self
	}
	
	func borderColor(_ borderColor: UIColor) -> UIView {
		layer.borderColor = borderColor.cgColor
		return self
	}
	
	func bind(borderColor: Published<UIColor>.Publisher, cancellables: inout Set<AnyCancellable>) -> UIView {
		return bind(borderColor: borderColor.eraseToAnyPublisher(),
					cancellables: &cancellables)
	}
	
	func bind(borderColor: AnyPublisher<UIColor, Never>, cancellables: inout Set<AnyCancellable>) -> UIView {
		borderColor.map { $0.cgColor }
			.assign(to: \.layer.borderColor, on: self)
			.store(in: &cancellables)
		return self
	}
	
	func contentCompressionResistancePriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> UIView {
		self.setContentCompressionResistancePriority(priority, for: axis)
		return self
	}
	
	func contentHuggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> UIView {
		self.setContentHuggingPriority(priority, for: axis)
		return self
	}
	
	func insetsLayoutMarginsFromSafeArea(_ isEnabled: Bool) -> UIView {
		insetsLayoutMarginsFromSafeArea = isEnabled
		return self
	}
	
	func blur(style: UIBlurEffect.Style, alpha: CGFloat = 1) -> UIView {
		let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
		blurView.frame = bounds
		blurView.alpha = alpha
		blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		addSubview(blurView)
		return self
	}
	
	func isSkeletonable(_ isSkeletonable: Bool) -> UIView {
		self.isSkeletonable = isSkeletonable
		return self
	}
	
	func isHiddenWhenSkeletonIsActive(_ isHiddenWhenSkeletonIsActive: Bool) -> UIView {
		self.isHiddenWhenSkeletonIsActive = isHiddenWhenSkeletonIsActive
		return self
	}
}

extension UIButton {
	convenience init(title: String) {
		self.init(frame: .zero)
		setTitle(title, for: .normal)
	}
	
	convenience init(title: Published<String>.Publisher, cancellables: inout Set<AnyCancellable>) {
		self.init(title: title.eraseToAnyPublisher(), cancellables: &cancellables)
	}
	
	convenience init(title: AnyPublisher<String, Never>, cancellables: inout Set<AnyCancellable>) {
		self.init(frame: .zero)
		_ = self.title(publisher: title, for: .normal, cancellables: &cancellables)
	}
	
	func title(_ title: String, for state: UIControl.State) -> UIButton {
		setTitle(title, for: state)
		return self
	}
	
	func title(publisher: Published<String>.Publisher, for state: UIControl.State,
			   cancellables: inout Set<AnyCancellable>) -> UIButton {
		return title(publisher: publisher.eraseToAnyPublisher(), for: state,
					 cancellables: &cancellables)
	}
	
	func title(publisher: AnyPublisher<String, Never>, for state: UIControl.State,
			   cancellables: inout Set<AnyCancellable>) -> UIButton {
		publisher
			.sink { [weak self] title in
				self?.setTitle(title, for: state)
			}
			.store(in: &cancellables)
		return self
	}
	
	func titleColor(_ titleColor: UIColor, for state: UIControl.State) -> UIButton {
		setTitleColor(titleColor, for: state)
		return self
	}
	
	func addAction(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) -> UIButton {
		addTarget(target, action: action, for: controlEvents)
		return self
	}
	
	func contentEdgeInsets(_ insets: UIEdgeInsets) -> UIButton {
		contentEdgeInsets = insets
		return self
	}
}

extension UIImageView {
	
	convenience init(image: Published<UIImage?>.Publisher, cancellables: inout Set<AnyCancellable>) {
		self.init(image: image.eraseToAnyPublisher(), cancellables: &cancellables)
	}
	
	convenience init(image: AnyPublisher<UIImage?, Never>, cancellables: inout Set<AnyCancellable>) {
		self.init(frame: .zero)
		_ = self.image(publisher: image, cancellables: &cancellables)
	}
	
	func image(publisher: Published<UIImage?>.Publisher, cancellables: inout Set<AnyCancellable>) -> UIImageView {
		return image(publisher: publisher.eraseToAnyPublisher(),
					cancellables: &cancellables)
	}
	
	func image(publisher: AnyPublisher<UIImage?, Never>, cancellables: inout Set<AnyCancellable>) -> UIImageView {
		publisher
			.assign(to: \.image, on: self)
			.store(in: &cancellables)
		return self
	}
}

public extension UIView {
	
	/// Adds subviews in provided order
	/// - Parameter views: views
	func zStackAddSubviews(_ views: [UIView]) {
		views.forEach({
			addSubview($0)
		})
	}
	
	/// Adds subviews in provided order
	/// - Parameter views: views
	func zStackAddSubviews(@ArrayBuilder<UIView> _ views: (() -> [UIView])) {
		zStackAddSubviews(views())
	}
	
	
	/// Adds subviews in provided order
	/// - Parameter views: views
	@discardableResult
	func zStackAddingSubviews(@ArrayBuilder<UIView> _ views: (() -> [UIView])) -> Self {
		zStackAddSubviews(views())
		return self
	}
	
	func with<T>(_ val: T?, at: ReferenceWritableKeyPath<UIView, T>) -> Self {
		guard let val = val else { return self }
		self[keyPath: at] = val
		return self
	}
	
	func with<T, U: UIView>(_ val: T?, at: ReferenceWritableKeyPath<U, T>, type: U.Type) -> U {
		guard let val = val else { return self as! U }
		(self as! U)[keyPath: at] = val
		return self as! U
	}
	
	private struct AssociatedKeys {
		static var _snpClosure = "ru.SmartStaff.UIView._snpClosure"
	}
}

public extension UIStackView {
	
	func replaceSubviews(@ArrayBuilder<UIView> _ views: (() -> [UIView])) {
		let views = views()
		self.arrangedSubviews.forEach({ self.removeArrangedSubview($0) })
		views.forEach { view in
			self.addArrangedSubview(view)
		}
	}
	
	func replacingSubviews(@ArrayBuilder<UIView> _ views: (() -> [UIView])) -> Self {
		replaceSubviews(views)
		return self
	}
 }
