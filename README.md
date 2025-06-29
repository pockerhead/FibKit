# FibKit

FibKit is a Swift library that brings a SwiftUI‑like declarative syntax to UIKit. It allows you to build complex asynchronous user interfaces while retaining full control over UIKit components. The package supports iOS 13 and higher and can be integrated using Swift Package Manager.

For a Russian version of this document see [README.ru.md](README.ru.md).

## Features

- SwiftUI style interface code with function builders
- Views implemented entirely on top of UIKit
- Declarative sections and view models for building forms and lists
- Optional code generation templates for creating views and controllers
- Example iOS application showcasing the library in action

## Getting Started

The package can be added to your project using the Swift Package Manager. In your `Package.swift` add FibKit as a dependency:

```swift
.package(url: "https://github.com/pockerhead/FibKit.git", from: "0.1.0")
```

Then include `FibKit` in your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["FibKit"]
)
```

You can also open the **FibExampleApp** Xcode project located in `FibExampleApp/` to see a working example.

## Repository Structure

- `Sources/FibKit` – Main library source code
- `Sources/FibNavigation` – Navigation helpers
- `Tests/` – Unit tests
- `FibExampleApp/` – Example iOS application

## Documentation

For a hands‑on guide to building controllers with sections, see the
[FibViewController examples](Sources/FibKit/FibViewController/Doc.en.md).
The document covers static sections, dynamic lists and common modifiers.

See the [EmbedCollection guide](Sources/FibKit/RootViews/EmbedCollection/Doc.en.md)
for embedding horizontal rows inside a flow layout screen.

For details on the base reusable view see the
[FibCoreView guide](Sources/FibKit/RootViews/FibCore/FibCoreView/Doc.en.md).

## Building and Testing

To build the package from the command line run:

```bash
swift build
```

Run the test suite with:

```bash
swift test
```

## Contributing

Contributions are welcome! Feel free to open issues or pull requests if you encounter problems or have improvements.

