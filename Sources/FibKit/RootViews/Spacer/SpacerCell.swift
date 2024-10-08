//
//  SpacerCell.swift
//  SmartStaff
//
//  Created artem on 03.04.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
//  Template generated by Balashov Artem @pockerhead
//


import SkeletonView
import UIKit

public class SpacerCell: UICollectionViewCell {

    // MARK: Outlets

    // MARK: Properties
    var mainColor: UIColor = .clear
    var corner: CGFloat = 0
    var masked: CACornerMask = []

    // MARK: Initialization

    override public  func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = self.corner
        layer.maskedCorners = self.masked
        contentView.layer.cornerRadius = self.corner
        contentView.layer.maskedCorners = self.masked
    }

    // MARK: UI Configuration

    private func configureUI() {
    }
}

public class FormViewSpacer: ViewModelWithViewClass {
    public let height: CGFloat
    public let color: UIColor
    public let width: CGFloat?
    public var cornerRadius: CGFloat = 0
    public var maskedCorners: CACornerMask = []

    public var id: String? {
        _id ?? "Spacer_height_\(height)_\(color.hexInt)"
    }
	
	private var _id: String? = nil
	
	public init(
		_ height: CGFloat,
		color: UIColor = .clear,
		width: CGFloat? = nil,
		cornerRadius: CGFloat = 0,
		maskedCorners: CACornerMask = [],
		id: String? = nil
	) {
        self.height = height
        self.color = color
        self.width = width
        self.cornerRadius = cornerRadius
        self.maskedCorners = maskedCorners
		self._id = id
    }

	public func id(_ id: String) -> Self {
		self._id = id
		return self
	}
	
    public func viewClass() -> ViewModelConfigurable.Type {
        SpacerCell.self
    }
    
    public var separator: ViewModelWithViewClass? {
        FormViewSpacer(0, color: .clear)
    }
}

// MARK: ViewModelConfigurable

extension SpacerCell: ViewModelConfigurable {

    typealias ViewModel = FormViewSpacer

    public func configure(with data: ViewModelWithViewClass?) {
        guard let data = data as? ViewModel else { return }
        mainColor = data.color
        self.corner = data.cornerRadius
        self.masked = data.maskedCorners
        applyAppearance()
    }

    public func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize? {
        guard let data = data as? ViewModel else { return .zero }
        return CGSize(width: data.width ?? targetSize.width, height: data.height)
    }
	
	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		applyAppearance()
	}
	
	func applyAppearance() {
		contentView.backgroundColor = mainColor
	}
}
