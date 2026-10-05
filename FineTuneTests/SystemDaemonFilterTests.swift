// FineTuneTests/SystemDaemonFilterTests.swift
import Testing
@testable import FineTune

@MainActor
struct SystemDaemonFilterTests {
    /// #427: the Sound settings pane's audio extension must not be listed as an app.
    @Test func soundSettingsExtensionIsFiltered() {
        #expect(AudioProcessMonitor.isSystemDaemon(bundleID: "com.apple.Sound-Settings.extension", name: "extension"))
    }

    @Test func realAppsAreKept() {
        #expect(!AudioProcessMonitor.isSystemDaemon(bundleID: "com.google.Chrome", name: "Google Chrome"))
        #expect(!AudioProcessMonitor.isSystemDaemon(bundleID: "com.apple.Music", name: "Music"))
    }
}
