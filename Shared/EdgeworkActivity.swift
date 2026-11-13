import ActivityKit
import Foundation

/// Shared between the app and the widget extension: what the Lock Screen and Dynamic Island show.
struct EdgeworkActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Kind: String, Codable, Hashable { case workout, rest, run }
        var kind: Kind
        var title: String
        var detail: String
        /// Counts down to this when set (timed sets and rest).
        var timerEnd: Date?
        /// Counts up from this when set (runs, rep-based sets).
        var timerStart: Date?
        var paused: Bool = false
        var pausedText: String = ""
        var progress: Double = 0
        /// Extra big number, e.g. distance on a run.
        var value: String = ""
        var unit: String = ""
    }

    var name: String
    /// Hex accent so hockey stays ice blue and track stays red.
    var accent: UInt32
}
