import Foundation

/// Rates the user typed in: the offline fallback, and the override when their
/// bank's rate is the one that matters. A manual rate applies to every date.
public struct ManualRateProvider: ExchangeRateProvider {
    private let table: [String: ExchangeRate]

    public init(rates: [ExchangeRate]) {
        self.table = Dictionary(rates.map { ("\($0.base)/\($0.quote)", $0) }, uniquingKeysWith: { _, last in last })
    }

    public func rate(base: String, quote: String) async throws -> ExchangeRate {
        if let direct = table["\(base)/\(quote)"] { return direct }
        if let reverse = table["\(quote)/\(base)"] { return reverse.inverted }
        throw RateError.unavailable(base: base, quote: quote)
    }

    public func rate(base: String, quote: String, on date: Date) async throws -> ExchangeRate {
        try await rate(base: base, quote: quote)
    }

    public func rates(base: String, quote: String, from start: Date, through end: Date) async throws -> [ExchangeRate] {
        [try await rate(base: base, quote: quote)]
    }
}
