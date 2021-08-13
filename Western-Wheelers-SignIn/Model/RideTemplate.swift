import Foundation
import CloudKit

class RideTemplate: RiderList, Hashable {
    var name: String = ""
    var notes:String = ""
    var recordId:CKRecord.ID?

    init(name: String, notes:String, riders:[Rider]){
        self.name = name
        self.notes = notes
        //self.riders.append(Rider(id:"X", nameFirst:"F", nameLast:"L", phone:"P", emrg:"E", email:"EM"))
    }
    
    init(record:CKRecord) {
        super.init()

        recordId = record.recordID
        if let data = record["name"] {
            name = data.description
        }
        if let data = record["notes"] {
            notes = data.description
        }
        let riders = record.object(forKey: "riders") as! NSArray
            let decoder = JSONDecoder()
            for r in riders {
                let json = Data("\(r)".utf8)
                if let rider = try? decoder.decode(Rider.self, from: json) {
                    list.append(rider)
                }
            }

    }
    
    static func == (lhs: RideTemplate, rhs: RideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    func makeRecord() -> CKRecord {
        var ckRecord = CKRecord(recordType: "RideTemplates")
        if let id = self.recordId {
            ckRecord = CKRecord(recordType: "RideTemplates", recordID: id)
        }
        ckRecord["name"] = name as CKRecordValue
        ckRecord["notes"] = notes as CKRecordValue
        let encoder = JSONEncoder()
        var jsonRiders:[String] = []
        for rider in self.list {
            if let data = try? encoder.encode(rider) {
                let s = String(data: data, encoding: String.Encoding.utf8)
                jsonRiders.append(s!)
            }
        }
        ckRecord["riders"] = jsonRiders as CKRecordValue
        return ckRecord
    }
    
    func remoteAdd() { //completion: @escaping (CKRecord.ID) -> Void) {
        let op = CKModifyRecordsOperation(recordsToSave: [makeRecord()], recordIDsToDelete: [])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive

        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || savedRecords == nil || savedRecords?.count != 1 {
                print(error) //TODO
                return
            }
            guard let records = savedRecords else {
                print("no records") //TODO
                return
            }
            let record = records[0]
            print("added record", record.recordID)
            self.recordId = record.recordID
            //completion(record.recordID)
        }
        RideTemplates.container.publicCloudDatabase.add(op)
    }
    
    public func remoteModify() { //completion: @escaping () -> Void) {
        let op = CKModifyRecordsOperation(recordsToSave: [makeRecord()], recordIDsToDelete: [])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive
        op.savePolicy = .allKeys  //2 hours later ... required otherwise it does NOTHING :( :(
        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || savedRecords?.count != 1 {
                print(error?.localizedDescription)            }
            else {
                print("modified ok", savedRecords?.count)
            }
        }
        RideTemplates.container.publicCloudDatabase.add(op)
    }
    
    public func remoteDelete() {//completion: @escaping () -> Void) {
        let op = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [self.recordId!])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive
        op.savePolicy = .allKeys  //2 hours later ... required otherwwise it does NOTHING :( :(
        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || deletedRecordIDs?.count != 1 {
                print(error?.localizedDescription)            //TODO
            }
            else {
                //completion()
            }
        }
        RideTemplates.container.publicCloudDatabase.add(op)
    }

}
