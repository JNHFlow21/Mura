// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mura",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MemoryWallCore", targets: ["MemoryWallCore"]),
        .library(name: "MemoryWallWorkspace", targets: ["MemoryWallWorkspace"]),
        .library(name: "MemoryWallRenderer", targets: ["MemoryWallRenderer"]),
        .library(name: "MemoryWallWallpaper", targets: ["MemoryWallWallpaper"]),
        .library(name: "MemoryWallEditorBridge", targets: ["MemoryWallEditorBridge"]),
        .library(name: "MemoryWallAgentTools", targets: ["MemoryWallAgentTools"]),
        .executable(name: "Mura", targets: ["DesktopMemoryWallApp"]),
        .executable(name: "dmwctl", targets: ["dmwctl"])
    ],
    targets: [
        .target(name: "MemoryWallCore"),
        .target(name: "MemoryWallWorkspace", dependencies: ["MemoryWallCore"]),
        .target(name: "MemoryWallRenderer", dependencies: ["MemoryWallCore", "MemoryWallWorkspace"]),
        .target(name: "MemoryWallWallpaper", dependencies: ["MemoryWallCore", "MemoryWallWorkspace", "MemoryWallRenderer"]),
        .target(name: "MemoryWallEditorBridge", dependencies: ["MemoryWallCore", "MemoryWallWorkspace"], resources: [.process("Resources")]),
        .target(name: "MemoryWallAgentTools", dependencies: ["MemoryWallCore", "MemoryWallWorkspace", "MemoryWallRenderer", "MemoryWallWallpaper", "MemoryWallEditorBridge"]),
        .executableTarget(name: "DesktopMemoryWallApp", dependencies: ["MemoryWallCore", "MemoryWallWorkspace", "MemoryWallRenderer", "MemoryWallWallpaper", "MemoryWallEditorBridge", "MemoryWallAgentTools"], path: "App/DesktopMemoryWallApp", resources: [.process("Resources")]),
        .executableTarget(name: "dmwctl", dependencies: ["MemoryWallAgentTools"]),
        .testTarget(name: "MemoryWallCoreTests", dependencies: ["MemoryWallCore"]),
        .testTarget(name: "MemoryWallWorkspaceTests", dependencies: ["MemoryWallWorkspace", "MemoryWallCore"]),
        .testTarget(name: "MemoryWallRendererTests", dependencies: ["MemoryWallRenderer", "MemoryWallWorkspace", "MemoryWallCore"]),
        .testTarget(name: "MemoryWallWallpaperTests", dependencies: ["MemoryWallWallpaper", "MemoryWallRenderer", "MemoryWallWorkspace", "MemoryWallCore"]),
        .testTarget(name: "MemoryWallEditorBridgeTests", dependencies: ["MemoryWallEditorBridge", "MemoryWallCore"]),
        .testTarget(name: "MemoryWallAgentToolsTests", dependencies: ["MemoryWallAgentTools", "MemoryWallWorkspace", "MemoryWallCore"]),
        .testTarget(name: "dmwctlTests", dependencies: ["MemoryWallAgentTools"])
    ]
)
