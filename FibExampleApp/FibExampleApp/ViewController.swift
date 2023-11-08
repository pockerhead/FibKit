//
//  ViewController.swift
//  FibExampleApp
//
//  Created by Артём Балашов on 18.07.2023.
//

import Combine
import FibKit
import VisualEffectView

class ViewController: FibViewController {
	
	@Reloadable var flag = false
	
//	override var header: FibViewHeaderViewModel? {
//		return flag ? nil : EmbedCollection.ViewModel(
//			provider: ViewModelSection({
//				(0...5).map({ MyFibSquareView.ViewModel(text: "\($0)" ).id("\($0)")})
//			})
//			.centeringFlowLayout()
//			.didReorderItems({ _, _ in
//				
//			})
//		)
//		.sizeHash(UUID().uuidString)
//		.scrollDirection(.vertical)
//		.scrollEnabled(false)
//	}
	
	@Reloadable
	var arr2 = (0...1000).map({ $0 })
	
	let effect: VisualEffectView = {
		let view = VisualEffectView()
		view.blurRadius = 6
		view.colorTint = .clear
		view.colorTintAlpha = 0
		return view
	}()
	
//	let effect = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
	
	override var configuration: FibViewController.Configuration? {
		.init(
			viewConfiguration: .init(
			roundedShutterBackground: .white,
			shutterBackground: .white,
			viewBackgroundColor: .white,
			shutterType: .default,
			topInsetStrategy: .safeArea,
			headerBackgroundViewColor: .clear,
			headerBackgroundEffectView: { self.effect }
			),
			navigationConfiguration: .init(
				title: "3f23f32",
				largeTitleViewModel: MyFibView.ViewModel(text: "3f23f32"),
				searchContext:
					.init(
						hideWhenScrolling: true,
						onSearchResults: { text in
							print(text)
						}
					)
			)
		)
	}
	
	override var body: SectionProtocol? {
		SectionStack {
			ViewModelSection {
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
						.layout(WaterfallLayout())
			.header(MyFibHeader.ViewModel(flag: true, headerStrategy: .init(controller: self, titleString: "@#R#@@#F@#")))
			.isSticky(true)
			.tapHandler { _ in
				self.arr2.removeAll()
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					self.flag.toggle()
					self.arr2 = Array(0...10)
					self.showDebugScreen()
				}
			}
		}
		.id(UUID().uuidString)
	}
	
	@SectionBuilder
	var sections: [ViewModelSection] {
		ViewModelSection {
			arr2.map { i in
				MyFibSquareView.ViewModel(text: "1--arr2_cell_\(i)")
			} as [ViewModelWithViewClass?]
		}
		.header(MyFibView.ViewModel(text: "arr_HEADER_2"))
		.isSticky(true)
		ViewModelSection {
			
		}
	}
	
	@SectionProtocolBuilder
	var stacks: [SectionProtocol] {
		SectionStack {
			ViewModelSection {
				arr2.map { i in
					MyFibSquareView.ViewModel(text: "1--arr2_cell_\(i)")
				} as [ViewModelWithViewClass?]
			}
			.header(MyFibView.ViewModel(text: "arr_HE232ADER_2"))
			.isSticky(true)
		}
		ViewModelSection {
			
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		rootView.applyAppearance()
		addDebugButton()
	}
	
	var timer: AnyCancellable?
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
//		rootView.rootFormView.scrollDirection = .unlocked
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		let appearance = UINavigationBarAppearance()
		appearance.configureWithTransparentBackground()
//		addRefreshAction {
//			
//		}
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
//		guard let controller = viewModel?.headerStrategy?.controller else { return }
//		guard controller.navigationItem.title != nil else { return }
//		let fadeTextAnimation = CATransition()
//		fadeTextAnimation.duration = 0.1
//		fadeTextAnimation.type = .fade
//
////		controller.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
//		controller.navigationItem.title = nil
	}
	
	func onDissappear(with formView: FibGrid?) {
//		guard let controller = viewModel?.headerStrategy?.controller else { return }
//		guard controller.navigationItem.title == nil else { return }
//		let fadeTextAnimation = CATransition()
//		fadeTextAnimation.duration = 0.1
//		fadeTextAnimation.type = .fade
////		controller.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
//		controller.navigationItem.title = viewModel?.headerStrategy?.titleString
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
		layer.borderColor = UIColor.black.cgColor
		layer.borderWidth = 2
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
		return .init(width: targetSize.width, height: size.height + 90)
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

class MyFibSquareView: FibCoreView {
	
	var label: UILabel = .init()
	
	override func configureUI() {
		super.configureUI()
		contentView.addSubview(label)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		label.frame = contentView.bounds
		label.textAlignment = .center
		layer.borderWidth = 1
		layer.borderColor = UIColor.black.cgColor
	}
	
	override func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		//return .init(width: label.text?.contains("2") == true ? 300 : 100, height: 100)
		return .init(width: 48, height: 48)
	}
	
	override func configure(with data: FibKit.ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else { return }
		super.configure(with: data)
		label.text = data.text
		backgroundColor = data.color
	}
	

	
	
	class ViewModel: FibCoreViewModel {
		
		init(text: String) {
			self.text = text
			super.init()
		}
		var text: String
		var color: UIColor = .white
		
		func color(_ color: UIColor) -> Self {
			self.color = color
			return self
		}
		
		override func viewClass() -> FibKit.ViewModelConfigurable.Type {
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
			ViewModelSection { section in
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


public class MyFibSwipeView: FibCoreView, FibSwipeView {
	
	public var swipeEdge: FibKit.SwipesContainerView.Edge? = nil
	
	private let imageView = UIImageView()
	
	public override func configureUI() {
		super.configureUI()
		contentView.addSubview(imageView)
		imageView.contentMode = .scaleAspectFit
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		imageView.frame = contentView.bounds
	}
	
	
	public override func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		return CGSize(width: 84, height: 100)
	}
	
	override public func configure(with data: ViewModelWithViewClass?) {
		super.configure(with: data)
		guard let data = data as? ViewModel else { return }
		imageView.image = data.image
	}
	
	public class ViewModel: FibCoreViewModel, FibSwipeViewModel {
		public var title: String?
		public var secondGradientColor: UIColor?
		public var action: (() -> Void)?
		public var image: UIImage?
		public var backgroundColor: UIColor = UIColor.systemBackground
		
		public init(image: UIImage?, backgroundColor: UIColor = UIColor.systemBackground) {
			self.image = image
			self.backgroundColor = backgroundColor
			super.init()
		}
		
		public override func viewClass() -> FibKit.ViewModelConfigurable.Type {
			MyFibSwipeView.self
		}
	}
	
}


public class MarkerView: FibCoreView {

	var color: UIColor = .clear
	override public func configureAppearance() {
		super.configureAppearance()
	}
	
	override public func layoutSubviews() {
		super.layoutSubviews()
		backgroundColor = color
	}
	
	public override func configure(with data: ViewModelWithViewClass?) {
		super.configure(with: data)
		guard let data = data as? ViewModel else { return }
		color = data.backgroundColor
	}
	
	public override func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		return CGSize(width: 10, height: 10)
	}
	
	public class ViewModel: FibCoreViewModel, TooltipMarkerViewModel {
		public var backgroundColor: UIColor
		
		public var orientation: FibKit.TriangleView.ViewModel.Orientation
		
		public required init(backgroundColor: UIColor, orientation: FibKit.TriangleView.ViewModel.Orientation) {
			self.backgroundColor = backgroundColor
			self.orientation = orientation
		}
		
		
		public override func viewClass() -> FibKit.ViewModelConfigurable.Type {
			MarkerView.self
		}
	}
	
}

