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

## Controller Configuration

`FibViewController` can be customized with the `Configuration` struct which has two parts:

- `viewConfiguration` – appearance of the root `FibControllerRootView` such as background colors, shutter behaviour and keyboard handling.
- `navigationConfiguration` – content of the navigation bar including titles and search options.

### `viewConfiguration` fields

- `viewBackgroundColor` – main background color.
- `shutterType` – shutter style (`.default` or `.rounded`).
- `shutterBackground` – color for the `.default` shutter.
- `roundedShutterBackground` – color for the `.rounded` shutter.
- `shutterTopInset` – additional space above the shutter.
- `backgroundView` – closure returning a custom background view.
- `backgroundViewInsets` – insets for that background view.
- `headerBackgroundViewColor` – header background color.
- `headerBackgroundEffectView` – effect view used behind the header.
- `shutterShadowClosure` – configure a custom shadow for the shutter.
- `topInsetStrategy` – how the top inset is calculated (`safeArea`, `statusBar`, `top`, `custom`).
- `needFooterKeyboardSticks` – whether the footer sticks to the keyboard.
- `footerBackgroundViewColor` – footer background color.

### `navigationConfiguration` fields

- `titleViewModel` – view model of the navigation title.
- `largeTitleViewModel` – view model for the large title.
- `searchContext` – search bar options:
  - `isForceActive` – keep the search bar always active.
  - `placeholder` – placeholder text.
  - `hideWhenScrolling` – hide the search bar when scrolling.
  - `onSearchResults` – callback for text changes.
  - `onSearchBegin` / `onSearchEnd` – callbacks on begin/end editing.
  - `onSearchButtonClicked` – callback when the Search button is pressed.
  - `searchBarAppearance` – font, icon and text color of the search bar.

You can modify `FibViewController.defaultConfiguration` once on startup or override it per controller. To apply changes at runtime set `storedConfiguration` and call `reload()`.
