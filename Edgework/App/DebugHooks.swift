import Foundation

/// Launch arguments used by the CI screenshot job (`-showScreen study`, `-demoData YES`…).
/// Debug builds only: in release builds they always read as unset.
enum DebugHooks {
    static func string(_ key: String) -> String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: key)
        #else
        nil
        #endif
    }

    static func bool(_ key: String) -> Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: key)
        #else
        false
        #endif
    }

    static func integer(_ key: String) -> Int {
        #if DEBUG
        UserDefaults.standard.integer(forKey: key)
        #else
        0
        #endif
    }
}
