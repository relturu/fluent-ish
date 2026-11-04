//
//  ConfettiView.swift
//  FluentIsh
//
//  The celebration from the prototype (ConfettiBurst in HiFiElements.tsx):
//  three waves of paper confetti in the brand colours, then a fade-out.
//    wave 1 (0ms):   corner cannons, 70 pieces each, plus 60 falling from the top
//    wave 2 (280ms): 50 stars bursting from upper-centre
//    wave 3 (650ms): 55 ribbons falling from the top
//  Each piece has gravity, air drag, side-to-side wobble and a fake 3D flip
//  (squashing its width with cos(tilt)), so it looks like paper.
//
//  How it runs: a TimelineView asks for a new frame ~60–120×/s, and a Canvas
//  draws every particle. The physics uses fixed 60fps steps, so it behaves the
//  same on 60Hz and 120Hz (ProMotion) screens.
//
//  CelebrationOverlay wraps it with the dim background, a cheer bubble,
//  dancing Churro and a Continue button. Show it after a solved puzzle.
//

import SwiftUI

struct ConfettiView: View {
    var duration: TimeInterval = 2.8
    @State private var simulation = ConfettiSimulation()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                simulation.advance(to: timeline.date, in: size)
                let fade = simulation.fade(total: duration)
                guard fade > 0.01 else { return }
                for p in simulation.particles {
                    let transform = CGAffineTransform(translationX: p.x, y: p.y)
                        .rotated(by: p.angle)
                        .scaledBy(x: cos(p.tilt), y: 1)
                    context.fill(p.shape.path(size: p.size, length: p.length).applying(transform),
                                 with: .color(p.color.opacity(fade)))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Physics

/// A plain class (not @Observable): the TimelineView already redraws every
/// frame, so the particles don't need to trigger SwiftUI updates themselves.
final class ConfettiSimulation {
    struct Particle {
        var x, y, vx, vy: CGFloat
        var gravity: CGFloat
        var color: Color
        var shape: Shape
        var size, length: CGFloat
        var angle, angleSpeed: CGFloat
        var tilt, tiltSpeed: CGFloat
        var wobble, wobbleSpeed: CGFloat
    }

    enum Shape {
        case rect, ribbon, circle, star

        func path(size: CGFloat, length: CGFloat) -> Path {
            switch self {
            case .rect:   Path(CGRect(x: -size / 2, y: -size * 0.7, width: size, height: size * 1.4))
            case .ribbon: Path(CGRect(x: -size / 2, y: -length / 2, width: size, height: length))
            case .circle: Path(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
            case .star:   Self.star(outer: size, inner: size * 0.45)
            }
        }

        private static func star(outer: CGFloat, inner: CGFloat) -> Path {
            var path = Path()
            for i in 0..<10 {
                let r = i.isMultiple(of: 2) ? outer : inner
                let a = CGFloat(i) * .pi / 5 - .pi / 2
                let point = CGPoint(x: cos(a) * r, y: sin(a) * r)
                i == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            path.closeSubpath()
            return path
        }
    }

    private(set) var particles: [Particle] = []
    private var start: Date?
    private var stepsDone = 0
    private var wavesSpawned = 0

    private static let colors: [Color] = [.flame, .connPurple, .aqua, .indigo, .offWhite, .sunny]

    /// 0…1 opacity: fades out over the last 0.9s.
    func fade(total: TimeInterval) -> Double {
        guard let start else { return 1 }
        let remaining = total - Date().timeIntervalSince(start)
        return max(0, min(1, remaining / 0.9))
    }

    func advance(to now: Date, in size: CGSize) {
        if start == nil { start = now }
        let elapsed = now.timeIntervalSince(start!)

        if wavesSpawned == 0 { spawnCannonsAndRain(size); wavesSpawned = 1 }
        if wavesSpawned == 1, elapsed >= 0.28 { spawnStarburst(size); wavesSpawned = 2 }
        if wavesSpawned == 2, elapsed >= 0.65 { spawnRibbons(size); wavesSpawned = 3 }

        // Fixed 60fps steps (the prototype's numbers are per-frame at 60fps).
        let target = Int(elapsed * 60)
        while stepsDone < target {
            step()
            stepsDone += 1
        }
    }

    private func step() {
        for i in particles.indices {
            var p = particles[i]
            p.vx *= 0.985
            p.vy *= 0.985
            p.vy += p.gravity
            p.wobble += p.wobbleSpeed
            p.x += p.vx + sin(p.wobble) * 1.4
            p.y += p.vy
            p.angle += p.angleSpeed
            p.tilt += p.tiltSpeed
            particles[i] = p
        }
    }

    // MARK: Waves

    private func spawnCannonsAndRain(_ size: CGSize) {
        for _ in 0..<70 {   // left cannon, up-right
            let a = -CGFloat.pi / 4 + .random(in: -0.325...0.325)
            let speed = CGFloat.random(in: 16...38)
            particles.append(make(x: size.width * 0.05, y: size.height * 0.96, vx: cos(a) * speed, vy: sin(a) * speed))
        }
        for _ in 0..<70 {   // right cannon, up-left
            let a = -3 * CGFloat.pi / 4 + .random(in: -0.325...0.325)
            let speed = CGFloat.random(in: 16...38)
            particles.append(make(x: size.width * 0.95, y: size.height * 0.96, vx: cos(a) * speed, vy: sin(a) * speed))
        }
        for _ in 0..<60 {   // rain across the top
            particles.append(make(x: .random(in: 0...size.width), y: .random(in: -100 ... -20),
                                  vx: .random(in: -2.5...2.5), vy: .random(in: 2...8)))
        }
    }

    private func spawnStarburst(_ size: CGSize) {
        for _ in 0..<50 {
            let a = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 6...22)
            particles.append(make(x: size.width * 0.5, y: size.height * 0.35,
                                  vx: cos(a) * speed, vy: sin(a) * speed - 5, shape: .star))
        }
    }

    private func spawnRibbons(_ size: CGSize) {
        for _ in 0..<55 {
            particles.append(make(x: .random(in: 0...size.width), y: .random(in: -80 ... -20),
                                  vx: .random(in: -2...2), vy: .random(in: 2.5...7.5), shape: .ribbon))
        }
    }

    private func make(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, shape: Shape? = nil) -> Particle {
        let shape = shape ?? {
            // Same odds as the prototype: ~35% ribbon, ~39% rect, ~21% star, ~5% circle
            if Double.random(in: 0..<1) > 0.65 { return .ribbon }
            if Double.random(in: 0..<1) > 0.4 { return .rect }
            if Double.random(in: 0..<1) > 0.2 { return .star }
            return .circle
        }()
        let size: CGFloat = switch shape {
        case .ribbon: .random(in: 6...9)
        case .star: .random(in: 7...12)
        default: .random(in: 8...14)
        }
        return Particle(
            x: x, y: y, vx: vx, vy: vy,
            gravity: .random(in: 0.32...0.44),
            color: Self.colors.randomElement()!,
            shape: shape, size: size,
            length: shape == .ribbon ? .random(in: 22...44) : .random(in: 12...20),
            angle: .random(in: 0...(2 * .pi)), angleSpeed: .random(in: -0.08...0.08),
            tilt: .random(in: 0...(2 * .pi)), tiltSpeed: .random(in: 0.08...0.22),
            wobble: .random(in: 0...10), wobbleSpeed: .random(in: 0.04...0.10))
    }
}

// MARK: - Celebration overlay

/// Full-screen celebration: dim scrim + confetti + cheer + dancing Churro.
/// Tap anywhere or "Continue" to dismiss; it also dismisses itself after `duration`.
///
///     .overlay { if showCelebration { CelebrationOverlay { showCelebration = false } } }
struct CelebrationOverlay: View {
    var message: String? = nil
    var duration: TimeInterval = 2.8
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var cheer = ""
    @State private var shown = false
    @State private var finished = false

    var body: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.5 : 0.25)
                .ignoresSafeArea()

            if !reduceMotion { ConfettiView(duration: duration) }

            VStack(spacing: 14) {
                Text(cheer)
                    .font(.jakarta(14, 800))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.flame, lineWidth: 2))
                    .shadow(color: Color.flame.opacity(0.35), radius: 16, y: 12)

                MascotView(mood: .celebrating, size: .lg, idle: false)

                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Text("Continue")
                        Image(systemName: "arrow.right").font(.system(size: 11, weight: .heavy))
                    }
                    .font(.jakarta(12, 800))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 20).padding(.vertical, 9)
                    .background(Color.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.flame.opacity(0.4)))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            // Pop entrance (churroPopEntrance) and shrink-away exit (churroPopExit)
            .scaleEffect(shown ? 1 : 0.3)
            .offset(y: shown ? 0 : 60)
        }
        .opacity(finished ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .sensoryFeedback(.success, trigger: shown) { _, isShown in isShown }
        .task {
            cheer = message ?? Cheers.celebration.randomElement()!
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.6)) {
                shown = true
            }
            try? await Task.sleep(for: .seconds(duration - 0.3))
            dismiss()
        }
        .accessibilityAddTraits(.isModal)
    }

    private func dismiss() {
        guard !finished else { return }
        withAnimation(.easeIn(duration: 0.28)) {
            shown = false
            finished = true
        } completion: {
            onDone()
        }
    }
}

// MARK: - Encouragement toast

/// Gentle toast after a wrong guess: never negative, no confetti.
/// Shown ~80pt above the bottom; auto-hides after 2.4s (the caller owns that timer).
struct MascotToast: View {
    var message: String = Cheers.encouraging.randomElement()!
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            MascotView(mood: .encouraging, size: .sm, idle: false)
            VStack(alignment: .leading, spacing: 2) {
                Text("Churro cheers you on")
                    .font(.jakarta(10, 800)).tracking(0.8).textCase(.uppercase)
                    .foregroundStyle(Color.flame)
                Text(message)
                    .font(.jakarta(12, 700))
                    .foregroundStyle(Color.ink)
            }
            Spacer(minLength: 4)
            Text("TAP").font(.jakarta(10, 800)).foregroundStyle(Color.ink.opacity(0.4))
        }
        .padding(12)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.flame.opacity(0.4), lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .onTapGesture(perform: onTap)
    }
}

#Preview("Celebration") {
    Color.canvas.ignoresSafeArea()
        .overlay { CelebrationOverlay(duration: 60) {} }
}
