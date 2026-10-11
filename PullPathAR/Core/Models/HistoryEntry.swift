import Foundation
import SwiftData

enum HistoryKind: String, CaseIterable, Codable, Identifiable {
    case created
    case measured
    case updated
    case statusChanged
    case reelAssigned
    case photoAdded
    case exported

    var id: String { rawValue }
}

@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var routeID: UUID
    var kindRaw: String
    var detail: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        routeID: UUID,
        kind: HistoryKind,
        detail: String,
        timestamp: Date = .now
    ) {
        self.id = id
        self.routeID = routeID
        self.kindRaw = kind.rawValue
        self.detail = detail
        self.timestamp = timestamp
    }

    var kind: HistoryKind {
        HistoryKind(rawValue: kindRaw) ?? .updated
    }
}
