// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

import Foundation
import QuartzCore

enum QuakeTerminalAppearancePolicy {
    static let minimumBackgroundBlurRadius = 0
    static let maximumBackgroundBlurRadius = 100
    static let disabledBackgroundBlurRadius = 0

    static let squareCornerRadius = 0.0

    /// Same ceiling the system-wide window corner setting uses, so the two sliders agree.
    static let maximumCornerRadius = 64.0

    /// Radius Ghostty uses for `background-blur = true`; the value the UI offers as "on".
    static let defaultEnabledBackgroundBlurRadius = 20

    static func normalizedBackgroundBlurRadius(_ value: Int) -> Int {
        min(max(value, minimumBackgroundBlurRadius), maximumBackgroundBlurRadius)
    }

    /// Blur only shows through translucent pixels, so a fully opaque terminal renders
    /// identically with the blur on or off.
    static func backgroundBlurIsHiddenByOpaqueBackground(radius: Int, opacity: Double) -> Bool {
        normalizedBackgroundBlurRadius(radius) > disabledBackgroundBlurRadius && opacity >= 1.0
    }

    static func normalizedCornerRadius(_ value: Double) -> Double {
        guard value.isFinite else { return squareCornerRadius }
        return min(max(value, squareCornerRadius), maximumCornerRadius)
    }

    /// `systemRadius` is what macOS draws for a standard window, resolved by the caller so
    /// this stays a pure function.
    static func resolvedCornerRadius(
        style: QuakeTerminalCornerStyle,
        customRadius: Double,
        systemRadius: Double
    ) -> Double {
        switch style {
        case .square:
            squareCornerRadius
        case .systemDefault:
            normalizedCornerRadius(systemRadius)
        case .custom:
            normalizedCornerRadius(customRadius)
        }
    }

    /// A corner flush against the screen edge stays square. Rounding it would cut a notch
    /// out of a docked terminal and show a sliver of desktop through it.
    static func roundedCorners(
        frame: CGRect,
        visibleFrame: CGRect,
        tolerance: CGFloat = 1
    ) -> CACornerMask {
        var corners: CACornerMask = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]
        guard visibleFrame.width > 0, visibleFrame.height > 0 else { return corners }

        if abs(frame.minX - visibleFrame.minX) <= tolerance {
            corners.subtract([.layerMinXMinYCorner, .layerMinXMaxYCorner])
        }
        if abs(frame.maxX - visibleFrame.maxX) <= tolerance {
            corners.subtract([.layerMaxXMinYCorner, .layerMaxXMaxYCorner])
        }
        if abs(frame.minY - visibleFrame.minY) <= tolerance {
            corners.subtract([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        }
        if abs(frame.maxY - visibleFrame.maxY) <= tolerance {
            corners.subtract([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        return corners
    }
}
