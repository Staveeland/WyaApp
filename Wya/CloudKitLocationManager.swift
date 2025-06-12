import Foundation
import CloudKit
import CoreLocation

class CloudKitLocationManager: ObservableObject {
    static let shared = CloudKitLocationManager()

    let container: CKContainer
    let privateDB: CKDatabase
    @Published private(set) var share: CKShare?
    @Published private(set) var locationRecord: CKRecord?

    private init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        createLocationRecordIfNeeded()
    }

    private func createLocationRecordIfNeeded() {
        let recordID = CKRecord.ID(recordName: "MyLocation")
        privateDB.fetch(withRecordID: recordID) { [weak self] record, error in
            if let record = record {
                self?.locationRecord = record
            } else {
                let newRecord = CKRecord(recordType: "Location", recordID: recordID)
                newRecord["lat"] = 0
                newRecord["lon"] = 0
                self?.privateDB.save(newRecord) { savedRecord, error in
                    self?.locationRecord = savedRecord
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
            let err = NSError(domain: "CloudKitLocationManager",
                               code: 0,
                               userInfo: [NSLocalizedDescriptionKey: "Missing location record"])
            completion(nil, err)
            return
        }

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "Wya Location"

        let modify = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
        modify.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            if let error = error {
                completion(nil, error)
            } else {
                self?.share = share
                completion(share, nil)
            }
        }

        privateDB.add(modify)
    }

    func acceptShare(from url: URL, completion: @escaping (Bool) -> Void) {
        container.fetchShareMetadata(with: url) { [weak self] metadata, error in
            guard let metadata = metadata, error == nil else {
                completion(false)
                return
            }

            let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
            operation.acceptSharesCompletionBlock = { error in
                completion(error == nil)
            }

            self?.container.add(operation)
        }
    }
}
