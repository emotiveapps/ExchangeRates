// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ExchangeRates",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10)],
    products: [.library(name: "ExchangeRates", targets: ["ExchangeRates"])],
    targets: [
        .target(name: "ExchangeRates"),
        .testTarget(name: "ExchangeRatesTests", dependencies: ["ExchangeRates"])
    ],
    swiftLanguageModes: [.v6]
)
