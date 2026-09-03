import AppKit
import SwiftUI

// MARK: - 奶茶宠物图案

struct MilkTeaArtwork: View {
    let milkTea: MilkTea

    var body: some View {
        if let image = MilkTeaImageCache.shared.image(named: milkTea.artworkAssetName) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .scaleEffect(milkTea.displayConfiguration.scale)
                .offset(
                    x: milkTea.displayConfiguration.offsetX,
                    y: milkTea.displayConfiguration.offsetY
                )
        } else {
            Color.clear
        }
    }
}

private final class MilkTeaImageCache {
    static let shared = MilkTeaImageCache()

    private var images: [String: NSImage] = [:]

    func image(named name: String) -> NSImage? {
        if let image = images[name] {
            return image
        }

        guard let url = Bundle.module.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        images[name] = image
        return image
    }
}

// MARK: - 动效：悬停时摇一摇

private struct HoverShakeEffect: GeometryEffect {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let phase = progress - floor(progress)
        let envelope = sin(phase * .pi)
        let angle = sin(phase * .pi * 6) * envelope * (.pi / 36)
        let pivot = CGPoint(x: size.width / 2, y: size.height)

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: pivot.x, y: pivot.y)
        transform = transform.rotated(by: angle)
        transform = transform.translatedBy(x: -pivot.x, y: -pivot.y)
        return ProjectionTransform(transform)
    }
}

struct AnimatedMilkTea: View {
    let milkTea: MilkTea
    @State private var shakeProgress: CGFloat = 0

    var body: some View {
        MilkTeaArtwork(milkTea: milkTea)
            .modifier(HoverShakeEffect(progress: shakeProgress))
            .onHover { isHovering in
                guard isHovering else { return }
                withAnimation(.linear(duration: 0.55)) {
                    shakeProgress += 1
                }
            }
    }
}
