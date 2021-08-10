import Foundation
import CloudKit
import Combine

class RideTemplate: Identifiable, Hashable, Equatable {
    var id = UUID()
    var name: String = ""
    //var nextId: Int = 10000
    var riders:[Rider] = []
    var notes:String = ""
    
    init(name: String, notes:String, riders:[Rider]){
        self.name = name
        self.notes = notes
        //self.riders.append(Rider(id:"X", nameFirst:"F", nameLast:"L", phone:"P", emrg:"E", email:"EM"))
        for rider in riders {
            self.riders.append(rider)
        }
    }
    
    static func == (lhs: RideTemplate, rhs: RideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    func remoteAdd(completion: @escaping (CKRecord.ID) -> Void) {
        let ckRecord = CKRecord(recordType: "RideTemplate")
        ckRecord["name"] = name as CKRecordValue
        ckRecord["notes"] = notes as CKRecordValue

        let op = CKModifyRecordsOperation(recordsToSave: [ckRecord], recordIDsToDelete: [])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive

        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || savedRecords == nil || savedRecords?.count != 1 {
                //Util.app().reportError(class_type: type(of: self), context: "Cannot add user record", error: error?.localizedDescription ?? "")
                return
            }
            guard let records = savedRecords else {
                //Util.app().reportError(class_type: type(of: self), context: "add user, nil record")
                return
            }
            let record = records[0]
            guard (record["email"] as? String) != nil else {
                //Util.app().reportError(class_type: type(of: self), context: "add user but no email stored")
                return
            }
            completion(record.recordID)
        }
        CKContainer.default().publicCloudDatabase.add(op)
    }
}

class RideTemplates : ObservableObject {
    static let instance:RideTemplates = RideTemplates()
    @Published public var list:[RideTemplate] = []
    
    private init() {
        list = []
        //list.append(RideTemplate(name: "tem[1"))
        //list.append(RideTemplate(name: "temp2"))
//        DispatchQueue.global(qos: .userInitiated).async {
//            var eventsUrl = "https://api.wildapricot.org/v2/accounts/$id/events"
//            let formatter = DateFormatter()
//            let startDate = Calendar.current.date(byAdding: .day, value: 0, to: Date())!
//            formatter.dateFormat = "yyyy-01-01"
//            let startDateStr = formatter.string(from: startDate)
//            eventsUrl = eventsUrl + "?%24filter=StartDate%20gt%20\(startDateStr)"
//            self.api.apiCall(url: eventsUrl, username:nil, password:nil, completion: self.loadRides, fail: self.loadRidesFailed)
//        }
    }
    func added(id:CKRecord.ID) {
        print("added", id)
    }

    func save(name:String, notes:String, riders:[Rider]) {
        let template = RideTemplate(name: name, notes: notes, riders: riders)
        list.append(template)
        template.remoteAdd(completion: added)
    }
    
    func load(name:String, signedIn:SignedInRiders) {
        for template in list {
            if template.name == name {
                for rider in template.riders {
                    signedIn.add(rider: rider)
                }
            }
        }
    }
}
