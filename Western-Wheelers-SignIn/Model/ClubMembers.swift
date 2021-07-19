import Foundation

class ClubMembers : ObservableObject {
    @Published public var clubList:[Rider] = []
    static let instance:ClubMembers = ClubMembers()
    static let savedDataName = "MemberListData"
    private var pageList:[Rider] = []
    private let api = WAApi()
    //TODO blanket privacy block works?
    private init() {
        //https://app.swaggerhub.com/apis/WildApricot/wild-apricot_api_for_non_administrative_access/7.15.0#/Contacts/get_accounts__accountId__contacts
        DispatchQueue.global(qos: .userInitiated).async {
            //let url = "https://api.wildapricot.org/v2.2/Accounts/$id/Contacts"
            var done = false
            var pos = 0
            let pageSize = 400 //500 seems to be max and the default if no page size specified.
            var downloadList:[Rider] = []

            while !done {
                var url = "https://api.wildapricot.org/publicview/v1/accounts/$id/contacts"
                url += "?%24skip=\(pos)&%24top=\(pageSize)"
                self.pageList = []
                self.api.apiCall(url: url, username:nil, password:nil, completion: self.loadMembers)
                print ("++++", self.pageList.count, self.clubList.count)
                pos += pageSize
                downloadList.append(contentsOf: self.pageList)
                if self.pageList.count < pageSize {
                    done = true
                    break
                }
            }
            downloadList.sort {
                $0.getDisplayName() < $1.getDisplayName()
            }
            self.updateList(updList: downloadList)
        }
        
        let savedData = UserDefaults.standard.object(forKey: ClubMembers.savedDataName)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let list = try? decoder.decode([Rider].self, from: json as Data) {
                    clubList = list
                    Messages.instance.sendMessage(msg: "Restored \(list.count) club members from local")
                }
                else {
                    Messages.instance.reportError(context: "ClubRiders", msg: "Unable to restore riders")
                }
            }
            catch {
                let msg = "Error restoring member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
        else {
            Messages.instance.sendMessage(msg: "Please wait for the club member list to download")
        }
    }
    
    func loadMembers(rawData: Data) {
        var cnt = 0
        
        if let contacts = try! JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] {
            for (key, val) in contacts {
                print("===", key)
//                if key == "ResultUrl" {
//                    resultsUrl = (val as! String)
//                }
//                if key == "State" {
//                    responseComplete = (val as! String == "Complete")
//                }
                if key == "Contacts" {
                    let members = val as! NSArray
                    for member in members {
                        let memberDict = member as! NSDictionary
//                        for d in memberDict {
//                            print(d)
//                        }
                        let id = memberDict["Id"] as! Int
                        if id == 3922122 {
                            //cnt = 0
                        }
                        var lastName = ""
                        if let name = memberDict["LastName"] as? String {
                            lastName = name
                        }
                        var firstName = ""
                        if let name = memberDict["FirstName"] as? String {
                            firstName = name
                        }

//                        if let val = memberDict["Status"]  { non admin API returns only active members
//                            let active=true
//                            if !active {
//                                continue
//                            }
//                        }
//                        else {
//                            continue
//                        }
                        
                        //var homePhone = ""
                        var cellPhone = ""
                        var emergencyPhone = ""
                        var email = ""

                        let keys = memberDict["FieldValues"] as! NSArray
                        var c = 0
                        for k in keys {
                            let fields = k as! NSDictionary
                            let fieldName = fields["FieldName"]
                            let fieldValue = fields["Value"]
                            c = c+1
//                            if fieldName as! String == "Home Phone" {
//                                if let e = fieldValue as? String {
//                                    homePhone = e
//                                }
//                            }
                            if fieldName as! String == "Cell Phone" {
                                if let e = fieldValue as? String {
                                    cellPhone = e
                                }
                            }
                            if fieldName as! String == "Emergency Phone" {
                                if let e = fieldValue as? String {
                                    emergencyPhone = e
                                }
                            }
                            if fieldName as! String == "e-Mail" {
                                if let e = fieldValue as? String {
                                    email = e
                                }
                            }

                        }
                        cnt += 1
                        self.pageList.append(Rider(id: String(id), nameFirst: firstName, nameLast: lastName, phone: cellPhone, emrg: emergencyPhone, email: email))
                    }
                }
            }
        }
//        if memberList.count > 0 {
////            memberList.sort {
////                $0.name < $1.name
////            }
//            ClubMembers.instance.updateList(updList: memberList)
//            responseComplete = true
//        }
//        else {
//            if responseComplete {
//                //the first response says the query results are 'complete' so go fetch them now
//                DispatchQueue.global(qos: .userInitiated).async {
//                    //load the members from the result URL
////                    self.apiCallOld(path: resultsUrl!, withToken: true, usrMsg: usrMsg, completion: self.parseMembers, apiType: apiType, tellUsers: tellUsers)
//                }
//            }
//            else {
//                DispatchQueue.global(qos: .userInitiated).async {
//                    //poll again for results
//                    sleep(4)
////                    self.apiCallOld(path: resultsUrl!, withToken: true, usrMsg: usrMsg, completion: self.parseMembers, apiType: apiType, tellUsers: tellUsers)
//                }
//            }
//        }
    }

    func get(id:String) -> Rider? {
        for r in clubList {
            if r.id == id {
                return r
            }
        }
        return nil
    }
    
    func getByName(displayName:String) -> Rider? {
        for r in clubList {
            if r.getDisplayName() == displayName {
                return r
            }
        }
        return nil
    }

    func selectionCount() -> Int {
        var cnt = 0
        for r in clubList {
            if r.selected() {
                cnt += 1
            }
        }
        return cnt
    }
    
    func getFirstSelected() -> Rider? {
        for r in clubList {
            if r.selected() {
                return r
            }
        }
        return nil
    }
    
    func pushChange() {
        //force an array change to publish the row change
        clubList.append(Rider(id: "", nameFirst: "", nameLast: "", phone: "", emrg: "", email: ""))
        clubList.remove(at: clubList.count-1)
    }

    func filter(nameLast: String, nameFirst: String) {
        var fnd = 0
        for r in clubList {
            if nameLast.isEmpty && nameFirst.isEmpty {
                r.setSelected(false)
                continue
            }
            if  (r.nameLast.lowercased().contains(nameLast.lowercased()) || nameLast.isEmpty) &&
                    (r.nameFirst.lowercased().contains(nameFirst.lowercased()) || nameFirst.isEmpty) {
                r.setSelected(true)
                fnd += 1
            }
            else {
                r.setSelected(false)
            }
        }
        self.pushChange()
    }
    
//    func setSelected(name: String) {
//        for r in clubList {
//            if r.name == name {
//                r.setSelected(true)
//            }
//            else {
//                r.setSelected(false)
//            }
//        }
//        self.pushChange()
//    }
//
    func clearSelected() {
        for r in clubList {
            r.setSelected(false)
        }
        //force an array change to publish the row change
        pushChange()
    }

    func updateList(updList: [Rider]) {
        DispatchQueue.main.async {
            self.clubList = []
            for r in updList {
                self.clubList.append(r)
            }
            let msg = "Downloaded \(self.clubList.count) club members"
            Messages.instance.sendMessage(msg: msg)
            do {
                var capacity:Int64 = 0
                //In iOS, the home directory is the application’s sandbox directory
                let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                
                let values = try docPath.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                if let cap = values.volumeAvailableCapacityForImportantUsage {
                    capacity = cap
                }

                let encoder = JSONEncoder()
                if let data = try? encoder.encode(self.clubList) {
                    let compressedData = try (data as NSData).compressed(using: .lzfse)
                    if compressedData.count < capacity {
                        UserDefaults.standard.set(compressedData, forKey: ClubMembers.savedDataName)
                    }
                    else {
                        Messages.instance.reportError(context: "ClubRiders", msg:"insufficent space to save list")
                    }
                }
            }
            catch {
                let msg = "Error saving member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
    }
}
