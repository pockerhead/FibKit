// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "FibKit",
	platforms: [.iOS(.v13)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "FibKit",
			targets: ["FibKit"]
		),
	],
	dependencies: [
		.package(
			url: "https://ditlogger:ZqTixVPcM-Y3@git24.ru/scm/staff/ditlogger.git",
			branch: "master"
		),
		.package(url: "https://github.com/Miraion/Threading", .upToNextMajor(from: "1.0.0")),
		.package(url: "https://github.com/efremidze/VisualEffectView", .upToNextMajor(from: "4.0.0")),
		.package(url: "https://github.com/hackiftekhar/IQKeyboardManager", .upToNextMajor(from: "6.0.0")),
		.package(url: "https://github.com/Juanpe/SkeletonView", .upToNextMajor(from: "1.0.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "FibKit",
			dependencies: [
				.product(name: "DITLogger", package: "ditlogger"),
				"Threading",
				"VisualEffectView",
				.product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager"),
				"SkeletonView"
			]
		)
	]
)
