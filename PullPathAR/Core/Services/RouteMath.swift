import Foundation

struct RouteVector3: Equatable, Sendable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct ReelAssessment: Equatable, Sendable {
    let fits: Bool
    let remainingMeters: Double
    let shortageMeters: Double
}

struct RouteGeometrySummary: Equatable, Sendable {
    let horizontalTravelMeters: Double
    let verticalTravelMeters: Double
    let elevationRangeMeters: Double
    let straightLineMeters: Double
}

enum RouteMath {
    static let feetPerMeter = 3.280_839_895

    static func distance(from a: RouteVector3, to b: RouteVector3) -> Double {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let dz = b.z - a.z
        return (dx * dx + dy * dy + dz * dz).squareRoot()
    }

    static func segmentLengths(points: [RouteVector3]) -> [Double] {
        guard points.count > 1 else { return [] }
        return zip(points, points.dropFirst()).map { distance(from: $0.0, to: $0.1) }
    }

    static func totalLength(points: [RouteVector3]) -> Double {
        segmentLengths(points: points).reduce(0, +)
    }

    static func slackLength(
        baseMeters: Double,
        fixedMeters: Double,
        percent: Double
    ) -> Double {
        let safeBase = max(0, baseMeters)
        let safeFixed = max(0, fixedMeters)
        let safePercent = max(0, percent)
        return safeFixed + (safeBase * safePercent / 100)
    }

    static func requiredLength(
        baseMeters: Double,
        fixedSlackMeters: Double,
        slackPercent: Double
    ) -> Double {
        let safeBase = max(0, baseMeters)
        return safeBase + slackLength(
            baseMeters: safeBase,
            fixedMeters: fixedSlackMeters,
            percent: slackPercent
        )
    }

    static func metersToFeet(_ meters: Double) -> Double {
        meters * feetPerMeter
    }

    static func feetToMeters(_ feet: Double) -> Double {
        feet / feetPerMeter
    }

    static func reelAssessment(requiredMeters: Double, availableMeters: Double) -> ReelAssessment {
        let required = max(0, requiredMeters)
        let available = max(0, availableMeters)
        let delta = available - required
        return ReelAssessment(
            fits: delta >= 0,
            remainingMeters: max(0, delta),
            shortageMeters: max(0, -delta)
        )
    }

    static func geometrySummary(points: [RouteVector3]) -> RouteGeometrySummary {
        guard let first = points.first, let last = points.last, points.count > 1 else {
            return RouteGeometrySummary(
                horizontalTravelMeters: 0,
                verticalTravelMeters: 0,
                elevationRangeMeters: 0,
                straightLineMeters: 0
            )
        }

        var horizontal = 0.0
        var vertical = 0.0
        for (a, b) in zip(points, points.dropFirst()) {
            let dx = b.x - a.x
            let dz = b.z - a.z
            horizontal += (dx * dx + dz * dz).squareRoot()
            vertical += abs(b.y - a.y)
        }

        let elevations = points.map(\.y)
        let range = (elevations.max() ?? 0) - (elevations.min() ?? 0)
        return RouteGeometrySummary(
            horizontalTravelMeters: horizontal,
            verticalTravelMeters: vertical,
            elevationRangeMeters: max(0, range),
            straightLineMeters: distance(from: first, to: last)
        )
    }

    static func formattedLength(
        meters: Double,
        unitSystem: UnitSystem,
        locale: Locale = .current
    ) -> String {
        let safeMeters = max(0, meters)
        let value: Double
        let unit: String

        switch unitSystem {
        case .metric:
            value = safeMeters
            unit = "m"
        case .imperial:
            value = metersToFeet(safeMeters)
            unit = "ft"
        }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(number) \(unit)"
    }

    static func vectors(from points: [RoutePoint]) -> [RouteVector3] {
        points
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { RouteVector3(x: $0.xMeters, y: $0.yMeters, z: $0.zMeters) }
    }
}
