// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

import CoreGraphics
import Foundation
@testable import OmniWM
import XCTest

@MainActor
final class DirectionalFocusResolverTests: XCTestCase {
    private let origin = CGRect(x: 0, y: 100, width: 100, height: 100)

    func testPicksNearestCandidateToTheRight() {
        let near = candidate(1, CGRect(x: 150, y: 100, width: 100, height: 100), floating: true)
        let far = candidate(2, CGRect(x: 400, y: 100, width: 100, height: 100), floating: false)

        let target = DirectionalFocusResolver.nearest(
            direction: .right,
            from: origin,
            candidates: [far, near]
        )

        XCTAssertEqual(target, near)
    }

    func testIgnoresCandidatesBehindTheDirection() {
        let behind = candidate(1, CGRect(x: -300, y: 100, width: 100, height: 100), floating: true)

        XCTAssertNil(
            DirectionalFocusResolver.nearest(direction: .right, from: origin, candidates: [behind])
        )
        XCTAssertEqual(
            DirectionalFocusResolver.nearest(direction: .left, from: origin, candidates: [behind]),
            behind
        )
    }

    func testUpIsIncreasingYAndDownIsDecreasingY() {
        let above = candidate(1, CGRect(x: 0, y: 400, width: 100, height: 100), floating: true)
        let below = candidate(2, CGRect(x: 0, y: -200, width: 100, height: 100), floating: true)

        XCTAssertEqual(
            DirectionalFocusResolver.nearest(
                direction: .up,
                from: origin,
                candidates: [above, below]
            ),
            above
        )
        XCTAssertEqual(
            DirectionalFocusResolver.nearest(
                direction: .down,
                from: origin,
                candidates: [above, below]
            ),
            below
        )
    }

    func testPrefersCandidateSharingTheOriginRowOverANearerOffRowOne() {
        let offRow = candidate(1, CGRect(x: 150, y: 900, width: 100, height: 100), floating: true)
        let sameRow = candidate(2, CGRect(x: 300, y: 100, width: 100, height: 100), floating: true)

        XCTAssertEqual(
            DirectionalFocusResolver.nearest(
                direction: .right,
                from: origin,
                candidates: [offRow, sameRow]
            ),
            sameRow
        )
    }

    func testFallsBackToOffRowCandidateWhenNothingSharesTheRow() {
        let offRow = candidate(1, CGRect(x: 150, y: 900, width: 100, height: 100), floating: true)

        XCTAssertEqual(
            DirectionalFocusResolver.nearest(
                direction: .right,
                from: origin,
                candidates: [offRow]
            ),
            offRow
        )
    }

    func testCandidateAtTheSamePositionIsNotANeighbour() {
        let stacked = candidate(1, origin, floating: true)

        XCTAssertNil(
            DirectionalFocusResolver.nearest(direction: .right, from: origin, candidates: [stacked])
        )
    }

    func testEmptyCandidatesResolveToNil() {
        XCTAssertNil(
            DirectionalFocusResolver.nearest(direction: .left, from: origin, candidates: [])
        )
    }

    private func candidate(
        _ windowId: Int,
        _ frame: CGRect,
        floating: Bool
    ) -> DirectionalFocusCandidate {
        DirectionalFocusCandidate(
            token: WindowToken(pid: 9100, windowId: windowId),
            frame: frame,
            isFloating: floating
        )
    }
}
