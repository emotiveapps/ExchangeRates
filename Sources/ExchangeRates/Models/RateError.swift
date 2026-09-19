import Foundation

public enum RateError: LocalizedError, Equatable {
    case unavailable(base: String, quote: String)
    case badResponse

    public var errorDescription: String? {
        switch self {
        case let .unavailable(base, quote): "No exchange rate available for \(base) to \(quote)."
        case .badResponse: "The exchange-rate service sent something unexpected."
        }
    }
}
