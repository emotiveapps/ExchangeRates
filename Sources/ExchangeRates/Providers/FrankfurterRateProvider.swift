import Foundation

/// Daily European Central Bank reference rates from the free, keyless
/// Frankfurter service, current and historic (back to 1999). Reference rates
/// are mid-market: a bank will give less. Only currency codes and dates are
/// sent; no financial data leaves the device.
public struct FrankfurterRateProvider: ExchangeRateProvider {
    public static let sourceName = "ECB reference rate"

    private let session: URLSession
    private let root: URL

    public init(session: URLSession = .shared, root: URL = URL(string: "https://api.frankfurter.dev/v1")!) {
        self.session = session
        self.root = root
    }

    private struct DayPayload: Decodable {
        let date: String
        let rates: [String: Double]
    }

    private struct SeriesPayload: Decodable {
        let rates: [String: [String: Double]]
    }

    public func rate(base: String, quote: String) async throws -> ExchangeRate {
        try Self.parseDay(try await fetch("latest", base: base, quote: quote), base: base, quote: quote)
    }

    public func rate(base: String, quote: String, on date: Date) async throws -> ExchangeRate {
        try Self.parseDay(try await fetch(RateDay.string(from: date), base: base, quote: quote), base: base, quote: quote)
    }

    public func rates(base: String, quote: String, from start: Date, through end: Date) async throws -> [ExchangeRate] {
        let path = "\(RateDay.string(from: start))..\(RateDay.string(from: end))"
        return try Self.parseSeries(try await fetch(path, base: base, quote: quote), base: base, quote: quote)
    }

    private func fetch(_ path: String, base: String, quote: String) async throws -> Data {
        let url = root.appendingPathComponent(path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw RateError.badResponse }
        components.queryItems = [URLQueryItem(name: "base", value: base), URLQueryItem(name: "symbols", value: quote)]
        guard let full = components.url else { throw RateError.badResponse }
        let (data, response) = try await session.data(from: full)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw RateError.unavailable(base: base, quote: quote) }
        return data
    }

    static func parseDay(_ data: Data, base: String, quote: String) throws -> ExchangeRate {
        let payload = try JSONDecoder().decode(DayPayload.self, from: data)
        guard let value = payload.rates[quote] else { throw RateError.unavailable(base: base, quote: quote) }
        return try make(value, day: payload.date, base: base, quote: quote)
    }

    static func parseSeries(_ data: Data, base: String, quote: String) throws -> [ExchangeRate] {
        let payload = try JSONDecoder().decode(SeriesPayload.self, from: data)
        return try payload.rates.keys.sorted().compactMap { day in
            guard let value = payload.rates[day]?[quote] else { return nil }
            return try make(value, day: day, base: base, quote: quote)
        }
    }

    private static func make(_ value: Double, day: String, base: String, quote: String) throws -> ExchangeRate {
        guard value > 0 else { throw RateError.unavailable(base: base, quote: quote) }
        guard let date = RateDay.date(from: day) else { throw RateError.badResponse }
        return ExchangeRate(base: base, quote: quote, rate: Decimal(string: String(value)) ?? Decimal(value), asOf: date, source: sourceName)
    }
}
