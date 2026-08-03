// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MenubarLLM",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MenubarLLM", targets: ["MenubarLLM"])
    ],
    targets: [
        .executableTarget(name: "MenubarLLM")
    ]
)
