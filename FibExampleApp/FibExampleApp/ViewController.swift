//
//  ViewController.swift
//  FibExampleApp
//
//  Created by Артём Балашов on 18.07.2023.
//

import FibKit

class ViewController: FibViewController {
	
	override var header: FibViewHeaderViewModel? {
		MyFibView.ViewModel(text: "HEADER_TOP")
	}
	
	var arr2 = Array(0...100)
	var flag = true
	
	override var body: SectionProtocol? {
		SectionStack {
			SpacerSection(30)
			GridSection(forceReassignLayout: true) {
				arr2.map { i in
					MyFibSquareView.ViewModel(text: "arr2_cell_\(i)")
				}
			}
			.tapHandler { cont in
				self.arr2.remove(at: cont.index)
				self.reload()
			}
			sections
		}
	}
	
	@SectionBuilder
	var sections: [GridSection] {
		GridSection {
			
		}
		GridSection {
			
		}
	}
	
	override init(provider: SectionProtocol?) {
		super.init(provider: provider)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		title = "g34g42g234fg2"
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
			false
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
