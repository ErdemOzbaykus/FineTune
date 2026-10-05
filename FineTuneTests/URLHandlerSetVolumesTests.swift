// FineTuneTests/URLHandlerSetVolumesTests.swift
import Foundation
import Testing
@testable import FineTune

@MainActor
private final class MockEngine: URLHandlerEngine {
    let settingsManager: SettingsManager
    var apps: [AudioApp] { [] }
    var inactiveGains: [String: Float] = [:]

    init() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        settingsManager = SettingsManager(directory: dir)
    }

    func setVolume(for app: AudioApp, to volume: Float) {}
    func getVolume(for app: AudioApp) -> Float { 1 }
    func setMute(for app: AudioApp, to muted: Bool) {}
    func getMute(for app: AudioApp) -> Bool { false }
    func setDevice(for app: AudioApp, deviceUID: String?) {}
    func setVolumeForInactive(identifier: String, to volume: Float) { inactiveGains[identifier] = volume }
    func setMuteForInactive(identifier: String, to muted: Bool) {}
    func getMuteForInactive(identifier: String) -> Bool { false }
}

@MainActor
struct URLHandlerSetVolumesTests {
    /// #434: volume=N must show N% on the slider, not sqrt(N/100).
    @Test(arguments: [0, 10, 20, 30, 50, 100])
    func sliderShowsRequestedPercent(percent: Int) {
        let engine = MockEngine()
        URLHandler(audioEngine: engine)
            .handleURL(URL(string: "finetune://set-volumes?app=com.a&volume=\(percent)")!)
        let gain = engine.inactiveGains["com.a"]!
        #expect(abs(VolumeMapping.gainToSlider(gain) - Double(percent) / 100) < 0.001)
    }
}
