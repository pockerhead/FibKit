import UIKit
import SwiftUI

@available(iOS 16.0, *)
public final class FibSUIView<Content: View>: FibCoreView {
	
	private var suiContentView: (UIView & UIContentView)!
	
	public override func configure(with data: (any ViewModelWithViewClass)?) {
		super.configure(with: data)
		guard let data = data as? FibSUIViewModel<Content> else { return }
		let config = UIHostingConfiguration(content: { data.content })
			.margins(.all, 0)
		if let view = suiContentView, view.supports(config) {
			view.configuration = config
		} else {
			suiContentView?.removeFromSuperview()
			suiContentView = config.makeContentView()
			contentView.addSubview(suiContentView)
			suiContentView.fillSuperview()
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
