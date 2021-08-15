import Foundation
import CloudKit

class RideTemplates : ObservableObject {
    static let instance:RideTemplates = RideTemplates()
    @Published public var list:[RideTemplate] = []
    static let container = CKContainer(identifier: "iCloud.com.dmurphy.westernwheelers")

    private init() {
        list = []
        loadFromCloud()
    }
    
    func loadFromCloud() {
        let query = CKQuery(recordType: "RideTemplates", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["name", "notes", "lastUpdater","lastUpdate", "riders"]
        operation.queuePriority = .veryHigh
        operation.qualityOfService = .userInteractive
        operation.recordFetchedBlock = { [self]record in
            list.append(RideTemplate(record: record))
        }
        operation.queryCompletionBlock = {(cursor, error) in //{ [unowned self] (cursor, error) in
            if error != nil {
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
                list[i] = saveTemplate
                fnd = true
            }
            i += 1
        }
        if !fnd {
            list.append(saveTemplate)
        }
        if saveTemplate.recordId != nil {
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
            if delTemplate.recordId != nil {
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

    func loadTemplate(name:String, signedIn:SignedInRiders) {
        for template in list {
            if template.name == name {
                signedIn.clearData(clearRide: false)
                signedIn.rideData.templateName = name.trimmingCharacters(in: .whitespaces)
                signedIn.rideData.notes = template.notes
                for rider in template.list {
                    signedIn.add(rider: rider)
                }
            }
        }
    }
}
