// FineTuneTests/AirPodsListeningModeTests.swift
import Testing
@testable import FineTune

struct AirPodsListeningModeTests {
    @Test func rawValuesMatchTheHALProtocol() {
        #expect(AirPodsListeningMode.off.rawValue == 1)
        #expect(AirPodsListeningMode.noiseCancellation.rawValue == 2)
        #expect(AirPodsListeningMode.transparency.rawValue == 3)
        #expect(AirPodsListeningMode.adaptive.rawValue == 4)
    }

    /// Mask 0b111 (seen on AirPods Pro) offers every mode; Off is always available to try.
    @Test func fullMaskOffersAllModes() {
        #expect(AirPodsListeningMode.supported(fromMask: 0b111)
            == [.off, .noiseCancellation, .transparency, .adaptive])
    }

    @Test func partialMaskOnlyOffersSupportedModes() {
        #expect(AirPodsListeningMode.supported(fromMask: 0b010) == [.off, .transparency])
        #expect(AirPodsListeningMode.supported(fromMask: 0) == [.off])
    }

    @Test func unknownMaskBitsAreIgnored() {
        #expect(AirPodsListeningMode.supported(fromMask: 0b1000_0001) == [.off, .noiseCancellation])
    }
}
