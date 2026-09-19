import Foundation

/// Calendar days as the rate services see them: `yyyy-MM-dd` in UTC.
public enum RateDay {
    private static let style = Date.ISO8601FormatStyle(timeZone: .gmt).year().month().day()

    public static func string(from date: Date) -> String {
        date.formatted(style)
    }

    public static func date(from string: String) -> Date? {
        try? style.parse(string)
    }

    /// True when `date` falls on a UTC day before today, so its rate can never change.
    public static func isSettled(_ date: Date, now: Date = Date()) -> Bool {
        string(from: date) < string(from: now)
    }
}
