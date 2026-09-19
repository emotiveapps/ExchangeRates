import ExchangeRates
import Foundation

actor CountingProvider: ExchangeRateProvider {
    private(set) var calls = 0

    func rate(base: String, quote: String) async throws -> ExchangeRate {
        calls += 1
        return ExchangeRate(base: base, quote: quote, rate: 2, asOf: Date(), source: "stub")
    }

    func rate(base: String, quote: String, on date: Date) async throws -> ExchangeRate {
        calls += 1
        return ExchangeRate(base: base, quote: quote, rate: 2, asOf: date, source: "stub")
    }

    func rates(base: String, quote: String, from start: Date, through end: Date) async throws -> [ExchangeRate] {
        calls += 1
        return [ExchangeRate(base: base, quote: quote, rate: 2, asOf: start, source: "stub")]
    }
}
