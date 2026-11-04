//
//  MascotView.swift
//  FluentIsh
//
//  Churro el Ajolote, the Fluent·ish axolotl, ported from the prototype's
//  inline SVG (src/components/common/Mascot.tsx). Same 100×100 drawing grid,
//  same path strings, same colours, same 6 moods.
//
//  How it's drawn: a Canvas paints the shapes in the original SVG order
//  (gills → body → head → face → bandana → arms). A TimelineView redraws it
//  every frame so the idle animations from index.css can run:
//    blink 3.8s · gill flutter 2.8s · breathe 3.2s · head tilt 5.6s
//    celebrating → dance 0.65s loop · encouraging → one nod (1.2s) · tap → bounce
//  With Reduce Motion on, Churro stays still (same as the prototype's CSS).
//
//  Usage: MascotView(mood: .waving, size: .sm)
//

import SwiftUI

enum MascotMood: String, CaseIterable {
    case waving, celebrating, quest, thinking, proud, encouraging
}

enum MascotSize {
    case xs, sm, md, lg, xl
    var points: CGFloat {
        switch self {
        case .xs: 32
        case .sm: 44
        case .md: 68
        case .lg: 96
        case .xl: 128
        }
    }
}

struct MascotView: View {
    var mood: MascotMood = .waving
    var size: MascotSize = .md
    /// Breathing, tilting, blinking and gill flutter. Turn off for tiny static uses.
    var idle: Bool = true
    var onTap: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = Date()
    @State private var tappedAt: Date?

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSince(appeared)
            let motion = bodyMotion(t: t, now: timeline.date)

            Canvas { context, canvasSize in
                context.scaleBy(x: canvasSize.width / 100, y: canvasSize.height / 100)
                ChurroDrawing(mood: mood,
                              blink: reduceMotion || !idle ? 1 : Self.blinkScale(t),
                              flutter: reduceMotion || !idle ? 0 : Self.loop(t, period: 2.8))
                    .draw(in: &context)
            }
            .frame(width: size.points, height: size.points)
            .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
            .rotationEffect(.degrees(motion.rotation), anchor: .bottom)
            .offset(y: motion.offsetY)
        }
        .frame(width: size.points, height: size.points)
        .contentShape(Rectangle())
        .onTapGesture {
            tappedAt = Date()
            onTap?()
        }
        .accessibilityElement()
        .accessibilityLabel("Churro the axolotl, \(mood.rawValue)")
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
    }

    // MARK: Whole-body motion (matches the CSS keyframes)

    private struct Motion { var offsetY = 0.0, rotation = 0.0, scaleX = 1.0, scaleY = 1.0 }

    private func bodyMotion(t: Double, now: Date) -> Motion {
        guard !reduceMotion else { return Motion() }
        let px = size.points / 96   // CSS offsets were in px at size "lg" (96pt)
        var m = Motion()

        // Tap → bounce (Tailwind animate-bounce: up 25% and back, 0.6s)
        if let tappedAt, case let dt = now.timeIntervalSince(tappedAt), dt < 0.6 {
            m.offsetY = -0.25 * size.points * sin(.pi * dt / 0.6)
            return m
        }

        switch mood {
        case .celebrating:   // churroCelebrateDance 650ms infinite
            let p = (t.truncatingRemainder(dividingBy: 0.65)) / 0.65
            m.offsetY = Self.keyframes(p, [(0, 0), (0.25, -10), (0.5, -16), (0.75, -10), (1, 0)]) * px
            m.rotation = Self.keyframes(p, [(0, 0), (0.25, -3), (0.5, 0), (0.75, 3), (1, 0)])
            let s = Self.keyframes(p, [(0, 1), (0.25, 1.04), (0.5, 1.08), (0.75, 1.04), (1, 1)])
            m.scaleX = s; m.scaleY = s
        case .encouraging:   // churroEncourageNod 1.2s, plays once
            if t < 1.2 {
                let p = t / 1.2
                m.rotation = Self.keyframes(p, [(0, 0), (0.3, -4.5), (0.7, 3), (1, 0)])
                m.offsetY = Self.keyframes(p, [(0, 0), (0.3, -2), (0.7, -1), (1, 0)]) * px
            }
        default:
            guard idle else { break }
            // churroBreathe 3.2s: rise 3px and squash slightly
            let breathe = Self.loop(t, period: 3.2)
            m.offsetY = -3 * breathe * px
            m.scaleX = 1 + 0.015 * breathe
            m.scaleY = 1 - 0.015 * breathe
            // churroTilt 5.6s: still most of the time, then a little head tilt
            let p = t.truncatingRemainder(dividingBy: 5.6) / 5.6
            m.rotation = Self.keyframes(p, [(0, 0), (0.78, 0), (0.84, -3.5), (0.92, 2.5), (1, 0)])
        }
        return m
    }

    // MARK: Animation helpers

    /// 0 → 1 → 0 over `period`, eased like CSS ease-in-out.
    static func loop(_ t: Double, period: Double) -> Double {
        (1 - cos(2 * .pi * t / period)) / 2
    }

    /// churroBlink 3.8s: eyes squash to 8% height around 95% of the cycle.
    static func blinkScale(_ t: Double) -> Double {
        let p = t.truncatingRemainder(dividingBy: 3.8) / 3.8
        return keyframes(p, [(0, 1), (0.93, 1), (0.95, 0.08), (0.97, 1), (1, 1)])
    }

    /// Interpolates CSS-style keyframes [(progress, value)] with ease-in-out.
    static func keyframes(_ p: Double, _ frames: [(Double, Double)]) -> Double {
        guard let last = frames.last else { return 0 }
        for i in 1..<frames.count where p <= frames[i].0 {
            let (p0, v0) = frames[i - 1], (p1, v1) = frames[i]
            let local = p1 == p0 ? 1 : (p - p0) / (p1 - p0)
            let eased = local * local * (3 - 2 * local)   // smoothstep
            return v0 + (v1 - v0) * eased
        }
        return last.1
    }
}

// MARK: - The drawing itself

/// Paints Churro on a 100×100 grid. Kept separate from the animation code so
/// it reads like the original SVG, top to bottom.
private struct ChurroDrawing {
    let mood: MascotMood
    let blink: Double      // 1 = eyes open, 0.08 = closed
    let flutter: Double    // 0…1 gill flutter amount

    private let ink = Color(hex: 0x1F1B4D)
    private let skin = Color(hex: 0xFFEBD2)
    private let bodyGradient = Gradient(colors: [Color(hex: 0xFFEBD2), Color(hex: 0xFFD6A5)])

    func draw(in ctx: inout GraphicsContext) {
        drawGills(&ctx)
        drawBody(&ctx)
        drawHead(&ctx)
        drawFace(&ctx)
        drawBandana(&ctx)
        drawArms(&ctx)
    }

    // 1. External gills, with the flutter (rotate up to 2° and grow 2%)
    private func drawGills(_ ctx: inout GraphicsContext) {
        var g = ctx
        g.translateBy(x: 50, y: 42)
        g.rotate(by: .degrees(2 * flutter))
        g.scaleBy(x: 1 + 0.02 * flutter, y: 1 + 0.02 * flutter)
        g.translateBy(x: -50, y: -42)

        shape(&g, "M 32 36 C 20 28 8 32 10 20 C 14 16 26 24 33 30", fill: .flame, line: 2)
        line(&g, "M 12 21 C 16 22 22 26 28 29", Color(hex: 0xFFA07A), 1.5)
        shape(&g, "M 28 46 C 14 42 6 48 8 38 C 12 34 22 40 28 43", fill: .connPurple, line: 2)
        line(&g, "M 10 39 C 14 40 20 42 26 43", Color(hex: 0xB8A5FF), 1.5)
        shape(&g, "M 30 56 C 18 56 12 66 14 58 C 16 54 24 54 29 53", fill: .aqua, line: 2)

        shape(&g, "M 68 36 C 80 28 92 32 90 20 C 86 16 74 24 67 30", fill: .flame, line: 2)
        line(&g, "M 88 21 C 84 22 78 26 72 29", Color(hex: 0xFFA07A), 1.5)
        shape(&g, "M 72 46 C 86 42 94 48 92 38 C 88 34 78 40 72 43", fill: .connPurple, line: 2)
        line(&g, "M 90 39 C 86 40 80 42 74 43", Color(hex: 0xB8A5FF), 1.5)
        shape(&g, "M 70 56 C 82 56 88 66 86 58 C 84 54 76 54 71 53", fill: .aqua, line: 2)
    }

    // 2. Body, belly and feet
    private func drawBody(_ ctx: inout GraphicsContext) {
        let body = SVGPath.path("M 35 60 C 35 55 42 55 50 55 C 58 55 65 55 65 60 C 67 70 66 84 59 89 C 54 92 46 92 41 89 C 34 84 33 70 35 60 Z")
        ctx.fill(body, with: skinGradient)
        ctx.stroke(body, with: .color(ink), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

        let belly = Path(ellipseIn: CGRect(x: 39, y: 62, width: 22, height: 24))
        ctx.fill(belly, with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF8EC), skin]),
                                              center: CGPoint(x: 50, y: 74), startRadius: 0, endRadius: 16))

        ellipse(&ctx, cx: 40, cy: 90, rx: 4.5, ry: 3, fill: skin, line: 2)
        ellipse(&ctx, cx: 60, cy: 90, rx: 4.5, ry: 3, fill: skin, line: 2)
    }

    // 3. Head and rosy cheeks
    private func drawHead(_ ctx: inout GraphicsContext) {
        let head = SVGPath.path("M 50 22 C 34 22 28 32 28 45 C 28 58 35 64 50 64 C 65 64 72 58 72 45 C 72 32 66 22 50 22 Z")
        ctx.fill(head, with: skinGradient)
        ctx.stroke(head, with: .color(ink), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
        circle(&ctx, 35, 48, 4.5, Color.coral.opacity(0.45))
        circle(&ctx, 65, 48, 4.5, Color.coral.opacity(0.45))
    }

    // 4. Face, which changes with mood
    private func drawFace(_ ctx: inout GraphicsContext) {
        switch mood {
        case .celebrating:
            line(&ctx, "M 36 43 Q 41 38 46 43", ink, 2.8)          // ^ ^ happy eyes
            line(&ctx, "M 54 43 Q 59 38 64 43", ink, 2.8)
            shape(&ctx, "M 44 48 Q 50 58 56 48 Z", fill: .coral, line: 2)   // laughing mouth
            ctx.fill(SVGPath.path("M 46 52 Q 50 55 54 52"), with: .color(Color(hex: 0xFFA5B5)))

        case .encouraging:
            eyes(&ctx) { e in
                circle(&e, 41, 42, 4, ink); circle(&e, 39.5, 40.5, 1.5, .white)
                circle(&e, 59, 41.5, 4, ink); circle(&e, 57.5, 40, 1.5, .white)
            }
            line(&ctx, "M 45 50 Q 50 54 55 50", ink, 2.2)

        case .proud:
            circle(&ctx, 41, 42, 3.8, ink); circle(&ctx, 39.8, 40.5, 1.3, .white)
            line(&ctx, "M 54 43 Q 59 38 64 43", ink, 2.8)          // wink
            line(&ctx, "M 44 50 Q 50 55 56 49", ink, 2.2)

        case .quest:
            eyes(&ctx) { e in
                circle(&e, 41, 41, 4.5, ink); circle(&e, 39.5, 39.5, 1.8, .white); circle(&e, 43, 43, 0.9, .white)
                circle(&e, 59, 41, 4.5, ink); circle(&e, 57.5, 39.5, 1.8, .white); circle(&e, 61, 43, 0.9, .white)
            }
            ellipse(&ctx, cx: 50, cy: 51, rx: 3, ry: 3.5, fill: .coral, line: 1.8)   // curious "O"

        case .waving, .thinking:
            eyes(&ctx) { e in
                circle(&e, 41, 42, 4, ink); circle(&e, 39.5, 40.5, 1.5, .white); circle(&e, 42.5, 43.5, 0.7, .white)
                circle(&e, 59, 42, 4, ink); circle(&e, 57.5, 40.5, 1.5, .white); circle(&e, 60.5, 43.5, 0.7, .white)
            }
            line(&ctx, "M 44 50 Q 50 56 56 50", ink, 2.4)
        }
    }

    // 5. Teal bandana
    private func drawBandana(_ ctx: inout GraphicsContext) {
        shape(&ctx, "M 33 58 Q 50 66 67 58 L 64 63 Q 50 71 36 63 Z", fill: .aqua, line: 2)
        shape(&ctx, "M 61 61 L 67 69 L 63 70 L 59 63 Z", fill: Color(hex: 0x0E867A), line: 1.8)
    }

    // 6. Arms and accessories, which change with mood
    private func drawArms(_ ctx: inout GraphicsContext) {
        switch mood {
        case .waving:
            shape(&ctx, "M 34 62 C 28 58 20 50 24 44 C 27 40 32 46 33 54", fill: skin, line: 2.2, cap: .round)
            shape(&ctx, "M 66 62 C 70 65 74 70 70 74 C 67 76 65 72 64 67", fill: skin, line: 2, cap: .round)

        case .celebrating:
            shape(&ctx, "M 35 62 C 28 56 22 46 26 42 C 29 39 34 46 34 54", fill: skin, line: 2.2, cap: .round)
            shape(&ctx, "M 65 62 C 72 56 78 46 74 42 C 71 39 66 46 66 54", fill: skin, line: 2.2, cap: .round)
            shape(&ctx, "M 43 23 L 50 7 L 57 23 Z", fill: .flame, line: 2)       // party hat
            line(&ctx, "M 45 19 L 55 19", .sunny, 2)
            line(&ctx, "M 47 13 L 53 13", .aqua, 1.8)
            circle(&ctx, 50, 6, 3, .sunny); strokeCircle(&ctx, 50, 6, 3, 1.5)
            ctx.fill(SVGPath.path("M 18 16 L 20 22 L 26 24 L 20 26 L 18 32 L 16 26 L 10 24 L 16 22 Z"), with: .color(.sunny))
            ctx.fill(SVGPath.path("M 82 14 L 83 18 L 87 19 L 83 20 L 82 24 L 81 20 L 77 19 L 81 18 Z"), with: .color(.sunny))

        case .encouraging:
            shape(&ctx, "M 34 62 C 28 58 24 50 29 46 C 32 44 35 50 34 56", fill: skin, line: 2.2, cap: .round)
            ellipse(&ctx, cx: 64, cy: 66, rx: 4, ry: 3.5, fill: skin, line: 2)

        case .quest:
            circle(&ctx, 50, 19, 3, .flame); strokeCircle(&ctx, 50, 19, 3, 1.5)   // map pin
            ellipse(&ctx, cx: 50, cy: 68, rx: 5, ry: 4, fill: .sunny, line: 1.8)  // badge
            line(&ctx, "M 50 65 L 50 71", ink, 1.2)
            line(&ctx, "M 47 68 L 53 68", ink, 1.2)

        case .proud, .thinking:
            ellipse(&ctx, cx: 44, cy: 67, rx: 3.5, ry: 3, fill: skin, line: 1.8)  // polite hands
            ellipse(&ctx, cx: 56, cy: 67, rx: 3.5, ry: 3, fill: skin, line: 1.8)
        }
    }

    // MARK: Drawing primitives

    private var skinGradient: GraphicsContext.Shading {
        .linearGradient(bodyGradient, startPoint: CGPoint(x: 50, y: 20), endPoint: CGPoint(x: 50, y: 90))
    }

    /// Draws the eye group squashed vertically for the blink (around y = 42).
    private func eyes(_ ctx: inout GraphicsContext, _ drawEyes: (inout GraphicsContext) -> Void) {
        var e = ctx
        e.translateBy(x: 0, y: 42)
        e.scaleBy(x: 1, y: blink)
        e.translateBy(x: 0, y: -42)
        drawEyes(&e)
    }

    private func shape(_ ctx: inout GraphicsContext, _ d: String, fill: Color, line width: CGFloat, cap: CGLineCap = .butt) {
        let p = SVGPath.path(d)
        ctx.fill(p, with: .color(fill))
        ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: .round))
    }

    private func line(_ ctx: inout GraphicsContext, _ d: String, _ color: Color, _ width: CGFloat) {
        ctx.stroke(SVGPath.path(d), with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func circle(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)), with: .color(color))
    }

    private func strokeCircle(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ width: CGFloat) {
        ctx.stroke(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)), with: .color(ink), lineWidth: width)
    }

    private func ellipse(_ ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, fill: Color, line width: CGFloat) {
        let p = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
        ctx.fill(p, with: .color(fill))
        ctx.stroke(p, with: .color(ink), lineWidth: width)
    }
}

// MARK: - Cheers (from Mascot.tsx)

enum Cheers {
    static let celebration = [
        "¡Buen trabajo! · Great job! 🎉",
        "¡Lo lograste! · You did it! 🌟",
        "¡Increíble! · Amazing! ✨",
        "¡De rechupete! · Splendid! 🏆",
        "¡Qué crack! · You are a natural! 🔥",
        "¡Frase perfecta! · Flawless! 🎯",
    ]
    static let encouraging = [
        "¡Casi casi! · Almost there! 💪",
        "¡Buen intento! · Good try! 💡",
        "¡Ánimo! Sigue probando · Keep going! ☕",
        "¡No pasa nada! · You got this! ✨",
        "¡Cerca! Una más · So close! 🎯",
    ]
}

#Preview {
    HStack {
        ForEach(MascotMood.allCases, id: \.self) { MascotView(mood: $0, size: .md) }
    }
    .padding()
    .background(Color.canvas)
}
