#!/usr/bin/env swift
// Run this script on your Mac from Terminal:
//   swift generate_icon.swift
// It creates AppIcon-1024.png in the current directory.
// Then drag that PNG into Xcode → Assets.xcassets → AppIcon

import Foundation
import CoreGraphics
import ImageIO

let size = 1024
let half = CGFloat(size) / 2
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let ctx = CGContext(
    data: nil,
    width: size, height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Cannot create context") }

// ── Background: diagonal gradient navy → indigo ──────────────────────────────
let bgColors = [
    CGColor(red: 0.05, green: 0.08, blue: 0.25, alpha: 1.0),   // #0D1440 deep navy
    CGColor(red: 0.18, green: 0.08, blue: 0.55, alpha: 1.0),   // #2E148C indigo
] as CFArray

guard let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: bgColors,
    locations: [0.0, 1.0] as [CGFloat]
) else { fatalError("Cannot create gradient") }

ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: CGFloat(size), y: CGFloat(size)),
    options: []
)

// ── White rounded card ────────────────────────────────────────────────────────
let padding: CGFloat = 172
let cardRect = CGRect(
    x: padding, y: padding,
    width: CGFloat(size) - padding * 2,
    height: CGFloat(size) - padding * 2
)
let cornerRadius: CGFloat = 100

let cardPath = CGPath(roundedRect: cardRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.96))
ctx.addPath(cardPath)
ctx.fillPath()

// ── Box icon (dark indigo lines on the white card) ────────────────────────────
let bx: CGFloat = half
let by: CGFloat = half - 40
let bw: CGFloat = 280
let bh: CGFloat = 240
let bTop = by - bh / 2
let bBot = by + bh / 2
let bLeft = bx - bw / 2
let bRight = bx + bw / 2
let lidH: CGFloat = 60

ctx.setStrokeColor(CGColor(red: 0.18, green: 0.08, blue: 0.55, alpha: 1))
ctx.setLineWidth(18)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

// Box body outline
let boxBody = CGMutablePath()
boxBody.move(to: CGPoint(x: bLeft, y: bTop + lidH))
boxBody.addLine(to: CGPoint(x: bLeft, y: bBot))
boxBody.addLine(to: CGPoint(x: bRight, y: bBot))
boxBody.addLine(to: CGPoint(x: bRight, y: bTop + lidH))
ctx.addPath(boxBody)
ctx.strokePath()

// Lid
let lid = CGMutablePath()
lid.move(to: CGPoint(x: bLeft - 20, y: bTop + lidH))
lid.addLine(to: CGPoint(x: bLeft - 20, y: bTop))
lid.addLine(to: CGPoint(x: bRight + 20, y: bTop))
lid.addLine(to: CGPoint(x: bRight + 20, y: bTop + lidH))
lid.addLine(to: CGPoint(x: bLeft - 20, y: bTop + lidH))
ctx.addPath(lid)
ctx.strokePath()

// Lid divider line
ctx.move(to: CGPoint(x: bLeft - 20, y: bTop + lidH))
ctx.addLine(to: CGPoint(x: bRight + 20, y: bTop + lidH))
ctx.strokePath()

// Center seam on lid
ctx.move(to: CGPoint(x: half, y: bTop))
ctx.addLine(to: CGPoint(x: half, y: bTop + lidH))
ctx.strokePath()

// ── Sparkle (4-point star) — AI symbol ───────────────────────────────────────
let sx: CGFloat = bx
let sy: CGFloat = bBot + 72
let outerR: CGFloat = 54
let innerR: CGFloat = 22
let points = 4

ctx.setFillColor(CGColor(red: 0.18, green: 0.08, blue: 0.55, alpha: 1))
let star = CGMutablePath()
for i in 0..<(points * 2) {
    let angle = Double(i) * .pi / Double(points) - .pi / 2
    let r = i % 2 == 0 ? outerR : innerR
    let px = sx + CGFloat(cos(angle)) * r
    let py = sy + CGFloat(sin(angle)) * r
    if i == 0 { star.move(to: CGPoint(x: px, y: py)) }
    else { star.addLine(to: CGPoint(x: px, y: py)) }
}
star.closeSubpath()
ctx.addPath(star)
ctx.fillPath()

// Small dots flanking the sparkle
for dx in [-100, 100] as [CGFloat] {
    ctx.addEllipse(in: CGRect(x: sx + dx - 10, y: sy - 10, width: 20, height: 20))
}
ctx.fillPath()

// ── Export PNG ────────────────────────────────────────────────────────────────
guard let cgImage = ctx.makeImage() else { fatalError("Cannot create image") }

let outputURL = URL(fileURLWithPath: "AppIcon-1024.png")
guard let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Cannot create destination")
}
CGImageDestinationAddImage(dest, cgImage, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Cannot write PNG") }

print("✅  AppIcon-1024.png saved — drag it into Xcode Assets.xcassets → AppIcon")
