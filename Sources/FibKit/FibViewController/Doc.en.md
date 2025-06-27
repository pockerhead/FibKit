# FibViewController Examples

`FibViewController` lets you build UIKit screens using a SwiftUI-like sectioned layout. This document provides basic usage patterns and best practices.

## Basic Structure

```swift
class MyViewController: FibViewController {
    override var body: SectionProtocol? {
        SectionStack {
            // Interface sections
        }
    }
}
```

`body` returns the root section, commonly a `SectionStack` that combines several child sections.

## Static Sections

```swift
override var body: SectionProtocol? {
    SectionStack {
        ViewModelSection {
            MyFirstView.ViewModel(text: "First section")
        }
        ViewModelSection {
            MySecondView.ViewModel(text: "Second section")
        }
        .header(MyHeaderViewModel())
    }
}
```

Use `.header` to attach a header view model to a section.

## Dynamic Lists

```swift
@Reloadable var items = ["One", "Two", "Three"]

override var body: SectionProtocol? {
    SectionStack {
        ForEachSection(data: items) { item in
            MyItemView.ViewModel(text: item)
        }
    }
}
```

When `items` change the controller automatically reloads thanks to the `@Reloadable` property wrapper.

## Composing Sections

Sections can be nested to build complex layouts:

```swift
override var body: SectionProtocol? {
    SectionStack {
        ViewModelSection {
            MyHeaderView.ViewModel()
        }
        SectionStack {
            ForEachSection(data: 0..<5) { index in
                MyRowView.ViewModel(number: index)
            }
        }
    }
}
```

## Useful Modifiers

Sections support modifiers for layout, animations and interactions.

```swift
ViewModelSection {
    MyView.ViewModel()
}
// Content insets
.inset(by: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
// Element arrangement
.rowLayout(spacing: 12)
// Background view model
.background(FibSectionBackgroundView.ViewModel(color: .secondarySystemBackground))
// Stable identifier
.id("main_section")
// Disable sticky headers
.isSticky(false)
// Tap handler
.tapHandler { context in
    print("tapped", context.indexPath)
}
// Called after reload completes
.didReload {
    print("reload finished")
}
```

- `inset(by:)` controls inner padding.
- `rowLayout(spacing:)` or `flowLayout(spacing:)` define item arrangement.
- `background(_:)` adds a background to the section.
- `id(_:)` is needed for smooth animations during updates.
- `isSticky(_:)` toggles header sticking behavior.
- `tapHandler(_:)` and `didReload` let you react to user actions and reload completion.

## Manual Data Reloading

When you need to replace all sections, use `storedBody`:

```swift
func reloadContent() {
    storedBody = SectionStack {
        ViewModelSection {
            MyLoadingView.ViewModel()
        }
    }
    reload(animated: true)
}
```

`FibViewController` gives you a flexible way to compose screens using sections. Use `SectionStack` for grouping, `ForEachSection` for dynamic data and `storedBody` when you need to overwrite the entire layout.
