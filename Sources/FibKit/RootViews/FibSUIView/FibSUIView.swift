import UIKit
import SwiftUI

@available(iOS 16.0, *)
public final class FibSUIView<Content: View>: FibCoreView {
	
	private var suiContentView: (UIView & UIContentView)!
	
	public override func configureUI() {
		super.configureUI()
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		suiContentView.frame = contentView.frame
	}
	
	public override func sizeWith(_ targetSize: CGSize, data: (any ViewModelWithViewClass)?, horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
		guard let data = data as? FibSUIViewModel<Content> else { return .zero }
		configure(with: data)
		return suiContentView.systemLayoutSizeFitting(
			targetSize,
			withHorizontalFittingPriority: horizontal,
			verticalFittingPriority: vertical
		)
	}
	
	public override func configure(with data: (any ViewModelWithViewClass)?) {
		super.configure(with: data)
		guard let data = data as? FibSUIViewModel<Content> else { return }
		let config = UIHostingConfiguration(content: { data.content })
			.margins(.all, 0)
		if let view = suiContentView {
			view.configuration = config
		} else {
			suiContentView = config.makeContentView()
			contentView.addSubview(suiContentView)
		}
	}
}

@available(iOS 16.0, *)
public class FibSUIViewModel<T: View>: FibCoreViewModel {
	
	public var content: T
	
	public init(content: T) {
		self.content = content
	}
	
	public override func viewClass() -> any ViewModelConfigurable.Type {
		FibSUIView<T>.self
	}
}

@available(iOS 16.0, *)
public extension View {
	
	func fibView(line: Int = #line,
				 file: String = #file) -> FibSUIViewModel<Self> {
		FibSUIViewModel(content: self)
			.id("\(line)\(file)")
	}
}
