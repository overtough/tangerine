// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "TangerineReplica",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TangerineReplica",
            targets: ["TangerineReplicaApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TangerineReplicaApp"
        )
    ]
)
