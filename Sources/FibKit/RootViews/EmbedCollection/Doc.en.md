# EmbedCollection

`EmbedCollection` hosts its own `FibGrid` so you can embed a horizontal or vertical list inside another grid. This is handy when you need a row of items on a screen that uses a vertical `FlowLayout`.

## Row Sections in a Flow Layout Screen

1. Build a provider for the inner row and apply `rowLayout(spacing:)` to arrange items horizontally.

```swift
let rowProvider = ViewModelSection {
    (0..<10).map { index in
        MyRowView.ViewModel(text: "\(index)")
    }
}
.rowLayout(spacing: 8)
```

2. Pass the provider to `EmbedCollection.ViewModel` and set the desired row height.

```swift
let row = EmbedCollection.ViewModel(provider: rowProvider)
    .height(100)
```

3. Include the row in your controller's `SectionStack` configured with `flowLayout` for vertical scrolling.

```swift
override var body: SectionProtocol? {
    SectionStack {
        ViewModelSection { row }
        // other sections …
    }
    .flowLayout(spacing: 16)
}
```

`EmbedCollection` can also serve as a screen header or footer because its view model conforms to `FibViewHeaderViewModel`.

## ViewModel Modifiers

`EmbedCollection.ViewModel` exposes a number of modifiers to configure behavior and appearance. Below is a quick reference.

```swift
EmbedCollection.ViewModel(provider: rowProvider)
    // Collection scrolling direction (.horizontal by default)
    .scrollDirection(.vertical)
    // Height used when scrolling horizontally
    .height(120)
    // Custom size for vertical lists
    .size(CGSize(width: 200, height: 300))
    // Add paging with an optional start page
    .paging(true, selectedPage: 0)
    // Plug in custom page indicators
    .pagerView(myPager)
    .pageControlView(myPageControl)
    // Disable bounce or scrolling
    .bounces(false)
    .scrollEnabled(false)
    // Appearance
    .backgroundColor(.systemBackground)
    .clipsToBounds(true)
```

Other helpful modifiers include:

- `id(_:)` – assign a stable identifier
- `offset(_:)` – additional offset for layout adjustments
- `selectedPage(_:)` – scroll to a specific page
- `onAppear(_:)` / `onDissappear(_:)` – callbacks when the view is added or removed
- `scrollDidScroll(_:)` / `scrollDidEnd(_:)` – observe scroll events
- `needAnimation(_:)` – toggle initial scroll animation
- `allowedStretchDirections(_:)` and `atTop(_:)` – configure stretch behavior when used as a header

Use these modifiers to fine tune the embedded collection for your screen.
