import Foundation
import CloudKit

class RideTemplates : ObservableObject {
    static let instance:RideTemplates = RideTemplates()
    @Published public var list:[RideTemplate] = []
    static let container = CKContainer(identifier: "iCloud.com.dmurphy.westernwheelers")

    private init() {
        list = []
        //list.append(RideTemplate(name: "temp1", notes: "xxx", riders: []))
        //list.append(RideTemplate(name: "temp2", notes: "xx", riders: []))
//        DispatchQueue.global(qos: .userInitiated).async {
//            var eventsUrl = "https://api.wildapricot.org/v2/accounts/$id/events"
//            let formatter = DateFormatter()
//            let startDate = Calendar.current.date(byAdding: .day, value: 0, to: Date())!
//            formatter.dateFormat = "yyyy-01-01"
//            let startDateStr = formatter.string(from: startDate)
//            eventsUrl = eventsUrl + "?%24filter=StartDate%20gt%20\(startDateStr)"
//            self.api.apiCall(url: eventsUrl, username:nil, password:nil, completion: self.loadRides, fail: self.loadRidesFailed)
//        }
        loadFromCloud()
    }
    
    func loadFromCloud() {
        let query = CKQuery(recordType: "RideTemplates", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["name", "notes", "riders"]
        operation.queuePriority = .veryHigh
        operation.qualityOfService = .userInteractive
        operation.recordFetchedBlock = { [self]record in
            print(record)
            list.append(RideTemplate(record: record))
        }
        operation.queryCompletionBlock = {(cursor, error) in //{ [unowned self] (cursor, error) in
            if error == nil {
                print("===>Loaded templates", self.list.count)
            } else {
                Messages.instance.reportError(context: "RideTemplates load", error: error)
            }
        }
        RideTemplates.container.publicCloudDatabase.add(operation)
    }

    func save(saveTemplate:RideTemplate) {
        var fnd = false
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
        if let id = saveTemplate.recordId {
            saveTemplate.remoteModify()
        }
        else {
            saveTemplate.remoteAdd()
        }
    }
    
    func delete(name:String) {
        var i = 0
        var delTemplate:RideTemplate?
        for template in list {
            if template.name == name {
                delTemplate = template
                list.remove(at: i)
                break
            }
            i += 1
        }
        if let delTemplate = delTemplate {
            if let id = delTemplate.recordId {
                delTemplate.remoteDelete()
            }
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
