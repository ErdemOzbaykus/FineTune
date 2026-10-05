// FineTune/Audio/AirPods/AirPodsListeningMode.swift
import CoreAudio
import Foundation

/// AirPods listening modes, as exposed by the undocumented Core Audio HAL properties
/// `lstm` (current mode) and `lsms` (supported-mode mask) on Apple Bluetooth outputs.
///
/// The raw values and property selectors follow the MIT-licensed pods-control project
/// (github.com/raulgg/pods-control). Undocumented API: Apple may change it in any macOS release.
enum AirPodsListeningMode: UInt32, CaseIterable, Identifiable {
    case off = 1
    case noiseCancellation = 2
    case transparency = 3
    case adaptive = 4

    var id: UInt32 { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .noiseCancellation: return "Noise Cancellation"
        case .transparency: return "Transparency"
        case .adaptive: return "Adaptive"
        }
    }

    var symbolName: String {
        switch self {
        case .off: return "ear"
        case .noiseCancellation: return "ear.badge.waveform"
        case .transparency: return "person.wave.2"
        case .adaptive: return "sparkles"
        }
    }

    /// Decodes the `lsms` bit mask. The mask never lists Off (the user's "Allow Off" setting
    /// is not exposed), so Off is always offered and verified by read-back after writing.
    static func supported(fromMask mask: UInt32) -> [AirPodsListeningMode] {
        var modes: [AirPodsListeningMode] = [.off]
        if mask & 0b001 != 0 { modes.append(.noiseCancellation) }
        if mask & 0b010 != 0 { modes.append(.transparency) }
        if mask & 0b100 != 0 { modes.append(.adaptive) }
        return modes
    }
}

/// Reads and writes the listening mode of a connected AirPods output via Core Audio.
enum AirPodsListeningModeController {
    private static let currentSelector: AudioObjectPropertySelector = 0x6C73_746D  // 'lstm'
    private static let supportSelector: AudioObjectPropertySelector = 0x6C73_6D73  // 'lsms'

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private static func readUInt32(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
        var addr = address(selector)
        guard AudioObjectHasProperty(id, &addr) else { return nil }
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value) == noErr else { return nil }
        return value
    }

    /// The device that exposes the listening-mode property: the output itself, or a sibling
    /// endpoint of the same accessory (same UID before ":").
    static func controlDevice(for deviceID: AudioDeviceID, uid: String) -> AudioDeviceID? {
        if readUInt32(deviceID, currentSelector) != nil { return deviceID }
        guard let base = uid.split(separator: ":").first else { return nil }
        return ((try? AudioObjectID.readDeviceList()) ?? []).first { id in
            id != deviceID
                && ((try? id.readDeviceUID()) ?? "").hasPrefix(String(base))
                && readUInt32(id, currentSelector) != nil
        }
    }

    static func supportedModes(of id: AudioDeviceID) -> [AirPodsListeningMode] {
        AirPodsListeningMode.supported(fromMask: readUInt32(id, supportSelector) ?? 0)
    }

    static func currentMode(of id: AudioDeviceID) -> AirPodsListeningMode? {
        readUInt32(id, currentSelector).flatMap(AirPodsListeningMode.init(rawValue:))
    }

    /// Writes `mode`, then waits up to ~1.5 s for macOS to report it. Returns the mode the
    /// device actually ended up in, which differs from `mode` when the write was refused
    /// (e.g. Off while "Allow Off" is disabled).
    static func setMode(_ mode: AirPodsListeningMode, on id: AudioDeviceID) async -> AirPodsListeningMode? {
        var addr = address(currentSelector)
        var raw = mode.rawValue
        let status = AudioObjectSetPropertyData(id, &addr, 0, nil, UInt32(MemoryLayout<UInt32>.size), &raw)
        guard status == noErr else { return currentMode(of: id) }
        for _ in 0..<15 {
            if currentMode(of: id) == mode { return mode }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return currentMode(of: id)
    }
}
