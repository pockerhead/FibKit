# FibCoreView

`FibCoreView` is the base class for reusable views in FibKit. It extends `UIView`
with features like swipe actions, highlighting effects, drag and drop, context
menus and tooltips. Views are configured through a view model and can be reused
inside `FibGrid`.

## Initialization

```swift
public override init(frame: CGRect)
public required init?(coder: NSCoder)
```

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `contentView` | `UIView` | Container for your subviews |
| `data` | `FibCoreViewModel?` | Current view model |
| `isSwipeOpen` | `Bool` | Whether swipe actions are shown |
| `haveSwipeAction` | `Bool` | Are swipe views configured |
| `isHighlighted` | `Bool` | Current highlight state |
| `canBeReordered` | `Bool` | Can the view be reordered in a collection |

`FibCoreView` has a customizable `Appearance` struct for theming and a shared
reuse manager used by default.

## Main Methods

```swift
open func configureUI()
open func configureAppearance()
open func configure(with data: ViewModelWithViewClass?)
open func sizeWith(_ targetSize: CGSize,
                  data: ViewModelWithViewClass?,
                  horizontal: UILayoutPriority,
                  vertical: UILayoutPriority) -> CGSize?
public func animateSwipe(direction: SwipeType,
                        isOpen: Bool,
                        swipeWidth: CGFloat?,
                        initialVel: CGFloat?,
                        completion: (() -> Void)?)
```

You can override these methods in subclasses to build your hierarchy and
customize behaviour. `prepareForReuse()` is called automatically before a view is
reused.

## Highlight Effects

```swift
public func setHighlighted(highlighted: Bool)
public func highlightSqueeze(highlighted: Bool)
public func highlightColoredBackground(highlighted: Bool, color: UIColor? = nil)
```

A view can respond to touches with squeeze or background color changes or you can
implement a custom effect.

## Swipe Actions

Use the view model to configure left and right swipe actions. The built in
`FibCoreSwipeCoordinator` handles the animations.

## Drag and Drop

Implement `onDragBegin()` and `onDragEnd()` or provide drag & drop closures in the
view model. The `canStartDragSession` flag determines if dragging is allowed.

## View Model Basics

`FibCoreViewModel` configures a `FibCoreView`. It supports size strategies, swipe
models, context menus, tooltips and more. Modifiers return `Self` so they can be
chained fluently.

```swift
let viewModel = FibCoreViewModel()
    .id("user_cell")
    .sizeStrategy(.width(.absolute(300), height: .selfSized))
    .interactive(true)
    .highlight(.squeeze)
    .onTap { view in
        print("Cell tapped")
    }
```

### Swipe Actions Example

```swift
let deleteAction = FibSwipeViewModel(...)
let archiveAction = FibSwipeViewModel(...)

let viewModel = FibCoreViewModel()
    .rightSwipeViews(
        mainSwipeView: deleteAction,
        secondSwipeView: archiveAction
    )
    .leftSwipeViews(
        mainSwipeView: FibSwipeViewModel(...)
    )
```

### Context Menu Example

```swift
let menu = FibContextMenu(...)
let viewModel = FibCoreViewModel()
    .contextMenu(menu)
    .fibContextMenu(
        ContextMenu(actions: [...]),
        isSecure: true
    )
```

## Notes

- All configuration methods return the view model itself for chaining.
- Size calculation is handled by `Size.Strategy`.
- Drag and drop, context menus and analytics callbacks are built in.
- Extend `FibCoreView` via subclasses or extensions to add behaviour.

