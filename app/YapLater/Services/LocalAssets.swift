import Foundation

/// Where the model files copied onto the device ahead of time live.
/// iPhone: the app's Documents folder. Mac: `~/Library/Application Support/YapLater`.
enum LocalAssets {
    static var root: URL? {
        #if os(macOS)
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("YapLater", isDirectory: true)
        #else
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #endif
    }
}
