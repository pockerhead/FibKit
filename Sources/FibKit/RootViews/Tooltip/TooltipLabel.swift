//
//  TooltipLabel.swift
//  
//
//  Created by Денис Садаков on 29.08.2023.
//

import Foundation

public protocol TooltipViewModel: FibCoreViewModel {
	var text: String { get set }
}

public protocol TooltipLabelView: FibCoreView {}

final public class TooltipLabel: FibCoreView {
	
	var label: UILabel = UILabel()
	
	public struct TooltipAppearance {
		public init(
			backgroundColor: UIColor,
			textColor: UIColor
		) {
			self.backgroundColor = backgroundColor
			self.textColor = textColor
		}
		
		public var backgroundColor: UIColor
		public var textColor: UIColor
	}

	public static var defaultTooltipAppearance = TooltipAppearance(
		backgroundColor: .secondarySystemBackground,
		textColor: .label
	)
	
	public var tooltipAppearance: TooltipAppearance? {
		nil
	}
	
	public var tooltipBackgroundColor: UIColor {
		tooltipAppearance?.backgroundColor ?? TooltipLabel.defaultTooltipAppearance.backgroundColor
	}
	
	public var textColor: UIColor {
		tooltipAppearance?.textColor ?? TooltipLabel.defaultTooltipAppearance.textColor
	}
	
	public override func configureUI() {
		super.configureUI()
		addSubview(label)
		label.font = .boldSystemFont(ofSize: 12)
		label.textColor = textColor
		backgroundColor = tooltipBackgroundColor
		label.textAlignment = .left
		label.numberOfLines = 0
		layer.cornerRadius = 8
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		label.frame = bounds.inset(by: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
		backgroundColor = tooltipBackgroundColor
	}
	
	public override func configureAppearance() {
		label.textColor = textColor
		backgroundColor = tooltipBackgroundColor
	}
	
	public override func configure(with data: ViewModelWithViewClass?) {
		super.configure(with: data)
		guard let data = data as? ViewModel else { return }
		label.text = data.text
		backgroundColor = tooltipBackgroundColor
	}
	
	public override func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return targetSize }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return CGSize(width: size.width + 16, height: size.height + 12)

	}
	
	
	
	class ViewModel: FibCoreViewModel, TooltipViewModel {
		var text: String
		init(text: String) {
			self.text = text
		}
		override func viewClass() -> ViewModelConfigurable.Type {
			TooltipLabel.self
		}
	
	}
}
