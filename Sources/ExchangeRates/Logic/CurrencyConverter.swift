import Foundation

public enum CurrencyConverter {
    /// Converts whole minor units (cents, or YNAB milliunits) of `rate.base` into the same units of `rate.quote`,
    /// rounded half-even to the nearest unit.
    public static func convert(milliunits: Int, using rate: ExchangeRate) -> Int {
        var product = Decimal(milliunits) * rate.rate
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .bankers)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// Converts a decimal amount of `rate.base` into `rate.quote`, rounded
    /// half-even to `scale` places (2 for cents).
    public static func convert(_ amount: Decimal, using rate: ExchangeRate, scale: Int = 2) -> Decimal {
        var product = amount * rate.rate
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, scale, .bankers)
        return rounded
    }

    /// Receiving units per sending unit, fees included.
    public static func impliedRate(sent: Int, received: Int) -> Decimal {
        sent == 0 ? 0 : Decimal(received) / Decimal(sent)
    }
}
