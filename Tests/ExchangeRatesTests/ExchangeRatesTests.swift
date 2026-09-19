@testable import ExchangeRates
import Foundation
import Testing

@Suite struct ExchangeRatesTests {
    @Test func parsesASingleDay() throws {
        let json = Data(#"{"amount":1.0,"base":"AAA","date":"2020-03-13","rates":{"BBB":0.5}}"#.utf8)
        let rate = try FrankfurterRateProvider.parseDay(json, base: "AAA", quote: "BBB")
        #expect(rate.rate == Decimal(string: "0.5"))
        #expect(RateDay.string(from: rate.asOf) == "2020-03-13")
    }

    @Test func parsesASeriesOldestFirst() throws {
        let json = Data(#"{"base":"AAA","rates":{"2020-03-03":{"BBB":0.6},"2020-03-02":{"BBB":0.5}}}"#.utf8)
        let series = try FrankfurterRateProvider.parseSeries(json, base: "AAA", quote: "BBB")
        #expect(series.map { RateDay.string(from: $0.asOf) } == ["2020-03-02", "2020-03-03"])
    }

    @Test func missingQuoteIsUnavailable() {
        let json = Data(#"{"date":"2020-03-13","rates":{}}"#.utf8)
        #expect(throws: RateError.unavailable(base: "AAA", quote: "BBB")) {
            try FrankfurterRateProvider.parseDay(json, base: "AAA", quote: "BBB")
        }
    }

    @Test func historicRatesAreFetchedOnceAndSurviveARestart() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let day = try #require(RateDay.date(from: "2020-03-13"))
        let upstream = CountingProvider()
        let cache = CachedRateProvider(upstream: upstream, directory: directory)
        _ = try await cache.rate(base: "AAA", quote: "BBB", on: day)
        _ = try await cache.rate(base: "AAA", quote: "BBB", on: day)
        #expect(await upstream.calls == 1)

        let second = CountingProvider()
        let reopened = CachedRateProvider(upstream: second, directory: directory)
        _ = try await reopened.rate(base: "AAA", quote: "BBB", on: day)
        #expect(await second.calls == 0)
    }

    @Test func todaysRateIsNotStoredAsHistoric() async throws {
        let upstream = CountingProvider()
        let cache = CachedRateProvider(upstream: upstream, directory: nil)
        _ = try await cache.rate(base: "AAA", quote: "BBB", on: Date())
        _ = try await cache.rate(base: "AAA", quote: "BBB", on: Date())
        #expect(await upstream.calls == 2)
    }

    @Test func latestRateIsHeldInMemory() async throws {
        let upstream = CountingProvider()
        let cache = CachedRateProvider(upstream: upstream, directory: nil)
        _ = try await cache.rate(base: "AAA", quote: "BBB")
        _ = try await cache.rate(base: "AAA", quote: "BBB")
        #expect(await upstream.calls == 1)
    }

    @Test func manualRateInverts() async throws {
        let manual = ManualRateProvider(rates: [ExchangeRate(base: "AAA", quote: "BBB", rate: 4, asOf: Date(), source: "typed")])
        #expect(try await manual.rate(base: "BBB", quote: "AAA").rate == Decimal(string: "0.25"))
    }

    @Test func convertsWithBankersRounding() {
        let rate = ExchangeRate(base: "AAA", quote: "BBB", rate: Decimal(string: "0.5")!, asOf: Date(), source: "stub")
        #expect(CurrencyConverter.convert(milliunits: 5, using: rate) == 2)
        #expect(CurrencyConverter.convert(Decimal(string: "10.05")!, using: rate) == Decimal(string: "5.02"))
    }
}
