import XCTest
@testable import PullPathAR

final class RouteMathTests: XCTestCase {
    func testThreeDimensionalDistance() {
        let start = RouteVector3(x: 0, y: 0, z: 0)
        let end = RouteVector3(x: 3, y: 4, z: 12)
        XCTAssertEqual(RouteMath.distance(from: start, to: end), 13, accuracy: 0.000_001)
    }

    func testTotalLengthUsesConsecutiveSegments() {
        let points = [
            RouteVector3(x: 0, y: 0, z: 0),
            RouteVector3(x: 3, y: 4, z: 0),
            RouteVector3(x: 3, y: 4, z: 12)
        ]
        XCTAssertEqual(RouteMath.segmentLengths(points: points), [5, 12])
        XCTAssertEqual(RouteMath.totalLength(points: points), 17, accuracy: 0.000_001)
    }

    func testSlackCombinesFixedAndPercentAllowance() {
        XCTAssertEqual(
            RouteMath.slackLength(baseMeters: 100, fixedMeters: 5, percent: 10),
            15,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            RouteMath.requiredLength(baseMeters: 100, fixedSlackMeters: 5, slackPercent: 10),
            115,
            accuracy: 0.000_001
        )
    }

    func testNegativeSlackInputsAreClamped() {
        XCTAssertEqual(
            RouteMath.requiredLength(baseMeters: 20, fixedSlackMeters: -5, slackPercent: -10),
            20,
            accuracy: 0.000_001
        )
    }

    func testImperialConversionRoundTrip() {
        let feet = RouteMath.metersToFeet(1)
        XCTAssertEqual(feet, 3.280_839_895, accuracy: 0.000_000_001)
        XCTAssertEqual(RouteMath.feetToMeters(feet), 1, accuracy: 0.000_000_001)
    }

    func testReelAssessmentFitAndShortage() {
        let fit = RouteMath.reelAssessment(requiredMeters: 80, availableMeters: 100)
        XCTAssertTrue(fit.fits)
        XCTAssertEqual(fit.remainingMeters, 20, accuracy: 0.000_001)
        XCTAssertEqual(fit.shortageMeters, 0, accuracy: 0.000_001)

        let shortage = RouteMath.reelAssessment(requiredMeters: 120, availableMeters: 100)
        XCTAssertFalse(shortage.fits)
        XCTAssertEqual(shortage.remainingMeters, 0, accuracy: 0.000_001)
        XCTAssertEqual(shortage.shortageMeters, 20, accuracy: 0.000_001)
    }
    func testGeometrySummaryUsesThreeDimensionalRoute() {
        let points = [
            RouteVector3(x: 0, y: 0, z: 0),
            RouteVector3(x: 3, y: 4, z: 0),
            RouteVector3(x: 3, y: 1, z: 4)
        ]
        let summary = RouteMath.geometrySummary(points: points)
        XCTAssertEqual(summary.horizontalTravelMeters, 7, accuracy: 0.000_001)
        XCTAssertEqual(summary.verticalTravelMeters, 7, accuracy: 0.000_001)
        XCTAssertEqual(summary.elevationRangeMeters, 4, accuracy: 0.000_001)
        XCTAssertEqual(summary.straightLineMeters, Double(26).squareRoot(), accuracy: 0.000_001)
    }

}
