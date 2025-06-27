# FibKit

FibKit is a Swift library that brings a SwiftUI‑like declarative syntax to UIKit. It allows you to build complex asynchronous user interfaces while retaining full control over UIKit components. The package supports iOS 13 and higher and can be integrated using Swift Package Manager.

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

## Building and Testing

To build the package from the command line run:

```bash
swift build
```

Run the test suite with:

```bash
swift test
```

## Documentation

Additional usage examples for `FibViewController`, including static and dynamic
sections, can be found in
[Sources/FibKit/FibViewController/Doc.md](Sources/FibKit/FibViewController/Doc.md).

## Contributing

Contributions are welcome! Feel free to open issues or pull requests if you encounter problems or have improvements.

