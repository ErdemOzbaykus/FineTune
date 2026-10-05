// FineTuneTests/PopupDimensionsTests.swift
import CoreGraphics
import Testing
@testable import FineTune

struct PopupDimensionsTests {
    /// #430: Spacious on a 13" laptop (~860pt visible) must not exceed the screen.
    @Test(arguments: [MenuBarPopupSize.compact, .comfortable, .spacious])
    func popupFitsVisibleHeight(size: MenuBarPopupSize) {
        let d = size.dimensions
        for visible: CGFloat in [600, 760, 860, 1100] {
            let body = d.contentHeight(fittingVisibleHeight: visible)
            #expect(body + 2 * d.contentPadding + PopupDimensions.chromeHeight <= max(visible, 200 + 2 * d.contentPadding + PopupDimensions.chromeHeight))
        }
    }

    @Test func tallScreenKeepsConfiguredCeiling() {
        let d = MenuBarPopupSize.spacious.dimensions
        #expect(d.contentHeight(fittingVisibleHeight: 2000) == d.maxContentHeight)
    }

    @Test func neverCollapsesBelowUsableHeight() {
        #expect(MenuBarPopupSize.compact.dimensions.contentHeight(fittingVisibleHeight: 50) == 200)
    }
}
