// Renders the placeholder app icon: night-purple gradient, glowing crescent
// moon, star dots. Deliberately distinct from the source app's icon.
// Usage: swift MakeIcon.swift <output.png>

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
guard CommandLine.arguments.count > 1 else {
    fatalError("usage: swift MakeIcon.swift <output.png>")
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

// Background: vertical night gradient
let bgGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0.10, 0.06, 0.20), color(0.04, 0.02, 0.09)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: CGFloat(size)), end: .zero, options: [])

// Soft purple glow behind the moon
let glow = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0.55, 0.40, 0.97, 0.55), color(0.55, 0.40, 0.97, 0.0)] as CFArray,
    locations: [0, 1]
)!
let center = CGPoint(x: 512, y: 520)
ctx.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: 430, options: [])

// Star dots (fixed pseudo-random layout)
var state: UInt64 = 0xBEEF
func rand() -> CGFloat {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return CGFloat((state >> 33) % 10_000) / 10_000
}
for _ in 0..<40 {
    let x = rand() * 1024
    let y = rand() * 1024
    let r = 1.5 + rand() * 3.5
    let dx = x - center.x, dy = y - center.y
    if dx * dx + dy * dy < 300 * 300 { continue }
    ctx.setFillColor(color(1, 1, 1, 0.25 + rand() * 0.5))
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
}

// Crescent moon: bright disc with an offset bite
let moonRadius: CGFloat = 250
let moonGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0.93, 0.89, 1.0), color(0.72, 0.62, 0.98)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: center.x - moonRadius, y: center.y - moonRadius, width: moonRadius * 2, height: moonRadius * 2))
ctx.clip()
ctx.drawLinearGradient(
    moonGradient,
    start: CGPoint(x: center.x, y: center.y + moonRadius),
    end: CGPoint(x: center.x, y: center.y - moonRadius),
    options: []
)
ctx.restoreGState()

// Bite: overlap a background-colored disc to form the crescent
let bite = CGPoint(x: center.x + 150, y: center.y + 105)
let biteRadius: CGFloat = 215
let biteGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0.07, 0.04, 0.15), color(0.05, 0.03, 0.11)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: bite.x - biteRadius, y: bite.y - biteRadius, width: biteRadius * 2, height: biteRadius * 2))
ctx.clip()
ctx.drawLinearGradient(
    biteGradient,
    start: CGPoint(x: bite.x, y: bite.y + biteRadius),
    end: CGPoint(x: bite.x, y: bite.y - biteRadius),
    options: []
)
ctx.restoreGState()

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outputURL.path)")
