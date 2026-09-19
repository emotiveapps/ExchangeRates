# ExchangeRates

Current and historic currency exchange rates for Swift apps.

- `FrankfurterRateProvider`: free, keyless European Central Bank reference rates, latest, on a date, or a date range. Weekends and holidays resolve to the prior business day, and every `ExchangeRate` carries the day actually used.
- `CachedRateProvider`: historic rates never change, so they are stored on disk once; the latest rate is held in memory for a few hours.
- `ManualRateProvider`: rates the user typed in.
- `CurrencyConverter`: banker's rounding for minor units or decimals.

```swift
let rates = CachedRateProvider(upstream: FrankfurterRateProvider(), directory: cachesFolder)
let rate = try await rates.rate(base: "CAD", quote: "USD", on: purchaseDate)
let usd = CurrencyConverter.convert(cadAmount, using: rate)
```
