import PackageDescription
import Foundation

let package = Package(
    name: "CSyncSDK",
    dependencies: [
        .Package(url: "https://github.com/stephencelis/SQLite.swift.git", majorVersion: 0, minor: 11),
        .Package(url: "https://github.com/tidwall/SwiftWebSocket.git", majorVersion: 2, minor: 6)
    ],
    exclude: ["Tests/CSyncSDKTests/ObjCTests.m"]
)

// Copy test config file (macOS only)
let task = Process()
task.launchPath = "/usr/bin/env"
task.arguments = ["ditto", "Tests/CSyncSDKTests/Config.plist", ".build/debug/CSyncSDKPackageTests.xctest/Contents/Resources/"]
task.launch()
