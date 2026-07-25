// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

import Foundation
@testable import OmniWM
import XCTest

final class QuakeTerminalAppearanceSettingsTests: XCTestCase {
    func testBackgroundBlurDefaultsToOff() {
        let defaults = SettingsExport.defaults()

        XCTAssertEqual(
            defaults.quakeTerminalBackgroundBlurRadius,
            QuakeTerminalAppearancePolicy.disabledBackgroundBlurRadius
        )
    }

    func testNormalizedBackgroundBlurRadiusClampsToSupportedRange() {
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedBackgroundBlurRadius(-30), 0)
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedBackgroundBlurRadius(0), 0)
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedBackgroundBlurRadius(20), 20)
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedBackgroundBlurRadius(1000), 100)
    }

    func testBackgroundBlurIsOnlyVisibleThroughATranslucentTerminal() {
        let policy = QuakeTerminalAppearancePolicy.self

        XCTAssertFalse(policy.backgroundBlurIsHiddenByOpaqueBackground(radius: 0, opacity: 1.0))
        XCTAssertFalse(policy.backgroundBlurIsHiddenByOpaqueBackground(radius: 20, opacity: 0.85))
        XCTAssertTrue(policy.backgroundBlurIsHiddenByOpaqueBackground(radius: 20, opacity: 1.0))
    }

    @MainActor
    func testCornerStyleDefaultsToSquareWithACustomRadiusSeededFromMacOS() {
        let defaults = SettingsExport.defaults()

        XCTAssertEqual(defaults.quakeTerminalCornerStyle, QuakeTerminalCornerStyle.square.rawValue)
        XCTAssertEqual(defaults.quakeTerminalCornerRadius, GlobalWindowCornerPreferences.stockRadius)
    }

    @MainActor
    func testResolvedCornerRadiusFollowsTheSelectedStyle() {
        let policy = QuakeTerminalAppearancePolicy.self

        XCTAssertEqual(
            policy.resolvedCornerRadius(style: .square, customRadius: 24, systemRadius: 16),
            0
        )
        XCTAssertEqual(
            policy.resolvedCornerRadius(style: .systemDefault, customRadius: 24, systemRadius: 16),
            16
        )
        XCTAssertEqual(
            policy.resolvedCornerRadius(style: .custom, customRadius: 24, systemRadius: 16),
            24
        )
    }

    @MainActor
    func testResolvedCornerRadiusClampsWhateverTheSourceReports() {
        let policy = QuakeTerminalAppearancePolicy.self

        XCTAssertEqual(
            policy.resolvedCornerRadius(style: .systemDefault, customRadius: 0, systemRadius: 900),
            64
        )
        XCTAssertEqual(
            policy.resolvedCornerRadius(style: .custom, customRadius: -5, systemRadius: 16),
            0
        )
        XCTAssertEqual(
            policy.resolvedCornerRadius(style: .systemDefault, customRadius: 0, systemRadius: .nan),
            0
        )
    }

    func testNormalizedCornerRadiusClampsAndRejectsNonFiniteValues() {
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedCornerRadius(-8), 0)
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedCornerRadius(12.5), 12.5)
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedCornerRadius(500), 64)
        // Non-finite falls back to the default, matching normalizedDimensionPercent.
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedCornerRadius(.nan), 0)
        XCTAssertEqual(QuakeTerminalAppearancePolicy.normalizedCornerRadius(.infinity), 0)
    }

    func testFloatingTerminalRoundsEveryCorner() {
        let corners = QuakeTerminalAppearancePolicy.roundedCorners(
            frame: CGRect(x: 400, y: 300, width: 800, height: 400),
            visibleFrame: CGRect(x: 0, y: 0, width: 1600, height: 1000)
        )

        XCTAssertEqual(
            corners,
            [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        )
    }

    func testCornersFlushWithAScreenEdgeStaySquare() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1600, height: 1000)

        // Docked to the top: only the two bottom corners round.
        let topDocked = QuakeTerminalAppearancePolicy.roundedCorners(
            frame: CGRect(x: 400, y: 600, width: 800, height: 400),
            visibleFrame: visibleFrame
        )
        XCTAssertEqual(topDocked, [.layerMinXMinYCorner, .layerMaxXMinYCorner])

        // Docked to the left: only the two right-hand corners round.
        let leftDocked = QuakeTerminalAppearancePolicy.roundedCorners(
            frame: CGRect(x: 0, y: 300, width: 800, height: 400),
            visibleFrame: visibleFrame
        )
        XCTAssertEqual(leftDocked, [.layerMaxXMinYCorner, .layerMaxXMaxYCorner])

        // Full-screen: nothing rounds.
        let fullScreen = QuakeTerminalAppearancePolicy.roundedCorners(
            frame: visibleFrame,
            visibleFrame: visibleFrame
        )
        XCTAssertEqual(fullScreen, [])
    }

    func testRoundTripsCornerStyleAndRadiusInQuakeTerminalTable() throws {
        var export = SettingsExport.defaults()
        export.quakeTerminalCornerStyle = QuakeTerminalCornerStyle.custom.rawValue
        export.quakeTerminalCornerRadius = 12.5

        let data = try SettingsTOMLCodec.encode(export)
        let toml = String(decoding: data, as: UTF8.self)
        let decoded = try SettingsTOMLCodec.decode(data)

        XCTAssertTrue(toml.contains("cornerStyle = \"custom\""))
        XCTAssertTrue(toml.contains("cornerRadius = 12.5"))
        XCTAssertEqual(decoded.quakeTerminalCornerStyle, "custom")
        XCTAssertEqual(decoded.quakeTerminalCornerRadius, 12.5)
    }

    @MainActor
    func testConfigWithoutCornerKeysDecodesToSquare() throws {
        let defaults = SettingsExport.defaults()
        var toml = String(decoding: try SettingsTOMLCodec.encode(defaults), as: UTF8.self)
        toml = removingValue(in: toml, table: "quakeTerminal", key: "cornerStyle")
        toml = removingValue(in: toml, table: "quakeTerminal", key: "cornerRadius")

        let decoded = try SettingsTOMLCodec.decode(Data(toml.utf8))
        XCTAssertNil(decoded.quakeTerminalCornerStyle)
        XCTAssertNil(decoded.quakeTerminalCornerRadius)

        let settings = makeSettingsStore()
        settings.applyExport(decoded)
        XCTAssertEqual(settings.quakeTerminalCornerStyle, .square)
        XCTAssertEqual(
            QuakeTerminalAppearancePolicy.resolvedCornerRadius(
                style: settings.quakeTerminalCornerStyle,
                customRadius: settings.quakeTerminalCornerRadius,
                systemRadius: GlobalWindowCornerPreferences.stockRadius
            ),
            QuakeTerminalAppearancePolicy.squareCornerRadius
        )
    }

    @MainActor
    func testUnknownCornerStyleFallsBackToSquare() {
        let settings = makeSettingsStore()
        var export = SettingsExport.defaults()
        export.quakeTerminalCornerStyle = "rounded-ish"

        settings.applyExport(export)

        XCTAssertEqual(settings.quakeTerminalCornerStyle, .square)
    }

    @MainActor
    func testApplyExportClampsCornerRadius() {
        let settings = makeSettingsStore()
        var export = SettingsExport.defaults()

        export.quakeTerminalCornerRadius = -3
        settings.applyExport(export)
        XCTAssertEqual(settings.quakeTerminalCornerRadius, 0)

        export.quakeTerminalCornerRadius = 900
        settings.applyExport(export)
        XCTAssertEqual(settings.quakeTerminalCornerRadius, 64)
        XCTAssertEqual(settings.toExport().quakeTerminalCornerRadius, 64)
    }

    @MainActor
    func testAutosavePersistsCornerRadius() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("OmniWMQuakeCornerAutosaveTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        let persistence = SettingsFilePersistence(
            directory: root.appendingPathComponent("config", isDirectory: true),
            startWatching: false,
            deferSaves: false
        )
        let settings = SettingsStore(
            persistence: persistence,
            runtimeState: RuntimeStateStore(
                directory: root.appendingPathComponent("state", isDirectory: true),
                deferSaves: false
            ),
            autosaveEnabled: true
        )

        settings.quakeTerminalCornerStyle = .custom
        settings.quakeTerminalCornerRadius = 18

        let persisted = try SettingsTOMLCodec.decode(Data(contentsOf: persistence.fileURL))
        XCTAssertEqual(persisted.quakeTerminalCornerStyle, "custom")
        XCTAssertEqual(persisted.quakeTerminalCornerRadius, 18)
    }

    func testRoundTripsBackgroundBlurRadiusInQuakeTerminalTable() throws {
        var export = SettingsExport.defaults()
        export.quakeTerminalBackgroundBlurRadius = 35

        let data = try SettingsTOMLCodec.encode(export)
        let toml = String(decoding: data, as: UTF8.self)
        let decoded = try SettingsTOMLCodec.decode(data)

        XCTAssertTrue(toml.contains("[quakeTerminal]"))
        XCTAssertTrue(toml.contains("backgroundBlurRadius = 35"))
        XCTAssertEqual(decoded.quakeTerminalBackgroundBlurRadius, 35)
    }

    @MainActor
    func testConfigWithoutBackgroundBlurRadiusDecodesToOff() throws {
        let defaults = SettingsExport.defaults()
        let toml = String(decoding: try SettingsTOMLCodec.encode(defaults), as: UTF8.self)
        let stripped = removingValue(in: toml, table: "quakeTerminal", key: "backgroundBlurRadius")

        let decoded = try SettingsTOMLCodec.decode(Data(stripped.utf8))
        XCTAssertNil(decoded.quakeTerminalBackgroundBlurRadius)

        let settings = makeSettingsStore()
        settings.applyExport(decoded)
        XCTAssertEqual(
            settings.quakeTerminalBackgroundBlurRadius,
            QuakeTerminalAppearancePolicy.disabledBackgroundBlurRadius
        )
    }

    func testMalformedBackgroundBlurRadiusRejectsDecode() throws {
        let defaults = String(
            decoding: try SettingsTOMLCodec.encode(SettingsExport.defaults()),
            as: UTF8.self
        )
        let malformed = replacingValue(
            in: defaults,
            table: "quakeTerminal",
            key: "backgroundBlurRadius",
            with: "\"heavy\""
        )

        XCTAssertThrowsError(try SettingsTOMLCodec.decode(Data(malformed.utf8)))
    }

    @MainActor
    func testApplyExportClampsBackgroundBlurRadius() {
        let settings = makeSettingsStore()
        var export = SettingsExport.defaults()

        export.quakeTerminalBackgroundBlurRadius = -5
        settings.applyExport(export)
        XCTAssertEqual(settings.quakeTerminalBackgroundBlurRadius, 0)

        export.quakeTerminalBackgroundBlurRadius = 400
        settings.applyExport(export)
        XCTAssertEqual(settings.quakeTerminalBackgroundBlurRadius, 100)
        XCTAssertEqual(settings.toExport().quakeTerminalBackgroundBlurRadius, 100)
    }

    @MainActor
    func testAssigningOutOfRangeBackgroundBlurRadiusNormalizesInPlace() {
        let settings = makeSettingsStore()

        settings.quakeTerminalBackgroundBlurRadius = 250
        XCTAssertEqual(settings.quakeTerminalBackgroundBlurRadius, 100)

        settings.quakeTerminalBackgroundBlurRadius = -1
        XCTAssertEqual(settings.quakeTerminalBackgroundBlurRadius, 0)
    }

    @MainActor
    func testAutosavePersistsBackgroundBlurRadius() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("OmniWMQuakeAppearanceAutosaveTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        let persistence = SettingsFilePersistence(
            directory: root.appendingPathComponent("config", isDirectory: true),
            startWatching: false,
            deferSaves: false
        )
        let settings = SettingsStore(
            persistence: persistence,
            runtimeState: RuntimeStateStore(
                directory: root.appendingPathComponent("state", isDirectory: true),
                deferSaves: false
            ),
            autosaveEnabled: true
        )

        settings.quakeTerminalBackgroundBlurRadius = 40

        let persisted = try SettingsTOMLCodec.decode(Data(contentsOf: persistence.fileURL))
        XCTAssertEqual(persisted.quakeTerminalBackgroundBlurRadius, 40)
    }

    private func replacingValue(
        in toml: String,
        table: String,
        key: String,
        with replacement: String
    ) -> String {
        transform(toml) { currentTable, line in
            guard currentTable == table, line.hasPrefix("\(key) = ") else { return line }
            return "\(key) = \(replacement)"
        }
    }

    private func removingValue(in toml: String, table: String, key: String) -> String {
        transform(toml) { currentTable, line in
            guard currentTable == table, line.hasPrefix("\(key) = ") else { return line }
            return nil
        }
    }

    private func transform(
        _ toml: String,
        _ operation: (_ table: String, _ line: String) -> String?
    ) -> String {
        var currentTable = ""
        return toml
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { substring -> String? in
                let line = String(substring)
                if line.hasPrefix("["), line.hasSuffix("]") {
                    currentTable = String(line.dropFirst().dropLast())
                }
                return operation(currentTable, line)
            }
            .joined(separator: "\n")
    }

    @MainActor
    private func makeSettingsStore() -> SettingsStore {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("OmniWMQuakeAppearanceSettingsTests-\(UUID().uuidString)", isDirectory: true)
        return SettingsStore(
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
    }
}
