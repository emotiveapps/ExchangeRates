import Foundation

public protocol ExchangeRateProvider: Sendable {
    /// The most recent rate: one unit of `base` in `quote`.
    func rate(base: String, quote: String) async throws -> ExchangeRate

    /// The rate in force on `date`. Weekends and holidays resolve to the prior
    /// business day; the returned `asOf` says which day was actually used.
    func rate(base: String, quote: String, on date: Date) async throws -> ExchangeRate

    /// One rate per business day in the range, oldest first.
    func rates(base: String, quote: String, from start: Date, through end: Date) async throws -> [ExchangeRate]
}
