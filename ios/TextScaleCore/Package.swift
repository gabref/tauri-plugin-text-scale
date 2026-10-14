// swift-tools-version: 5.5

import PackageDescription

// The text scale logic, without UIKit or the Tauri package, so that `swift test` runs it
// on macOS.
let package = Package(
   name: "TextScaleCore",
   platforms: [
      .iOS(.v15),
      .macOS(.v10_13),
   ],
   products: [
      .library(
         name: "TextScaleCore",
         targets: ["TextScaleCore"])
   ],
   targets: [
      .target(
         name: "TextScaleCore",
         path: "Sources/TextScaleCore"),
      .testTarget(
         name: "TextScaleCoreTests",
         dependencies: ["TextScaleCore"],
         path: "Tests/TextScaleCoreTests"),
   ]
)
