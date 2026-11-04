//
//  FluentIshTests.swift
//  FluentIshTests
//
//  Unit tests for pure logic (no network, no UI). Run with ⌘U or
//  `xcodebuild test`. Each step of the V1 build adds tests here or in a
//  sibling file.
//

import Testing
import SwiftUI
@testable import FluentIsh

struct SVGPathTests {

    @Test func squareFromLines() {
        let rect = SVGPath.path("M 0 0 L 10 0 L 10 10 L 0 10 Z").boundingRect
        #expect(rect == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func implicitLineAfterMove() {
        // SVG rule: number pairs after "M" without a new command are line-tos.
        let rect = SVGPath.path("M 0 0 20 5").boundingRect
        #expect(rect.width == 20 && rect.height == 5)
    }

    @Test func negativeNumbersWithoutSpaces() {
        let rect = SVGPath.path("M 0 0 L-10-10").boundingRect
        #expect(rect.minX == -10 && rect.minY == -10)
    }

    @Test func churroHeadStaysOnTheGrid() {
        // The head path from Mascot.tsx spans x 28…72, y 22…64.
        let head = SVGPath.path("M 50 22 C 34 22 28 32 28 45 C 28 58 35 64 50 64 C 65 64 72 58 72 45 C 72 32 66 22 50 22 Z")
        let box = head.boundingRect
        #expect(abs(box.minX - 28) < 0.5 && abs(box.maxX - 72) < 0.5)
        #expect(abs(box.minY - 22) < 0.5 && abs(box.maxY - 64) < 0.5)
    }
}

struct MascotAnimationTests {

    @Test func blinkIsOpenMostOfTheTime() {
        #expect(MascotView.blinkScale(0) == 1)
        #expect(MascotView.blinkScale(3.8 * 0.5) == 1)
        // Fully closed at 95% of the 3.8s cycle.
        #expect(abs(MascotView.blinkScale(3.8 * 0.95) - 0.08) < 0.001)
    }

    @Test func keyframesHitTheirValues() {
        let frames = [(0.0, 0.0), (0.5, 10.0), (1.0, 0.0)]
        #expect(MascotView.keyframes(0.5, frames) == 10)
        #expect(MascotView.keyframes(1.0, frames) == 0)
        #expect(MascotView.keyframes(0.25, frames) == 5)   // smoothstep midpoint
    }
}
