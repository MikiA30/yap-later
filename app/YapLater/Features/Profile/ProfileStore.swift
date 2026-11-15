import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The user's name and picture. Both are kept on this device only: the name in the app's settings,
/// the picture as a file beside the models. There is no account behind this.
@MainActor
@Observable
final class ProfileStore {
    var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "profile.name") }
    }
    private(set) var photo: Image?
    /// Changes whenever the picture does, so views can animate the swap.
    private(set) var photoVersion = 0

    private static var photoFile: URL? { LocalAssets.root?.appendingPathComponent("profile-photo.jpg") }

    init() {
        name = UserDefaults.standard.string(forKey: "profile.name") ?? ""
        if let file = Self.photoFile, let data = try? Data(contentsOf: file) { photo = Self.image(from: data) }
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
        guard let file = Self.photoFile, let small = Self.scaledJPEG(from: data) else { return }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? small.write(to: file, options: .atomic)
        photo = Self.image(from: small)
        photoVersion += 1
    }

    func removePhoto() {
        if let file = Self.photoFile { try? FileManager.default.removeItem(at: file) }
        photo = nil
        photoVersion += 1
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
