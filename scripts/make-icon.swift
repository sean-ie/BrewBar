#!/usr/bin/env swift
// Generates BrewBar.app's icon — a rounded amber square with a white mug.
// Usage: swift scripts/make-icon.swift Resources/AppIcon.icns
import AppKit

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon.icns"

func renderIcon(size: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        // Rounded background: amber/orange gradient
        let gradient = NSGradient(
            colors: [
                NSColor(red: 0.96, green: 0.60, blue: 0.10, alpha: 1),
                NSColor(red: 0.78, green: 0.38, blue: 0.04, alpha: 1)
            ],
            atLocations: [0, 1],
            colorSpace: .deviceRGB
        )!
        let radius = size * 0.22
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        gradient.draw(in: path, angle: -50)

        // White mug symbol centred and scaled
        let symbolSize = size * 0.58
        if let sym = NSImage(systemSymbolName: "mug.fill", accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
            let img = sym.withSymbolConfiguration(cfg)!
            let origin = NSPoint(
                x: (rect.width  - img.size.width)  / 2,
                y: (rect.height - img.size.height) / 2 - size * 0.02
            )
            NSColor.white.withAlphaComponent(0.96).set()
            img.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 0.96)
        }
        return true
    }
}

// Build .iconset at required macOS sizes
let iconsetURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("BrewBar.iconset")
try? FileManager.default.removeItem(at: iconsetURL)
try! FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(Int, Bool)] = [
    (16, false), (16, true),
    (32, false), (32, true),
    (64, false), (64, true),
    (128, false), (128, true),
    (256, false), (256, true),
    (512, false), (512, true),
    (1024, false)
]

for (pts, is2x) in sizes {
    let pixels = is2x ? pts * 2 : pts
    let img = renderIcon(size: CGFloat(pixels))
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    let png = rep.representation(using: .png, properties: [:])!
    let name = is2x ? "icon_\(pts)x\(pts)@2x.png" : "icon_\(pts)x\(pts).png"
    try! png.write(to: iconsetURL.appendingPathComponent(name))
}

// Convert to icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetURL.path, "-o", outputPath]
try! task.run()
task.waitUntilExit()

try? FileManager.default.removeItem(at: iconsetURL)

if task.terminationStatus == 0 {
    print("Icon written to \(outputPath)")
} else {
    print("iconutil failed"); exit(1)
}
