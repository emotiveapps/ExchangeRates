import Foundation

/// Wraps another provider. Historic rates never change, so they are kept on
/// disk forever; the latest rate is kept in memory for a few hours.
public actor CachedRateProvider: ExchangeRateProvider {
    private let upstream: any ExchangeRateProvider
    private let fileURL: URL?
    private let latestLifetime: TimeInterval
    private var settled: [String: ExchangeRate]
    private var latest: [String: (rate: ExchangeRate, fetched: Date)] = [:]

    /// - Parameter directory: where `exchange-rates.json` lives; nil keeps the cache in memory only.
    public init(upstream: any ExchangeRateProvider, directory: URL?, latestLifetime: TimeInterval = 6 * 3600) {
        self.upstream = upstream
        self.latestLifetime = latestLifetime
        self.fileURL = directory?.appendingPathComponent("exchange-rates.json")
        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let stored = try? JSONDecoder().decode([String: ExchangeRate].self, from: data) {
            self.settled = stored
        } else {
            self.settled = [:]
        }
    }

    public func rate(base: String, quote: String) async throws -> ExchangeRate {
        let key = "\(base)/\(quote)"
        if let hit = latest[key], Date().timeIntervalSince(hit.fetched) < latestLifetime { return hit.rate }
        let fresh = try await upstream.rate(base: base, quote: quote)
        latest[key] = (fresh, Date())
        return fresh
    }

    public func rate(base: String, quote: String, on date: Date) async throws -> ExchangeRate {
        let key = Self.key(base, quote, date)
        if let hit = settled[key] { return hit }
        let fresh = try await upstream.rate(base: base, quote: quote, on: date)
        if RateDay.isSettled(date) {
            settled[key] = fresh
            persist()
        }
        return fresh
    }

    public func rates(base: String, quote: String, from start: Date, through end: Date) async throws -> [ExchangeRate] {
        let series = try await upstream.rates(base: base, quote: quote, from: start, through: end)
        for entry in series where RateDay.isSettled(entry.asOf) {
            settled[Self.key(base, quote, entry.asOf)] = entry
        }
        persist()
        return series
    }

    private static func key(_ base: String, _ quote: String, _ date: Date) -> String {
        "\(base)/\(quote)/\(RateDay.string(from: date))"
    }

    private func persist() {
        guard let fileURL else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(settled).write(to: fileURL, options: .atomic)
    }
}
