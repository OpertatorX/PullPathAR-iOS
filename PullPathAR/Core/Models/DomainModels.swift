import Foundation
import SwiftData

enum RouteStatus: String, CaseIterable, Codable, Identifiable {
    case draft
    case ready
    case pulled
    case verified

    var id: String { rawValue }
}

enum CableCategory: String, CaseIterable, Codable, Identifiable {
    case cat6
    case cat6a
    case fiber
    case coax
    case custom

    var id: String { rawValue }
}

enum UnitSystem: String, CaseIterable, Codable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }
}

enum RoutePointSource: String, Codable {
    case augmentedReality
    case manual
}

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var clientName: String
    var siteName: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        clientName: String = "",
        siteName: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.siteName = siteName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}

@Model
final class CableRoute {
    @Attribute(.unique) var id: UUID
    var projectID: UUID
    var name: String
    var profileID: UUID?
    var assignedReelID: UUID?
    var statusRaw: String
    var unitSystemRaw: String
    var fixedSlackMeters: Double
    var slackPercent: Double
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectID: UUID,
        name: String,
        profileID: UUID? = nil,
        assignedReelID: UUID? = nil,
        status: RouteStatus = .draft,
        unitSystem: UnitSystem = .metric,
        fixedSlackMeters: Double = 0,
        slackPercent: Double = 10,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.projectID = projectID
        self.name = name
        self.profileID = profileID
        self.assignedReelID = assignedReelID
        self.statusRaw = status.rawValue
        self.unitSystemRaw = unitSystem.rawValue
        self.fixedSlackMeters = max(0, fixedSlackMeters)
        self.slackPercent = max(0, slackPercent)
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var status: RouteStatus {
        get { RouteStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }
}

@Model
final class RoutePoint {
    @Attribute(.unique) var id: UUID
    var routeID: UUID
    var orderIndex: Int
    var xMeters: Double
    var yMeters: Double
    var zMeters: Double
    var sourceRaw: String
    var label: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        routeID: UUID,
        orderIndex: Int,
        xMeters: Double,
        yMeters: Double,
        zMeters: Double,
        source: RoutePointSource,
        label: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.routeID = routeID
        self.orderIndex = orderIndex
        self.xMeters = xMeters
        self.yMeters = yMeters
        self.zMeters = zMeters
        self.sourceRaw = source.rawValue
        self.label = label
        self.createdAt = createdAt
    }

    var source: RoutePointSource {
        RoutePointSource(rawValue: sourceRaw) ?? .manual
    }
}

@Model
final class CableProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var diameterMillimeters: Double
    var minimumBendRadiusMillimeters: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: CableCategory,
        diameterMillimeters: Double = 0,
        minimumBendRadiusMillimeters: Double = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.diameterMillimeters = max(0, diameterMillimeters)
        self.minimumBendRadiusMillimeters = max(0, minimumBendRadiusMillimeters)
        self.createdAt = createdAt
    }

    var category: CableCategory {
        get { CableCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class CableReel {
    @Attribute(.unique) var id: UUID
    var name: String
    var profileID: UUID?
    var initialLengthMeters: Double
    var remainingLengthMeters: Double
    var notes: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        profileID: UUID? = nil,
        initialLengthMeters: Double,
        remainingLengthMeters: Double? = nil,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        let safeInitial = max(0, initialLengthMeters)
        self.id = id
        self.name = name
        self.profileID = profileID
        self.initialLengthMeters = safeInitial
        self.remainingLengthMeters = min(max(0, remainingLengthMeters ?? safeInitial), safeInitial)
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class PhotoNote {
    @Attribute(.unique) var id: UUID
    var routeID: UUID
    @Attribute(.externalStorage) var imageData: Data?
    var caption: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        routeID: UUID,
        imageData: Data? = nil,
        caption: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.routeID = routeID
        self.imageData = imageData
        self.caption = caption
        self.createdAt = createdAt
    }
}
