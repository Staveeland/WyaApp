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

    func createShare(completion: @escaping (CKShare?) -> Void) {
        guard let record = locationRecord else { completion(nil); return }
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "Wya Location"
        let modify = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
        modify.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            if error == nil {
                self?.share = share
                completion(share)
            } else {
                completion(nil)
            }
        }
        privateDB.add(modify)
    }

    func acceptShare(from url: URL, completion: @escaping (Bool) -> Void) {
        container.acceptShare(with: url) { _, error in
            completion(error == nil)
        }
    }
}
