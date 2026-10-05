// FineTuneTests/DevicePriorityRegistrationTests.swift
import Foundation
import Testing
@testable import FineTune

@MainActor
struct DevicePriorityRegistrationTests {
    private func makeSettings() -> SettingsManager {
        SettingsManager(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    @Test func appendsByDefault() {
        let s = makeSettings()
        s.ensureDeviceInPriority("speakers")
        s.ensureDeviceInPriority("dac")
        #expect(s.devicePriorityOrder == ["speakers", "dac"])
    }

    /// A newly connected Bluetooth device outranks the always-connected speakers.
    @Test func atTopRanksNewDeviceFirst() {
        let s = makeSettings()
        s.ensureDeviceInPriority("speakers")
        s.ensureDeviceInPriority("airpods", atTop: true)
        #expect(s.devicePriorityOrder == ["airpods", "speakers"])
    }

    /// A device the user already ranked must not be moved by a reconnect.
    @Test func knownDeviceKeepsUserRank() {
        let s = makeSettings()
        s.ensureDeviceInPriority("speakers")
        s.ensureDeviceInPriority("airpods")
        s.ensureDeviceInPriority("airpods", atTop: true)
        #expect(s.devicePriorityOrder == ["speakers", "airpods"])
    }
}
