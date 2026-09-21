import Foundation

enum CircleMapper {
    static func toDomain(_ entity: CircleEntity) -> FriendCircle {
        FriendCircle(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            timezoneIdentifier: entity.timezoneIdentifier ?? TimeZone.current.identifier,
            createdAt: entity.createdAt ?? Date(),
            ownerProfileID: entity.ownerProfileID ?? UUID()
        )
    }

    static func apply(_ circle: FriendCircle, to entity: CircleEntity) {
        entity.id = circle.id
        entity.name = circle.name
        entity.timezoneIdentifier = circle.timezoneIdentifier
        entity.createdAt = circle.createdAt
        entity.ownerProfileID = circle.ownerProfileID
    }
}
