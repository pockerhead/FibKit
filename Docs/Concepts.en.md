# Core Concepts

This document introduces the main ideas behind **FibKit**. Understanding these concepts helps to navigate the APIs and build declarative UIs.

## ViewModelWithViewClass

`ViewModelWithViewClass` is a protocol that couples a view model with the class of the view that can render it. Each view model exposes `viewClass()` returning a `ViewModelConfigurable` type and provides identifiers used for diffing.

Key properties from `ViewModel.swift`:

```swift
public protocol ViewModelWithViewClass: AnyViewModelSection {
    var id: String? { get }
    var storedId: String? { get set }
    var sizeHash: String? { get }
    var showDummyView: Bool { get set }
    var userInfo: [AnyHashable: Any]? { get set }
    var separator: ViewModelWithViewClass? { get }
    func viewClass() -> ViewModelConfigurable.Type
}
```

A concrete view model conforms to this protocol and declares which view type should be used to display it.

## ViewModelConfigurable

Views that want to be configured by a view model implement `ViewModelConfigurable`. The protocol defines methods for updating the view and calculating its size based on incoming data.

Simplified definition:

```swift
public protocol ViewModelConfigurable: UIView {
    func configure(with data: ViewModelWithViewClass?)
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize?
    func sizeWith(_ targetSize: CGSize,
                  data: ViewModelWithViewClass?,
                  horizontal: UILayoutPriority,
                  vertical: UILayoutPriority) -> CGSize?
    func backgroundSizeWith(_ targetSize: CGSize,
                            data: ViewModelWithViewClass?,
                            horizontal: UILayoutPriority,
                            vertical: UILayoutPriority) -> CGSize?
    func setHighlighted(highlighted: Bool)
}
```

This separation between model and view keeps the UI declarative and testable.

## Providers

Collection views inside FibKit are powered by *providers*. A provider combines a data source, a view source, a size source and a layout to produce cells. Providers can be composed to create complex structures and act as the backbone of `FibGrid`.

For example, `BasicProvider` stores the data source and view source and exposes callbacks like `tapHandler`:

```swift
open class BasicProvider<Data, View: UIView>: ItemProvider, LayoutableProvider, CollectionReloadable {
    open var dataSource: DataSource<Data> { didSet { setNeedsReload() } }
    open var viewSource: ViewSource<Data, View> { didSet { setNeedsReload() } }
    open var sizeSource: SizeSource<Data> { didSet { setNeedsInvalidateLayout() } }
    open var layout: Layout { didSet { setNeedsInvalidateLayout() } }
    open var animator: Animator? { didSet { setNeedsReload() } }
    open var tapHandler: TapHandler?
    // ...
}
```

Providers report the number of items, create/update views, and handle layout invalidation.

## Diffing

`FibGrid` performs automatic diffing when reloading data. When `reloadData()` is called, it compares identifiers of existing cells with the new provider output and animates insertions or deletions accordingly. The comment in `FibGrid.swift` highlights this behaviour:

```swift
// reload all frames. will automatically diff insertion & deletion
public func reloadData(contentOffsetAdjustFn: ((CGSize) -> CGPoint)? = nil) { ... }
```

This allows updates to be expressed declaratively without manually tracking index changes.

## Declarativity

FibKit adopts a SwiftUI-like declarative style. Controllers define their interface by returning a tree of sections and view models from the `body` property:

```swift
class MyViewController: FibViewController {
    override var body: SectionProtocol? {
        SectionStack {
            ViewModelSection { MyView.ViewModel(text: "Hello") }
        }
    }
}
```

Function builders are heavily used to create nested layouts, and view models describe the state for each view. This approach keeps UI code concise and easy to reason about.
