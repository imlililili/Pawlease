import CloudKit
import Foundation

/// Implements `CircleInviteCodeRepository` against
/// `CKContainer(identifier: "iCloud.com.lili.Pawlease").publicCloudDatabase`.
/// This is the only place in the app that touches the CloudKit public
/// database. All `CKRecord` mapping — and all defensive validation of
/// fetched records — stays in this file.
///
/// The public database is used deliberately narrowly: it holds nothing but
/// a lookup record (`shareURL`, `circleID`, `createdAt`, `expiresAt`,
/// `isRevoked`, `schemaVersion`). Resolving a code here never grants
/// access by itself — real authorization only happens through Apple's
/// `CKShare` acceptance flow once the caller opens the resolved URL. See
/// the README's invite-code architecture section for the full data flow.
final class CloudKitCircleInviteCodeRepository: CircleInviteCodeRepository, @unchecked Sendable {
    private let database: CKDatabase

    init(database: CKDatabase = CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier).publicCloudDatabase) {
        self.database = database
    }

    @discardableResult
    func publish(_ details: CircleInviteCodeDetails) async throws -> CircleInviteCodeDetails {
        let recordID = CKRecord.ID(recordName: details.code.normalizedValue)
        let record = CKRecord(recordType: CircleInviteCodeRecordSchema.recordType, recordID: recordID)
        Self.apply(details, to: record)

        do {
            let saved = try await database.save(record)
            return try Self.map(saved)
        } catch let ckError as CKError where ckError.code == .serverRecordChanged {
            throw CircleInviteCodeError.collision
        } catch let error as CircleInviteCodeError {
            throw error
        } catch {
            throw CircleInviteCodeErrorMapping.map(error)
        }
    }

    func fetchActiveCode(circleID: UUID) async throws -> CircleInviteCodeDetails? {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == 0",
            CircleInviteCodeRecordSchema.Field.circleID, circleID.uuidString,
            CircleInviteCodeRecordSchema.Field.isRevoked
        )
        let query = CKQuery(recordType: CircleInviteCodeRecordSchema.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CircleInviteCodeRecordSchema.Field.createdAt, ascending: false)]

        do {
            let (matchResults, _) = try await database.records(matching: query, resultsLimit: 1)
            guard let (_, result) = matchResults.first else { return nil }
            let record = try result.get()
            return try Self.map(record)
        } catch let error as CircleInviteCodeError {
            throw error
        } catch {
            throw CircleInviteCodeErrorMapping.map(error)
        }
    }

    func fetchCode(_ code: CircleInviteCode) async throws -> CircleInviteCodeDetails {
        let recordID = CKRecord.ID(recordName: code.normalizedValue)
        do {
            let record = try await database.record(for: recordID)
            return try Self.map(record)
        } catch let error as CircleInviteCodeError {
            throw error
        } catch {
            throw CircleInviteCodeErrorMapping.map(error)
        }
    }

    func revoke(_ code: CircleInviteCode) async throws {
        let recordID = CKRecord.ID(recordName: code.normalizedValue)
        do {
            let record = try await database.record(for: recordID)
            record[CircleInviteCodeRecordSchema.Field.isRevoked] = Int64(1) as CKRecordValue
            _ = try await database.save(record)
        } catch {
            throw CircleInviteCodeErrorMapping.map(error)
        }
    }

    private static func apply(_ details: CircleInviteCodeDetails, to record: CKRecord) {
        record[CircleInviteCodeRecordSchema.Field.shareURL] = details.shareURL.absoluteString as CKRecordValue
        record[CircleInviteCodeRecordSchema.Field.circleID] = details.circleID.uuidString as CKRecordValue
        record[CircleInviteCodeRecordSchema.Field.createdAt] = details.createdAt as CKRecordValue
        record[CircleInviteCodeRecordSchema.Field.expiresAt] = details.expiresAt as CKRecordValue
        record[CircleInviteCodeRecordSchema.Field.isRevoked] = Int64(details.isRevoked ? 1 : 0) as CKRecordValue
        record[CircleInviteCodeRecordSchema.Field.schemaVersion] = CircleInviteCodeRecordSchema.currentSchemaVersion as CKRecordValue
    }

    /// Defensive parsing: expected record type, valid HTTPS CKShare URL,
    /// valid Circle UUID, and a supported schema version. Never trusts
    /// public-record content as authorization — this only produces a
    /// lookup result.
    private static func map(_ record: CKRecord) throws -> CircleInviteCodeDetails {
        guard record.recordType == CircleInviteCodeRecordSchema.recordType else {
            throw CircleInviteCodeError.invalidRecord
        }
        guard let schemaVersion = record[CircleInviteCodeRecordSchema.Field.schemaVersion] as? Int64,
              schemaVersion == CircleInviteCodeRecordSchema.currentSchemaVersion
        else {
            throw CircleInviteCodeError.invalidRecord
        }
        guard let code = CircleInviteCode(normalizedValue: record.recordID.recordName) else {
            throw CircleInviteCodeError.invalidRecord
        }
        guard let shareURLString = record[CircleInviteCodeRecordSchema.Field.shareURL] as? String,
              let shareURL = URL(string: shareURLString),
              shareURL.scheme?.lowercased() == "https"
        else {
            throw CircleInviteCodeError.invalidRecord
        }
        guard let circleIDString = record[CircleInviteCodeRecordSchema.Field.circleID] as? String,
              let circleID = UUID(uuidString: circleIDString)
        else {
            throw CircleInviteCodeError.invalidRecord
        }
        guard let createdAt = record[CircleInviteCodeRecordSchema.Field.createdAt] as? Date,
              let expiresAt = record[CircleInviteCodeRecordSchema.Field.expiresAt] as? Date
        else {
            throw CircleInviteCodeError.invalidRecord
        }
        let isRevokedRaw = record[CircleInviteCodeRecordSchema.Field.isRevoked] as? Int64 ?? 0

        return CircleInviteCodeDetails(
            code: code,
            circleID: circleID,
            shareURL: shareURL,
            createdAt: createdAt,
            expiresAt: expiresAt,
            isRevoked: isRevokedRaw != 0
        )
    }
}
