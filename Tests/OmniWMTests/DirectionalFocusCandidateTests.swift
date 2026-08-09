// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

import ApplicationServices
import CoreGraphics
import Foundation
@testable import OmniWM
import XCTest

@MainActor
final class DirectionalFocusCandidateTests: XCTestCase {
    func testHandsOffSurfaceIsNotAFocusCandidate() throws {
        let fixture = try makeFixture()
        let tiled = addWindow(
            fixture,
            pid: 8101,
            windowId: 81,
            mode: .tiling,
            frame: CGRect(x: 5, y: 5, width: 800, height: 900)
        )
        let handsOff = addWindow(
            fixture,
            pid: 8102,
            windowId: 82,
            mode: .floating,
            frame: CGRect(x: 900, y: 5, width: 700, height: 30)
        )
        fixture.controller.workspaceManager.setInteractionPolicy(.handsOffSurface, for: handsOff)

        let tokens = fixture.controller
            .directionalFocusCandidates(in: fixture.workspaceId)
            .map(\.token)

        XCTAssertTrue(tokens.contains(tiled))
        XCTAssertFalse(tokens.contains(handsOff))
    }

    func testFocusableFloatingSurfaceRemainsACandidate() throws {
        let fixture = try makeFixture()
        let floating = addWindow(
            fixture,
            pid: 8103,
            windowId: 83,
            mode: .floating,
            frame: CGRect(x: 900, y: 5, width: 700, height: 30)
        )
        fixture.controller.workspaceManager.setInteractionPolicy(.full, for: floating)

        let tokens = fixture.controller
            .directionalFocusCandidates(in: fixture.workspaceId)
            .map(\.token)

        XCTAssertTrue(tokens.contains(floating))
    }

    private struct Fixture {
        let controller: WMController
        let workspaceId: WorkspaceDescriptor.ID
        let monitor: Monitor
    }

    private func addWindow(
        _ fixture: Fixture,
        pid: pid_t,
        windowId: Int,
        mode: TrackedWindowMode,
        frame: CGRect
    ) -> WindowToken {
        let token = fixture.controller.workspaceManager.addWindow(
            AXWindowRef(element: AXUIElementCreateApplication(pid), windowId: windowId),
            pid: pid,
            windowId: windowId,
            to: fixture.workspaceId,
            mode: mode
        )
        switch mode {
        case .floating:
            fixture.controller.workspaceManager.updateFloatingGeometry(
                frame: frame,
                for: token,
                referenceMonitor: fixture.monitor,
                restoreToFloating: true
            )
        case .tiling:
            fixture.controller.axManager.confirmFrameWrite(for: windowId, frame: frame)
        }
        return token
    }

    private func makeFixture() throws -> Fixture {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DirectionalFocusCandidateTests-\(UUID().uuidString)", isDirectory: true)
        let settings = SettingsStore(
            persistence: SettingsFilePersistence(
                directory: root.appendingPathComponent("config", isDirectory: true),
                startWatching: false,
                deferSaves: false
            ),
            runtimeState: RuntimeStateStore(
                directory: root.appendingPathComponent("state", isDirectory: true),
                deferSaves: false
            ),
            autosaveEnabled: false
        )
        let controller = WMController(
            settings: settings,
            windowFocusOperations: WindowFocusOperations(
                activateApp: { _ in },
                focusSpecificWindow: { _, _, _ in },
                raiseWindow: { _ in }
            )
        )
        let frame = CGRect(x: 0, y: 0, width: 1600, height: 900)
        let monitor = Monitor(
            id: .init(displayId: 491_000),
            displayId: 491_000,
            frame: frame,
            visibleFrame: frame,
            hasNotch: false,
            name: "Directional Focus Candidate Tests"
        )
        controller.workspaceManager.applyMonitorConfigurationChange([monitor])
        controller.workspaceManager.applySettings()

        let niriEngine = NiriLayoutEngine()
        niriEngine.animationClock = controller.animationClock
        controller.niriEngine = niriEngine
        controller.niriLayoutHandler.syncMonitorsToNiriEngine()

        let workspaceId = try XCTUnwrap(
            controller.workspaceManager.workspaceId(for: "1", createIfMissing: false)
        )
        XCTAssertTrue(controller.workspaceManager.setActiveWorkspace(workspaceId, on: monitor.id))
        controller.layoutRefreshController.resetState()

        return Fixture(controller: controller, workspaceId: workspaceId, monitor: monitor)
    }
}
