//
//  ShakeEffect.swift
//  FluentIsh
//
//  The side-to-side wobble on a wrong answer (the prototype's
//  `animate-tile-shake`, 350ms). Bump a counter to shake once:
//
//      @State private var misses = 0
//      VStack { ... }.shake(misses)
//      misses += 1      // on a wrong tap
//
//  Skipped when Reduce Motion is on; pair it with Haptics.error() so the
//  miss is still felt.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 8
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    nonisolated func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * shakes), y: 0))
    }
}

private struct ShakeModifier: ViewModifier {
    let count: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: reduceMotion ? 0 : CGFloat(count)))
            .animation(.linear(duration: 0.35), value: count)
    }
}

extension View {
    func shake(_ count: Int) -> some View { modifier(ShakeModifier(count: count)) }
}
