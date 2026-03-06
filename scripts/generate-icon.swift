#!/usr/bin/env swift
// Generates MacPomodoro app icon PNGs using CoreGraphics.
// Usage: swift scripts/generate-icon.swift <output-dir>

import Foundation
import CoreGraphics
import ImageIO

func makeIcon(size: Int) -> CGImage? {
    let s = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()

    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: cs, components: [r, g, b, a])!
    }

    // ── Background: crimson gradient rounded rect ──────────────────────────
    let radius = s * 0.2237
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let bgGrad = CGGradient(
        colorsSpace: cs,
        colors: [rgb(0.84, 0.11, 0.09), rgb(0.95, 0.28, 0.22)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(bgGrad,
                           start: CGPoint(x: s / 2, y: 0),
                           end:   CGPoint(x: s / 2, y: s),
                           options: [])
    ctx.restoreGState()

    // ── Tomato body ────────────────────────────────────────────────────────
    let cx = s * 0.50
    let cy = s * 0.44
    let r  = s * 0.305
    let body = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)

    // soft drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.018),
                  blur: s * 0.045,
                  color: rgb(0, 0, 0, 0.40))
    ctx.setFillColor(rgb(1.0, 0.91, 0.82))
    ctx.fillEllipse(in: body)
    ctx.restoreGState()

    // body fill (no shadow)
    ctx.setFillColor(rgb(1.0, 0.91, 0.82))
    ctx.fillEllipse(in: body)

    // subtle vertical segment crease
    ctx.saveGState()
    ctx.addEllipse(in: body)
    ctx.clip()
    ctx.setStrokeColor(rgb(0.82, 0.60, 0.48, 0.28))
    ctx.setLineWidth(s * 0.011)
    ctx.move(to:    CGPoint(x: cx, y: cy - r * 0.82))
    ctx.addLine(to: CGPoint(x: cx, y: cy + r * 0.82))
    ctx.strokePath()
    ctx.restoreGState()

    // specular highlight
    ctx.saveGState()
    ctx.addEllipse(in: body)
    ctx.clip()
    let hlGrad = CGGradient(
        colorsSpace: cs,
        colors: [rgb(1, 1, 1, 0.50), rgb(1, 1, 1, 0)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(hlGrad,
                           startCenter: CGPoint(x: cx - r * 0.22, y: cy + r * 0.38),
                           startRadius: 0,
                           endCenter:   CGPoint(x: cx - r * 0.22, y: cy + r * 0.38),
                           endRadius:   r * 0.52,
                           options: [])
    ctx.restoreGState()

    // ── Stem ──────────────────────────────────────────────────────────────
    ctx.setStrokeColor(rgb(0.17, 0.53, 0.19))
    ctx.setLineWidth(s * 0.052)
    ctx.setLineCap(.round)
    ctx.move(to:    CGPoint(x: cx, y: cy + r - s * 0.012))
    ctx.addLine(to: CGPoint(x: cx, y: cy + r + s * 0.135))
    ctx.strokePath()

    // ── Leaves ────────────────────────────────────────────────────────────
    ctx.setFillColor(rgb(0.19, 0.60, 0.21))
    let baseY = cy + r + s * 0.038

    func leaf(dx: CGFloat) {
        let p = CGMutablePath()
        p.move(to:     CGPoint(x: cx + dx * 0.01, y: baseY + s * 0.03))
        p.addCurve(to: CGPoint(x: cx + dx * 0.16, y: baseY + s * 0.10),
                   control1: CGPoint(x: cx + dx * 0.04, y: baseY + s * 0.10),
                   control2: CGPoint(x: cx + dx * 0.13, y: baseY + s * 0.14))
        p.addCurve(to: CGPoint(x: cx + dx * 0.01, y: baseY + s * 0.03),
                   control1: CGPoint(x: cx + dx * 0.09, y: baseY + s * 0.04),
                   control2: CGPoint(x: cx + dx * 0.03, y: baseY + s * 0.02))
        ctx.addPath(p)
        ctx.fillPath()
    }
    leaf(dx: -1)
    leaf(dx:  1)

    return ctx.makeImage()
}

// ── Write PNGs ─────────────────────────────────────────────────────────────
let outputDir = CommandLine.arguments.dropFirst().first
    ?? FileManager.default.currentDirectoryPath

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    guard let image = makeIcon(size: size) else {
        fputs("error: failed to render \(size)x\(size)\n", stderr); exit(1)
    }
    let url = URL(fileURLWithPath: "\(outputDir)/icon_\(size).png")
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, "public.png" as CFString, 1, nil
    ) else {
        fputs("error: cannot create destination for \(size)\n", stderr); exit(1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else {
        fputs("error: cannot write \(size)\n", stderr); exit(1)
    }
    print("  icon_\(size).png")
}
print("Done.")
