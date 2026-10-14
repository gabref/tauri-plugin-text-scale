// swift-tools-version: 5.5

import PackageDescription

let package = Package(
   name: "tauri-plugin-text-scale",
   platforms: [
      .iOS(.v15),
   ],
   products: [
      .library(
         name: "tauri-plugin-text-scale",
         type: .static,
         targets: ["tauri-plugin-text-scale"])
   ],
   dependencies: [
      .package(name: "Tauri", path: "../.tauri/tauri-api"),
      .package(name: "TextScaleCore", path: "TextScaleCore"),
   ],
   targets: [
      .target(
         name: "tauri-plugin-text-scale",
         dependencies: [
            .byName(name: "Tauri"),
            .product(name: "TextScaleCore", package: "TextScaleCore"),
         ],
         path: "Sources")
   ]
)
