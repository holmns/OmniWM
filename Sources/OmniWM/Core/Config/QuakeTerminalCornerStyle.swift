// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

enum QuakeTerminalCornerStyle: String, CaseIterable, Codable {
    case square
    case systemDefault
    case custom

    var displayName: String {
        switch self {
        case .square: "Square"
        case .systemDefault: "macOS Default"
        case .custom: "Custom"
        }
    }
}
