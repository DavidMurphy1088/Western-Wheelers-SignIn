import Foundation
import CloudKit

class RideTemplate: RiderList, Identifiable, Hashable, Equatable {
    var id = UUID()
    var name: String = ""
    //var riders:RiderList =
    var notes:String = ""
    
    init(name: String, notes:String, riders:[Rider]){
        self.name = name
        self.notes = notes
        //self.riders.append(Rider(id:"X", nameFirst:"F", nameLast:"L", phone:"P", emrg:"E", email:"EM"))
//        for rider in riders {
//            self.riders.append(rider)
//        }
    }
    
    static func == (lhs: RideTemplate, rhs: RideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    func remoteAdd(completion: @escaping (CKRecord.ID) -> Void) {
        let container = CKContainer(identifier: "iCloud.com.dmurphy.westernwheelers")
        if let containerIdentifier = container.containerIdentifier {
            print(containerIdentifier)
        }

        let ckRecord = CKRecord(recordType: "RideTemplates")
        ckRecord["name"] = name as CKRecordValue
        ckRecord["notes"] = notes as CKRecordValue
        let encoder = JSONEncoder()
        var jsonRiders:[String] = []
        do {
            for rider in self.list {
                if let data = try? encoder.encode(rider) {
                    let s = String(data: data, encoding: String.Encoding.utf8)
                    //print(s ?? "")
                    jsonRiders.append(s!)
                    
                }
            }
        }
        catch {
            print(error)
        }
        ckRecord["rider"] = jsonRiders as CKRecordValue
        let op = CKModifyRecordsOperation(recordsToSave: [ckRecord], recordIDsToDelete: [])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive

        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || savedRecords == nil || savedRecords?.count != 1 {
                print(error)
                return
            }
            guard let records = savedRecords else {
                print("no records")
                return
            }
            let record = records[0]
            guard (record["name"] as? String) != nil else {
                print("no record")
                return
            }
            completion(record.recordID)
        }
        container.publicCloudDatabase.add(op)
    }
}

class RideTemplates : ObservableObject {
    static let instance:RideTemplates = RideTemplates()
    @Published public var list:[RideTemplate] = []
    
    private init() {
        list = []
        list.append(RideTemplate(name: "temp1", notes: "xxx", riders: []))
        list.append(RideTemplate(name: "temp2", notes: "xx", riders: []))
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

    func save(saveTemplate:RideTemplate) {
        var fnd = false
        //let template = RideTemplate(name: name, notes: notes, riders: riders)
        var i = 0
        for template in list {
            if template.name == saveTemplate.name {
                list[i] = template
                fnd = true
            }
            i += 1
        }
        if !fnd {
            list.append(saveTemplate)
        }
        saveTemplate.remoteAdd(completion: added)
    }
    
    func delete(name:String) {
        var i = 0
        for template in list {
            if template.name == name {
                list.remove(at: i)
                break
            }
            i += 1
        }
    }

    func get(name:String) -> RideTemplate? {
        for template in list {
            if template.name == name {
                return template
            }
        }
        return nil
    }

    func load(name:String, signedIn:SignedInRiders) {
        for template in list {
            if template.name == name {
                for rider in template.list {
                    signedIn.add(rider: rider)
                }
            }
        }
    }
}
