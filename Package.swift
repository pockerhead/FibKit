// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "FibKit",
	platforms: [.iOS(.v14)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "FibKit",
			targets: ["FibKit"]
		),
	],
	dependencies: [
		
		.package(url: "https://github.com/apple/swift-collections.git", exact: "1.1.2"),
		.package(url: "https://github.com/Miraion/Threading", .upToNextMajor(from: "1.0.1")),
		.package(url: "https://github.com/efremidze/VisualEffectView", .upToNextMajor(from: "6.0.0")),
		.package(url: "https://github.com/Juanpe/SkeletonView", .upToNextMajor(from: "1.26.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "FibKit",
			dependencies: [
				"Threading",
				"VisualEffectView",
				"SkeletonView",
				.product(name: "Collections", package: "swift-collections")
			]
		)
	]
)
