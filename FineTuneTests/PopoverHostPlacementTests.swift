// FineTuneTests/PopoverHostPlacementTests.swift
import AppKit
import SwiftUI
import Testing
@testable import FineTune

struct PopoverHostPlacementTests {
    private let visible = NSRect(x: 0, y: 0, width: 1000, height: 800)
    private let size = NSSize(width: 200, height: 300)
    private func origin(_ trigger: NSRect) -> NSPoint {
        PopoverHost<EmptyView>.panelOrigin(trigger: trigger, size: size, visible: visible)
    }

    @Test func opensBelowWhenItFits() {
        let o = origin(NSRect(x: 100, y: 600, width: 50, height: 20))
        #expect(o == NSPoint(x: 100, y: 296))
    }

    /// #430 #399 #391: not enough room below, so flip above the trigger.
    @Test func flipsAboveWhenBelowWouldLeaveScreen() {
        let o = origin(NSRect(x: 100, y: 100, width: 50, height: 20))
        #expect(o == NSPoint(x: 100, y: 124))
    }

    @Test func clampsHorizontallyToScreen() {
        let o = origin(NSRect(x: 950, y: 600, width: 50, height: 20))
        #expect(o.x == 800)
        let l = origin(NSRect(x: -40, y: 600, width: 50, height: 20))
        #expect(l.x == 0)
    }

    @Test func staysOnScreenWhenNeitherSideFits() {
        let tall = PopoverHost<EmptyView>.panelOrigin(
            trigger: NSRect(x: 0, y: 400, width: 50, height: 20),
            size: NSSize(width: 200, height: 780), visible: visible)
        #expect(tall.y >= 0 && tall.y + 780 <= 800)
    }
}
