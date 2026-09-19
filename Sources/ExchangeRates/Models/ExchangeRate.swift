import Foundation

/// One unit of `base` buys `rate` units of `quote`, as of `asOf`, according to `source`.
/// A rate is never used without its date and source being shown to the user.
public struct ExchangeRate: Sendable, Equatable, Codable {
    public let base: String
    public let quote: String
    public let rate: Decimal
    public let asOf: Date
    public let source: String

    public init(base: String, quote: String, rate: Decimal, asOf: Date, source: String) {
        self.base = base
        self.quote = quote
        self.rate = rate
        self.asOf = asOf
        self.source = source
    }

    public var inverted: ExchangeRate {
        ExchangeRate(base: quote, quote: base, rate: rate == 0 ? 0 : 1 / rate, asOf: asOf, source: source)
    }
}
