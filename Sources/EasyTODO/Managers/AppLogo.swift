import AppKit

enum AppLogo {
    private static let sourceImage: NSImage? = {
        guard let url = Bundle.module.url(forResource: "logo", withExtension: "png") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }()

    static var applicationImage: NSImage? {
        roundedImage(size: 512, cornerRadius: 112)
    }

    @MainActor
    static func applyApplicationIcon() {
        guard let image = applicationImage else { return }
        NSApplication.shared.applicationIconImage = image
    }

    private static func roundedImage(size: CGFloat, cornerRadius: CGFloat) -> NSImage? {
        guard let sourceImage else { return nil }

        let iconSize = NSSize(width: size, height: size)
        let rect = NSRect(origin: .zero, size: iconSize)
        let image = NSImage(size: iconSize)

        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSColor.clear.setFill()
        rect.fill()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).addClip()
        sourceImage.draw(
            in: rect,
            from: NSRect(origin: .zero, size: sourceImage.size),
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()
        image.unlockFocus()

        image.isTemplate = false
        return image
    }
}
