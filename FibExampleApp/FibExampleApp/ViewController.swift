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
			headerBackgroundViewColor: .clear,
			headerBackgroundEffectView: nil
		))
	}
	
	var arr2 = Array(0...30)
	
	override var body: SectionProtocol? {
		SectionStack {
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
			.header(MyFibHeader.ViewModel(flag: true, headerStrategy: .init(controller: self, titleString: "@#R#@@#F@#")))
			.isSticky(false)
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
		addDebugButton()
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
		backgroundColor = [UIColor.red, .alizarin, .amethyst, .carrot, .clouds, .flatOrange, .emerald].randomElement()!.withAlphaComponent(0.6)
		layer.borderWidth = 1
		layer.borderColor = UIColor.black.cgColor
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return .init(width: 100, height: (90...160).randomElement() ?? 100)
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
	weak var reloadable: CollectionReloadable?
	weak var grid: FibGrid?
	
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
		let description = FibKitDebugDescriptor.description(for: (grid?.provider as? SectionProtocol))
		guard label.text != description else { return }
		label.text = description
		reloadable?.setNeedsReload()
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
		self.grid = data.grid
		self.reloadable = data.reloadable
		label.text = FibKitDebugDescriptor.description(for: (grid?.provider as? SectionProtocol))
	}
	
	class ViewModel: ViewModelWithViewClass, FibViewHeaderViewModel {
		internal init(reloadable: CollectionReloadable?, grid: FibGrid?) {
			self.reloadable = reloadable
			self.grid = grid
		}
		
		var id: String? {
			guard let grid = grid, let reloadable = reloadable else { return UUID().uuidString }
			return "\(ObjectIdentifier(grid)),\(ObjectIdentifier(reloadable))"
		}
		
		weak var reloadable: CollectionReloadable?
		weak var grid: FibGrid?
		
		func viewClass() -> FibKit.ViewModelConfigurable.Type {
			FibDebugView.self
		}
		
		
	}
}


typealias SectionRef = (SectionProtocol & AnyObject)

extension FibViewController {
	
	func addDebugButton() {
		self.navigationItem.rightBarButtonItem = .init(title: "DBG", style: .plain, target: self, action: #selector(showDebugScreen))
	}
	
	@objc func showDebugScreen() {
		let nav = UINavigationController(rootViewController: DebugHelperController(parent: self))
		nav.modalPresentationStyle = .fullScreen
		self.present(nav, animated: true)
	}
	
	func addCloseButton() {
		self.navigationItem.leftBarButtonItem = .init(title: "Close", style: .plain, target: self, action: #selector(dismissSelf))
	}
	
	@objc func dismissSelf() {
		dismiss(animated: true)
	}
}

final class DebugHelperController: FibViewController {
	
	init(parent: FibViewController?) {
		self.parentVC = parent
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	weak var parentVC: FibViewController?
	override var body: SectionProtocol? {
		SectionStack {
			GridSection { section in
				FibDebugView.ViewModel(reloadable: section, grid: parentVC?.rootView.rootFormView)
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addCloseButton()
		title = "\(String(describing: parentVC) ?? "")"
	}
}
