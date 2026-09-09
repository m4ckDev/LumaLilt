// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LumaLiltCore",
    products: [.library(name: "LumaLiltCore", targets: ["LumaLiltCore"])],
    targets: [
        .target(name: "LumaLiltCore", path: "LumaLilt/Core"),
        .testTarget(name: "LumaLiltCoreTests", dependencies: ["LumaLiltCore"], path: "Tests")
    ]
)
