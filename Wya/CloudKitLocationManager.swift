import Foundation
import CloudKit
import CoreLocation

class CloudKitLocationManager: ObservableObject {
    static let shared = CloudKitLocationManager()

    let container: CKContainer
    let privateDB: CKDatabase
    let sharedZone = CKRecordZone(zoneName: "SharedZone")
    @Published private(set) var share: CKShare?
    @Published private(set) var locationRecord: CKRecord?

    private init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        createLocationRecordIfNeeded()
    }

    private func createLocationRecordIfNeeded() {
        let zone = CKRecordZone(zoneName: "SharedZone")
        let recordID = CKRecord.ID(recordName: "MyLocation", zoneID: zone.zoneID)

        // Save the zone first
        privateDB.save(zone) { [weak self] _, zoneError in
            if let zoneError = zoneError,
               let ckError = zoneError as? CKError,
               ckError.code != CKError.Code(rawValue: 26) { // 26 = zoneAlreadyExists
                print("Failed to create zone: \(zoneError)")
                return
            }

            print("Zone saved or already exists")

            self?.privateDB.fetch(withRecordID: recordID) { record, error in
                if let record = record {
                    print("Fetched existing record in SharedZone.")
                    DispatchQueue.main.async {
                        self?.locationRecord = record
                    }
                } else {
                    print("Creating new record in SharedZone")
                    let newRecord = CKRecord(recordType: "Location", recordID: recordID)
                    newRecord["lat"] = 0
                    newRecord["lon"] = 0

                    self?.privateDB.save(newRecord) { savedRecord, error in
                        if let savedRecord = savedRecord {
                            print("Saved new record: \(savedRecord.recordID)")
                        } else {
                            print("Failed to save record: \(String(describing: error))")
                        }
                        DispatchQueue.main.async {
                            self?.locationRecord = savedRecord
                        }
                    }
                }
            }
        }
    }

    func update(location: CLLocationCoordinate2D) {
        guard let record = locationRecord else { return }
        record["lat"] = location.latitude
        record["lon"] = location.longitude
        privateDB.save(record) { _, _ in }
    }

    func createShare(completion: @escaping (CKShare?, Error?) -> Void) {
        guard let record = locationRecord else {
            completion(nil, NSError(domain: "Missing record", code: 1))
            return
        }

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "Wya Location"

        let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            if let ckError = error as? CKError, ckError.code == .zoneBusy {
                let delay = (ckError.userInfo[CKErrorRetryAfterKey] as? TimeInterval) ?? 2.0
                print("Zone is busy, retrying in \(delay)s...")

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.createShare(completion: completion) // Retry recursively
                }
            } else if let error = error {
                print("Share creation failed: \(error)")
                completion(nil, error)
            } else {
                print("✅ Share created successfully")
                DispatchQueue.main.async {
                    self?.share = share
                }
                completion(share, nil)
            }
        }

        privateDB.add(operation)
    }

    func acceptShare(from url: URL, completion: @escaping (Bool) -> Void) {
        print("Received Universal Link: \(url)")

        container.fetchShareMetadata(with: url) { [weak self] metadata, error in
            if let error = error {
                print("Failed to fetch share metadata: \(error)")
                completion(false)
                return
            }

            guard let metadata = metadata else {
                print("No metadata returned")
                completion(false)
                return
            }

            let op = CKAcceptSharesOperation(shareMetadatas: [metadata])
            op.perShareCompletionBlock = { (metadata: CKShare.Metadata, share: CKShare?, error: Error?) in
                if let error = error {
                    print("Share failed: \(error)")
                } else {
                    print("Share accepted for root record: \(metadata.rootRecordID.recordName)")
                }
            }

            op.acceptSharesCompletionBlock = { error in
                if let error = error {
                    print("Accept shares failed: \(error)")
                    completion(false)
                } else {
                    print("Share accepted successfully 🎉")
                    completion(true)
                }
            }

            self?.container.add(op)
        }
    }
}
