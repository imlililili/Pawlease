/// The public `CircleInviteCode` CKRecord's field names and current schema
/// version. Deliberately minimal — never a name, photo, or caption. Kept in
/// its own file so the record shape is easy to audit against the README's
/// documented schema and the CloudKit Console setup.
enum CircleInviteCodeRecordSchema {
    static let recordType = "CircleInviteCode"
    static let currentSchemaVersion: Int64 = 1

    enum Field {
        static let shareURL = "shareURL"
        static let circleID = "circleID"
        static let createdAt = "createdAt"
        static let expiresAt = "expiresAt"
        static let isRevoked = "isRevoked"
        static let schemaVersion = "schemaVersion"
    }
}
