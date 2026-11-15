import SwiftUI
import ImageIO
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The user's name and picture: the name in the app's settings, the picture as a file beside the models.
/// There is no account behind this. They leave the device only when the user taps Sync, and then only
/// over Bluetooth to their own other device.
@MainActor
@Observable
final class ProfileStore {
    var name: String {
        didSet {
            guard name != oldValue else { return }
            defaults.set(name, forKey: "profile.name")
            if !adopting { touch() }
        }
    }
    private(set) var photo: Image?
    /// Changes whenever the picture does, so views can animate the swap.
    private(set) var photoVersion = 0

    /// When the name or picture was last changed by hand on either device. Decides which side wins a sync.
    private(set) var changedAt: Date

    private let defaults: UserDefaults
    private let photoFile: URL?
    private var adopting = false

    nonisolated static var defaultPhotoFile: URL? { LocalAssets.root?.appendingPathComponent("profile-photo.jpg") }

    init(defaults: UserDefaults = .standard, photoFile: URL? = ProfileStore.defaultPhotoFile) {
        self.defaults = defaults
        self.photoFile = photoFile
        name = defaults.string(forKey: "profile.name") ?? ""
        changedAt = defaults.object(forKey: "profile.changedAt") as? Date ?? .distantPast
        if let photoFile, let data = try? Data(contentsOf: photoFile) { photo = Self.image(from: data) }
    }

    private func touch() {
        changedAt = .now
        defaults.set(changedAt, forKey: "profile.changedAt")
    }

    // MARK: Sync with the user's other device

    /// The name and a small copy of the picture, sized to travel over Bluetooth in a few seconds.
    var forSync: SyncSnapshot.Profile {
        let small = photoFile.flatMap { try? Data(contentsOf: $0) }
            .flatMap { Self.smallJPEG(from: $0, maxPixel: 360, quality: 0.72) }
        return SyncSnapshot.Profile(name: name, photo: small, changedAt: changedAt)
    }

    /// Takes the name and picture that arrived from the other device. The caller has already decided
    /// that they are newer. A picture that is too large or is not an image is ignored.
    func adopt(_ other: SyncSnapshot.Profile) {
        adopting = true
        name = String(other.name.prefix(80))
        adopting = false
        if let data = other.photo, data.count <= 600_000, let image = Self.image(from: data), let photoFile {
            try? FileManager.default.createDirectory(at: photoFile.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: photoFile, options: .atomic)
            photo = image
        } else if other.photo == nil {
            if let photoFile { try? FileManager.default.removeItem(at: photoFile) }
            photo = nil
        }
        photoVersion += 1
        changedAt = other.changedAt
        defaults.set(changedAt, forKey: "profile.changedAt")
    }

    private static func smallJPEG(from data: Data, maxPixel: Int, quality: Double) -> Data? {
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: maxPixel]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    var firstName: String? {
        name.split(separator: " ").first.map(String.init)
    }

    var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return letters.joined()
    }

    /// Stores a newly chosen picture, scaled down to what the screen needs.
    func setPhoto(_ data: Data) {
        guard let file = photoFile, let small = Self.scaledJPEG(from: data) else { return }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? small.write(to: file, options: .atomic)
        photo = Self.image(from: small)
        photoVersion += 1
        touch()
    }

    func removePhoto() {
        if let file = photoFile { try? FileManager.default.removeItem(at: file) }
        photo = nil
        photoVersion += 1
        touch()
    }

    private static func image(from data: Data) -> Image? {
        #if canImport(UIKit)
        UIImage(data: data).map { Image(uiImage: $0) }
        #else
        NSImage(data: data).map { Image(nsImage: $0) }
        #endif
    }

    private static func scaledJPEG(from data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let side: CGFloat = 600
        let scale = max(side / image.size.width, side / image.size.height, 0.0001)
        let size = CGSize(width: image.size.width * min(scale, 1), height: image.size.height * min(scale, 1))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            .jpegData(compressionQuality: 0.85)
        #else
        guard let image = NSImage(data: data), let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
        #endif
    }
}

/// The user's picture in a circle, or their initials, or a plain figure when nothing is set.
struct Avatar: View {
    let profile: ProfileStore
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle().fill(Theme.brand)
            if let photo = profile.photo {
                photo.resizable().scaledToFill()
            } else if !profile.initials.isEmpty {
                Text(profile.initials)
                    .font(.system(size: size * 0.38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.44, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(Theme.card, lineWidth: max(2, size * 0.04)) }
    }
}
