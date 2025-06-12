import Foundation
import CloudKit

final class CloudKitUserDataManager {
    static let shared = CloudKitUserDataManager()
    private let container = CKContainer.default()
    private var privateDB: CKDatabase { container.privateCloudDatabase }

    func save(userID: String, name: String, people: [Person], alerts: [LocationAlert]) {
        let recordID = CKRecord.ID(recordName: userID)
        let record = CKRecord(recordType: "UserData", recordID: recordID)
        record["name"] = name
        if let peopleData = try? JSONEncoder().encode(people) {
            record["people"] = peopleData
        }
        if let alertData = try? JSONEncoder().encode(alerts) {
            record["alerts"] = alertData
        }
        privateDB.save(record) { _, _ in }
    }

    func fetch(userID: String, completion: @escaping ([Person], [LocationAlert]) -> Void) {
        let recordID = CKRecord.ID(recordName: userID)
        privateDB.fetch(withRecordID: recordID) { record, _ in
            var fetchedPeople: [Person] = []
            var fetchedAlerts: [LocationAlert] = []
            if let record = record {
                if let peopleData = record["people"] as? Data {
                    fetchedPeople = (try? JSONDecoder().decode([Person].self, from: peopleData)) ?? []
                }
                if let alertData = record["alerts"] as? Data {
                    fetchedAlerts = (try? JSONDecoder().decode([LocationAlert].self, from: alertData)) ?? []
                }
            }
            DispatchQueue.main.async {
                completion(fetchedPeople, fetchedAlerts)
            }
        }
    }
}
