// FineTune/Views/Components/AirPodsModePicker.swift
import CoreAudio
import SwiftUI

/// Icon button that opens a list of AirPods listening modes (Noise Cancellation, Transparency,
/// Adaptive, Off). Renders nothing unless the device exposes the listening-mode control,
/// so it is safe to place on every output device row.
struct AirPodsModePicker: View {
    let device: AudioDevice

    @State private var controlID: AudioDeviceID?
    @State private var modes: [AirPodsListeningMode] = []
    @State private var current: AirPodsListeningMode?
    @State private var isExpanded = false
    @State private var isButtonHovered = false
    @State private var isApplying = false

    @Environment(\.appearancePreference) private var appearancePreference

    private let popoverWidth: CGFloat = 200

    var body: some View {
        // The zero-size anchor keeps `.task` alive while the control is hidden (an empty Group
        // would never run it).
        HStack(spacing: 0) {
            Color.clear.frame(width: 0, height: 0)
            if controlID != nil {
                triggerButton
                    .background(
                        PopoverHost(
                            isPresented: $isExpanded,
                            preferredColorScheme: appearancePreference.swiftUIColorScheme,
                            nsAppearance: appearancePreference.nsAppearance
                        ) {
                            popoverContent
                        }
                    )
            }
        }
        .task(id: device.id) { discover() }
        .onChange(of: isExpanded) { _, expanded in
            if expanded { refresh() }
        }
    }

    private func discover() {
        guard device.id.readTransportType() == .bluetooth || device.id.readTransportType() == .bluetoothLE else {
            controlID = nil
            return
        }
        controlID = AirPodsListeningModeController.controlDevice(for: device.id, uid: device.uid)
        refresh()
    }

    private func refresh() {
        guard let id = controlID else { return }
        modes = AirPodsListeningModeController.supportedModes(of: id)
        current = AirPodsListeningModeController.currentMode(of: id)
    }

    private func select(_ mode: AirPodsListeningMode) {
        guard let id = controlID, !isApplying else { return }
        isApplying = true
        Task { @MainActor in
            // Shows the mode macOS actually settled on, so a refused write snaps back.
            current = await AirPodsListeningModeController.setMode(mode, on: id)
            isApplying = false
            withAnimation(.easeOut(duration: 0.15)) { isExpanded = false }
        }
    }

    private var triggerButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
        } label: {
            Image(systemName: current?.symbolName ?? "ear")
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    isExpanded ? DesignTokens.Colors.accentPrimary
                        : isButtonHovered ? DesignTokens.Colors.interactiveHover
                        : DesignTokens.Colors.interactiveDefault
                )
                .frame(
                    minWidth: DesignTokens.Dimensions.minTouchTarget,
                    minHeight: DesignTokens.Dimensions.minTouchTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isButtonHovered = $0 }
        .help("AirPods: \(current?.displayName ?? "Listening mode")")
        .animation(DesignTokens.Animation.hover, value: isButtonHovered)
    }

    private var popoverContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Listening Mode")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)

            ForEach(modes) { mode in
                Button { select(mode) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode.symbolName)
                            .frame(width: 18)
                        Text(mode.displayName)
                            .font(.system(size: 13))
                        Spacer(minLength: 0)
                        if mode == current {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DesignTokens.Colors.accentPrimary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isApplying)
            }
            .padding(.bottom, 0)
        }
        .padding(.bottom, 6)
        .frame(width: popoverWidth)
        .background(
            VisualEffectBackground(material: .menu, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 0.5)
        }
    }
}
