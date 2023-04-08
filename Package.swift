// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-tableview",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "TableView",
            targets: ["TableView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", "2.0.1" ..< "3.0.0"),
    ],
    targets: [
        .target(
            name: "TableView",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift")
            ]
        ),
        .testTarget(
            name: "TableViewTests",
            dependencies: [
                "TableView",
                .product(name: "Log4swift", package: "idd-log4-swift")
            ]
        )
    ]
)
