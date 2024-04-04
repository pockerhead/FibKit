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
	
	lazy var cancelDragTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancelDrag(sender:)))
	
	@Reloadable
	var arr2 = (0...50).map({ $0 })
	
	@Reloadable
	var isForceActive = false
	
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
			headerBackgroundEffectView: { self.effect },
			needFooterKeyboardSticks: true
			),
			navigationConfiguration: .init(titleViewModel: MyFibHeader.ViewModel())
		)
	}
	
	@Reloadable var isDragInProcess = false
	
	override var body: SectionProtocol? {
		SectionStack {
			ViewModelSection {
				MyFibSquareView.ViewModel(text: "cell #1")
						.id("1")
						.interactive(true)
						.sizeStrategy(.height(44))
						.onTap { view in
							PopoverService.showContextMenuWith(
								.init(
									view: view, 
									needHideSnapshot: true,
									needBlurBackground: false,
									viewToMenuSpacing: 4,
									menuWidth: self.view.bounds.width - 32,
									needHideAfterAction: true,
									verticalMenuAlignment: .common,
									dismissalInteraction: .anyTouch
								),
								.init(provider: ForEachSection(data: self.arr2) { i in MyFibSquareView.ViewModel(text: "cell #\(i)")
										.id("\(i)")
										.interactive(true)
								})
							)
						}
				MyFibSquareView.ViewModel(text: "cell #2")
						.id("2")
						.interactive(true)
						.sizeStrategy(.height(44))
						.onTap { view in
							PopoverService.showContextMenuWith(
								.init(
									view: view,
									needHideSnapshot: true,
									needBlurBackground: false,
									viewToMenuSpacing: 4,
									menuWidth: self.view.bounds.width - 32,
									needHideAfterAction: true,
									verticalMenuAlignment: .common,
									dismissalInteraction: .anyTouch
								),
								.init(
									provider: ForEachSection(data: self.arr2) { i in MyFibSquareView.ViewModel(text: "cell #\(i)")
											.id("\(i)")
											.interactive(true)
									}
								)
							)
						}
				MyFibSquareView.ViewModel(text: "cell #1")
						.id("1")
						.interactive(true)
						.sizeStrategy(.height(700))
						.onTap { view in
							PopoverService.showContextMenuWith(
								.init(view: view),
								.init(
									provider: ViewModelSection({
										MyFibSquareView.ViewModel(text: "cell #1")
											.sizeStrategy(.height(44))
										MyFibSquareView.ViewModel(text: "cell #1")
											.sizeStrategy(.height(44))
										MyFibSquareView.ViewModel(text: "cell #1")
											.sizeStrategy(.height(44))
									})
								)
							)
						}
			}
		}
		.id(UUID().uuidString)
	}
	
	override var footer: FibCell.ViewModel? {
		.init(provider: ViewModelSection({
			MyFibView.ViewModel(text: "32r23f")
		}))
		.borderStyle(.topShadow)
		.backgroundColor(.white)
		.needRound(false)
		.disableMaskToBounds(true)
	}
	
	func addDebugButton() {
		self.navigationItem.rightBarButtonItem = .init(title: "DBG", style: .plain, target: self, action: #selector(showDebugScreen))
	}
	
	@objc func showDebugScreen() {
		isForceActive.toggle()
	}
	
	var canc: Set<AnyCancellable> = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		rootView.applyAppearance()
		addDebugButton()
		setLayerDisableScreenshots(view.layer, true)
		rootView.rootFormView.keyboardDismissMode = .onDrag
		view.addGestureRecognizer(cancelDragTapRecognizer)
		cancelDragTapRecognizer.delegate = self
		rootView.rootFormView.alwaysBounceVertical = true
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
//			print("32f23f23")
//		}
//		appearance.backgroundColor = UIColor.clear
//		appearance.backgroundEffect = nil
		appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
		navigationController?.navigationBar.standardAppearance = appearance
		navigationController?.navigationBar.scrollEdgeAppearance = appearance
	}
	
	@objc func cancelDrag(sender: UITapGestureRecognizer) {
		let loc = sender.location(in: self.view)
		let hitView = self.view.hitTest(loc, with: nil)
		// TODO find DSWidgetButton in hitView superViews
		if hitView === rootView.rootFormView {
			isDragInProcess = false
		}
	}
	
}

extension ViewController: UIGestureRecognizerDelegate {
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		true
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
	var contentView = UIView()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	override var intrinsicContentSize: CGSize {
		contentView.systemLayoutSizeFitting(bounds.size)
	}
	
	func configureUI() {
		addSubview(contentView)
		contentView.addSubview(label)
		layer.borderColor = UIColor.black.cgColor
		layer.borderWidth = 2
		label.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			label.topAnchor.constraint(equalTo: contentView.topAnchor),
			label.leftAnchor.constraint(equalTo: contentView.leftAnchor),
			label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			label.rightAnchor.constraint(equalTo: contentView.rightAnchor)
		])
		label.textAlignment = .center
		backgroundColor = UIColor.systemBackground
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		contentView.frame = bounds
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return .init(width: targetSize.width, height: 50)
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

class MyTextField: FibCoreView {
	
	let textField = UITextField()
	
	override func configureUI() {
		super.configureUI()
		addSubview(textField)
		backgroundColor = .lightGray
		textField.borderStyle = .roundedRect
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		textField.frame = bounds.inset(by: .init(top: 4, left: 8, bottom: 4, right: 8))
	}
	
	override func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		return .init(width: targetSize.width, height: 60)
	}
	
	final class ViewModel: FibCoreViewModel {
		
		override func viewClass() -> ViewModelConfigurable.Type {
			MyTextField.self
		}
	}
}

class MyFibView2: UIView, ViewModelConfigurable, FibViewHeader {
	
	var label: UILabel = .init()
	var contentView = UIView()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureUI()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		configureUI()
	}
	
	override var frame: CGRect {
		didSet {
			print(oldValue, frame)
		}
	}
	
	func configureUI() {
		addSubview(contentView)
		contentView.addSubview(label)
		layer.borderColor = UIColor.black.cgColor
		layer.borderWidth = 2
		backgroundColor = UIColor.systemBackground
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		contentView.frame = bounds
		label.frame = contentView.bounds
	}
	
	func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? ViewModel else { return .zero }
		configure(with: data)
		let size = label.sizeThatFits(targetSize)
		return .init(width: 160, height: size.height + 90)
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
			MyFibView2.self
		}
		
		
	}
}

class MyFibSquareView: FibCoreView {
	
	override var alpha: CGFloat {
		didSet {
			if label.text?.contains("#6") == true {
				print(alpha)
				print("2f32f")
			}
			
		}
	}
	
	var label: UILabel = .init()
	private var shakeAnimator: UIViewPropertyAnimator = .init()

	override func configureUI() {
		super.configureUI()
		contentView.addSubview(label)
	}
	
	override func layoutSubviews() {
		if !shakeAnimator.isRunning {
			super.layoutSubviews()
		}
		label.frame = contentView.bounds
		label.textAlignment = .center
		contentView.layer.borderWidth = 1
		contentView.layer.borderColor = UIColor.black.cgColor
	}
	
//	override func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
//		guard let data = data as? ViewModel else { return .zero }
//		configure(with: data)
//		let size = label.sizeThatFits(targetSize)
//		//return .init(width: label.text?.contains("2") == true ? 300 : 100, height: 100)
//		return .init(width: targetSize.width, height: 50)
//	}
	
	override func configure(with data: FibKit.ViewModelWithViewClass?) {
		guard let data = data as? ViewModel else { return }
		super.configure(with: data)
		label.text = data.text
		if data.needShakeAnimation && !shakeAnimator.isRunning {
			start()
		} else if !data.needShakeAnimation && shakeAnimator.isRunning {
			stop()
		}
	}
	
	func start(_ reversed: Bool? = nil) {
		shakeAnimator = .init(duration: 0.15, curve: .linear)
		shakeAnimator.addAnimations {[weak self] in
			self?.contentView.transform = .init(rotationAngle: (reversed ?? false) ? .pi / 25 : -(.pi / 25))
		}
		shakeAnimator.addCompletion {[weak self] _ in
			self?.start(!(reversed ?? true))
		}
		shakeAnimator.startAnimation(afterDelay: reversed == nil ? TimeInterval.random(in: 0...0.3) : 0)
	}

	func stop() {
		shakeAnimator.stopAnimation(true)
		shakeAnimator.finishAnimation(at: .current)
		UIView.animate(withDuration: 0.2) {
			self.contentView.transform = .identity
		}
	}
	
	
	class ViewModel: FibCoreViewModel {
		
		var needShakeAnimation = false
		
		init(text: String, needShakeAnimation: Bool = false) {
			self.text = text
			self.needShakeAnimation = needShakeAnimation
			super.init()
		}
		var expanded: Bool = false
		var text: String
		var color: UIColor = .white
		
		func color(_ color: UIColor) -> Self {
			self.color = color
			return self
		}
		
		func expanded(_ color: Bool) -> Self {
			self.expanded = color
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

