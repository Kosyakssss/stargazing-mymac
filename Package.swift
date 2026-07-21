// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StargazingMyMac",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "StargazingCore", targets: ["StargazingCore"]),
        .executable(name: "StargazingMyMacApp", targets: ["StargazingMyMacApp"]),
        .executable(name: "stargazing-mymac", targets: ["stargazing-mymac"]),
        .executable(name: "stargazing-selftest", targets: ["stargazing-selftest"]),
    ],
    targets: [
        .target(name: "StargazingCore"),
        .executableTarget(name: "StargazingMyMacApp", dependencies: ["StargazingCore"]),
        .executableTarget(name: "stargazing-mymac", dependencies: ["StargazingCore"]),
        .executableTarget(name: "stargazing-selftest", dependencies: ["StargazingCore"]),
    ]
)
