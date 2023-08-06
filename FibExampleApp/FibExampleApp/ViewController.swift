//
//  ViewController.swift
//  FibExampleApp
//
//  Created by Артём Балашов on 18.07.2023.
//

import FibKit

class ViewController: FibViewController {
	
	@Reloadable var flag = false
	
	override var header: FibViewHeaderViewModel? {
		guard flag else { return nil }
		return FibCell.ViewModel(provider: GridSection {
			MyFibHeader.ViewModel()
			EmbedCollection.ViewModel(
				provider: GridSection({
					arr2.map { i in
						MyFibSquareView.ViewModel(text: "arr2_cell_\(i)")
					} as [ViewModelWithViewClass?]
				})
				.rowLayout(spacing: 8)
			)
			.backgroundColor(.asbestos)
			.height(100)
		})
		.needRound(false)
		.borderStyle(.none)
	}
	
	var arr2 = Array(0...50)
	
	override var configuration: FibViewController.Configuration? {
		.init(viewConfiguration: .init(
			shutterType: .default
		))
	}
	
	override var body: SectionProtocol? {
		SectionStack {
			GridSection {
				FormViewSpacer(30)
				arr2.map { i in
					MyFibSquareView.ViewModel(text: "1--arr2_cell_\(i)")
				} as [ViewModelWithViewClass?]
			}
			.header(MyFibHeader.ViewModel(flag: true))
			.isSticky(true)
			.tapHandler { _ in
				self.flag.toggle()
			}
		}
	}
	
	@SectionBuilder
	var sections: [GridSection] {
		GridSection {
			arr2.map { i in
				MyFibSquareView.ViewModel(text: "1--arr2_cell_\(i)")
			} as [ViewModelWithViewClass?]
		}
		.header(MyFibView.ViewModel(text: "arr_HEADER_2"))
		.isSticky(true)
		GridSection {
			
		}
	}
	
	@SectionProtocolBuilder
	var stacks: [SectionProtocol] {
		SectionStack {
			GridSection {
				arr2.map { i in
					MyFibSquareView.ViewModel(text: "1--arr2_cell_\(i)")
				} as [ViewModelWithViewClass?]
			}
			.header(MyFibView.ViewModel(text: "arr_HE232ADER_2"))
			.isSticky(true)
		}
		SectionStack {
			
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		rootView.applyAppearance()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		title = "g34g42g234fg2"
	}
}

class MyFibHeader: UIView, ViewModelConfigurable, FibViewHeader {
	func configure(with data: FibKit.ViewModelWithViewClass?) {
		backgroundColor = .green
		layer.borderColor = UIColor.blue.cgColor
		layer.borderWidth = 3
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		return .init(width: targetSize.width, height: data.flag ? 44 : 300)
	}
	
	struct ViewModel: ViewModelWithViewClass, FibViewHeaderViewModel {
		var atTop: Bool { false }
		
		var flag = false
		var id: String? { UUID().uuidString }
		func viewClass() -> FibKit.ViewModelConfigurable.Type {
			MyFibHeader.self
		}
		
		
	}
}

class MyFibView: UIView, ViewModelConfigurable, FibViewHeader {
	
	var label: UILabel = .init()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	func configureUI() {
		addSubview(label)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		label.frame = bounds
		label.textAlignment = .center
		backgroundColor = UIColor.systemBackground
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return .init(width: targetSize.width, height: size.height + 20)
	}
	
	func configure(with data: FibKit.ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else { return }
		label.text = data.text
	}
	
	class ViewModel: ViewModelWithViewClass, FibViewHeaderViewModel {
		internal init(text: String) {
			self.text = text
		}
		
		var id: String? {
			text
		}
		var atTop: Bool {
			true
		}
		var text: String
		
		func viewClass() -> FibKit.ViewModelConfigurable.Type {
			MyFibView.self
		}
		
		
	}
}

class MyFibSquareView: UIView, ViewModelConfigurable {
	
	var label: UILabel = .init()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	func configureUI() {
		addSubview(label)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		label.frame = bounds
		label.textAlignment = .center
		backgroundColor = UIColor.tertiarySystemBackground
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return .init(width: 300, height: size.height + 20)
	}
	
	func configure(with data: FibKit.ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else { return }
		label.text = data.text
	}
	

	
	
	class ViewModel: ViewModelWithViewClass {
		internal init(text: String) {
			self.text = text
		}
		
		var id: String? {
			text
		}
		var text: String
		
		func viewClass() -> FibKit.ViewModelConfigurable.Type {
			MyFibSquareView.self
		}
	}
}
