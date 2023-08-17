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
		return MyFibHeader.ViewModel()
	}
	
	var arr2 = Array(0...50)
	
	override var configuration: FibViewController.Configuration? {
		.init(viewConfiguration: .init(
			roundedShutterBackground: .white,
			shutterBackground: .white,
			viewBackgroundColor: .white,
			shutterType: .rounded,
			topInsetStrategy: .top,
			headerBackgroundViewColor: .green.withAlphaComponent(0.5),
			headerBackgroundEffectView: {
//				return nil
				return UIVisualEffectView(effect: UIBlurEffect(style: .regular))
			}
		))
	}
	
//	override var footer: FibCell.ViewModel? {
//		.init(provider: GridSection {
//			MyFibHeader.ViewModel(flag: flag)
//		})
//		.backgroundColor(.green.withAlphaComponent(0.2))
//		.borderStyle(.shadow)
//		.needRound(false)
//	}
	
//	private var stack: SectionStack {
//		SectionStack {
//
//		}
//	}
	
//	private var bodyContent: SectionProtocol {
//		SectionStack {
//			SpacerSection(16)
//			GridSection {
//				arr2.map { i in
//					MyFibSquareView.ViewModel(text: "\(i) first cell")
//
//				}
//			}
//			.didReorderItems({[weak self] oldIndex, newIndex in
//				guard let self = self else { return }
//				let item = arr2.remove(at: oldIndex)
//				arr2.insert(item, at: newIndex)
//				reload()
//			})
//			.centeringFlowLayout(spacing: 16)
//			.header(MyFibHeader.ViewModel(flag: false, headerStrategy: .init(controller: self, titleString: "@#R#@@#F@#")))
//			.isSticky(false)
//			.tapHandler { _ in
//				self.flag.toggle()
//			}
//		}
//	}
	
	private var bodyContent: SectionProtocol {
			GridSection {
				arr2.map { i in
					MyFibSquareView.ViewModel(text: "\(i) first cell")
					
				}
			}
			.didReorderItems({[weak self] oldIndex, newIndex in
				guard let self = self else { return }
				let item = arr2.remove(at: oldIndex)
				arr2.insert(item, at: newIndex)
				reload()
			})
			.centeringFlowLayout(spacing: 16)
			.header(MyFibHeader.ViewModel(flag: false, headerStrategy: .init(controller: self, titleString: "@#R#@@#F@#")))
			.isSticky(false)
			.tapHandler { _ in
				self.flag.toggle()
			}
	}
	
	private var bodyDebug: SectionProtocol {
		SectionStack {
			GridSection {
				FibDebugView.ViewModel(section: bodyContent)
			}
		}
	}
	
	override var body: SectionProtocol? {
		SectionStack {
			bodyContent
			bodyDebug
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
		let appearance = UINavigationBarAppearance()
		appearance.configureWithTransparentBackground()
//		appearance.backgroundColor = UIColor.clear
//		appearance.backgroundEffect = nil
		appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
		navigationController?.navigationBar.standardAppearance = appearance
		navigationController?.navigationBar.scrollEdgeAppearance = appearance
	}
}

class MyFibHeader: UIView, ViewModelConfigurable, FibViewHeader, FormViewAppearable, CollectionViewReusableView {
	func configure(with data: FibKit.ViewModelWithViewClass?) {
//		backgroundColor = .green
		layer.borderColor = UIColor.blue.cgColor
		layer.borderWidth = 3
		guard let data = data as? ViewModel else { return }
		self.viewModel = data
	}
	
	func prepareForReuse() {
		
	}
	
	var viewModel: ViewModel?
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		return .init(width: targetSize.width, height: data.flag ? 44 : 300)
	}
	
	struct ViewModel: ViewModelWithViewClass, FibViewHeaderViewModel {
		var atTop: Bool { true }
		var maxHeight: CGFloat? { nil }
		var minHeight: CGFloat? { 100 }
		var allowedStretchDirections: Set<StretchDirection> = [.down, .up]
		var flag = false
		var headerStrategy: HeaderStrategy?
//		var id: String? { UUID().uuidString }
		var sizeHash: String? { "\(flag)" }
		func viewClass() -> FibKit.ViewModelConfigurable.Type {
			MyFibHeader.self
		}
		
		struct HeaderStrategy {
			weak var controller: UIViewController?
			var titleString: String?
		}
		
	}
	
	func onAppear(with formView: FibGrid?) {
		guard let controller = viewModel?.headerStrategy?.controller else { return }
		guard controller.navigationItem.title != nil else { return }
		let fadeTextAnimation = CATransition()
		fadeTextAnimation.duration = 0.1
		fadeTextAnimation.type = .fade

//		controller.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
		controller.navigationItem.title = nil
	}
	
	func onDissappear(with formView: FibGrid?) {
		guard let controller = viewModel?.headerStrategy?.controller else { return }
		guard controller.navigationItem.title == nil else { return }
		let fadeTextAnimation = CATransition()
		fadeTextAnimation.duration = 0.1
		fadeTextAnimation.type = .fade
//		controller.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
		controller.navigationItem.title = viewModel?.headerStrategy?.titleString
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
		backgroundColor = UIColor.red.withAlphaComponent(0.6)
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return .init(width: 100, height: 100)
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


class FibDebugView: UIView, ViewModelConfigurable, FibViewHeader {
	
	var label: UILabel = .init()
	var section: SectionRef?
	
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
		label.numberOfLines = 0
		label.textColor = .white
		label.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
		label.textAlignment = .left
		backgroundColor = .belizeHole
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		label.frame = bounds.inset(by: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
		label.text = FibKitDebugDescriptor.description(for: section)
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let fittingSize = CGSize(width: targetSize.width - 8, height: targetSize.height - 8)
		let size = label.sizeThatFits(fittingSize)
		return .init(width: targetSize.width, height: size.height + 8)
	}
	
	func configure(with data: FibKit.ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else { return }
		self.section = data.section
		label.text = FibKitDebugDescriptor.description(for: section)
	}
	
	class ViewModel: ViewModelWithViewClass, FibViewHeaderViewModel {
		internal init(section: SectionRef?) {
			self.section = section
		}
		
		var id: String? {
			guard let section = section else { return UUID().uuidString }
			return "\(ObjectIdentifier(section))"
		}
		var section: SectionRef?
		
		func viewClass() -> FibKit.ViewModelConfigurable.Type {
			FibDebugView.self
		}
		
		
	}
}


typealias SectionRef = (SectionProtocol & AnyObject)
