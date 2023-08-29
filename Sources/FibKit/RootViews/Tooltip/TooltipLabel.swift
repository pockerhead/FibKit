//
//  TooltipLabel.swift
//  
//
//  Created by Денис Садаков on 29.08.2023.
//

import Foundation

public protocol TooltipViewModel: ViewModelWithViewClass {
	var text: String { get set }
}

public protocol TooltipLabelView: ViewModelConfigurable {}

final class TooltipLabel: UIView, TooltipLabelView {
	
	var label: UILabel = UILabel()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	private func configureUI() {
		addSubview(label)
		label.font = .systemFont(ofSize: 12)
		label.textColor = .darkText
		label.textAlignment = .center
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		label.frame = bounds
	}
	
	func configure(with data: ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else { return }
		label.text = data.text
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize? {
		guard let data = data as? ViewModel else { return targetSize }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return size
	}
	
	
	class ViewModel: TooltipViewModel {
		var text: String
		init(text: String) {
			self.text = text
		}
		func viewClass() -> ViewModelConfigurable.Type {
			TooltipLabel.self
		}
	
	}
}
