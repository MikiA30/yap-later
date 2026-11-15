import SwiftUI

/// The page behind everything: paper with a warm wash at the top and a faint dot grid that fades out
/// down the screen, like the corner of an engineer's notebook. It gives cards something to sit on.
struct AppBackdrop: View {
    var body: some View {
        ZStack {
            Theme.paper
            LinearGradient(colors: [Theme.wash, Theme.wash.opacity(0)], startPoint: .top, endPoint: .center)
            DotGrid()
                .foregroundStyle(Theme.ink.opacity(0.10))
                .mask(LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Evenly spaced small dots. Drawn once; nothing here animates.
struct DotGrid: View {
    var spacing: CGFloat = 22
    var radius: CGFloat = 1.1

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    x += spacing
                }
                y += spacing
            }
            context.fill(path, with: .foreground)
        }
    }
}
