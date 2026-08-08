// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

import CoreGraphics
import Foundation

struct DirectionalFocusCandidate: Equatable {
    let token: WindowToken
    let frame: CGRect
    let isFloating: Bool
}

enum DirectionalFocusResolver {
    static let axisEpsilon: CGFloat = 1

    static func nearest(
        direction: Direction,
        from origin: CGRect,
        candidates: [DirectionalFocusCandidate]
    ) -> DirectionalFocusCandidate? {
        let scored = candidates.compactMap { candidate -> (DirectionalFocusCandidate, CGFloat, CGFloat, Bool)? in
            guard let advance = axisAdvance(direction: direction, from: origin, to: candidate.frame) else {
                return nil
            }
            return (
                candidate,
                advance,
                perpendicularDistance(direction: direction, from: origin, to: candidate.frame),
                overlapsPerpendicularly(direction: direction, origin, candidate.frame)
            )
        }
        guard !scored.isEmpty else { return nil }

        let overlapping = scored.filter(\.3)
        let pool = overlapping.isEmpty ? scored : overlapping

        return pool.min { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return lhs.2 < rhs.2
        }?.0
    }

    static func axisAdvance(
        direction: Direction,
        from origin: CGRect,
        to target: CGRect
    ) -> CGFloat? {
        let delta: CGFloat = switch direction {
        case .left: origin.midX - target.midX
        case .right: target.midX - origin.midX
        case .down: origin.midY - target.midY
        case .up: target.midY - origin.midY
        }
        return delta > axisEpsilon ? delta : nil
    }

    private static func perpendicularDistance(
        direction: Direction,
        from origin: CGRect,
        to target: CGRect
    ) -> CGFloat {
        switch direction {
        case .left,
             .right:
            abs(target.midY - origin.midY)
        case .up,
             .down:
            abs(target.midX - origin.midX)
        }
    }

    private static func overlapsPerpendicularly(
        direction: Direction,
        _ origin: CGRect,
        _ target: CGRect
    ) -> Bool {
        switch direction {
        case .left,
             .right:
            origin.minY < target.maxY && target.minY < origin.maxY
        case .up,
             .down:
            origin.minX < target.maxX && target.minX < origin.maxX
        }
    }
}
