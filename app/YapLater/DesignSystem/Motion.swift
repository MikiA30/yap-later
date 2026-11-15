import SwiftUI

/// The app's one motion vocabulary. Views use these, never ad-hoc curves. Tuned on device in T017/T018.
enum Motion {
    /// Taps, toggles, small state.
    static let quick = Animation.snappy(duration: 0.22)
    /// Layout, cards, screen content.
    static let move = Animation.smooth(duration: 0.38)
    /// A card or banner arriving.
    static let present = Animation.spring(duration: 0.5, bounce: 0.18)
    /// Confirmed success only.
    static let delight = Animation.bouncy(duration: 0.45, extraBounce: 0.08)

    static func stagger(_ index: Int, step: Double = 0.035, cap: Int = 6) -> Double {
        Double(min(index, cap)) * step
    }
}
