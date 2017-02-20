import PackageDescription

let package = Package(
    name: "CSyncSwift",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/tidwall/SwiftWebSocket.git",
                 majorVersion: 2),
        .Package(url: "https://github.com/stephencelis/SQLite.swift.git",
                 majorVersion: 0),
    ]
)