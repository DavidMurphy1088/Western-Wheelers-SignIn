import Foundation

class ClubMembers : ObservableObject {
    @Published public var clubList:[Rider] = []
    static let instance:ClubMembers = ClubMembers()
    static let savedDataName = "MemberListData"
    
    private init() {
        WAApi.instance()
        let savedData = UserDefaults.standard.object(forKey: ClubMembers.savedDataName)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let list = try? decoder.decode([Rider].self, from: json as Data) {
                    clubList = list
                    Messages.instance.sendMessage(msg: "Restored \(list.count) club members from local")
                }
            }
            catch {
                let msg = "Error restoring member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
    }
    
    func get(name:String) -> Rider? {
        for r in clubList {
            if r.name == name {
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

    func filter(name: String) {
        var fnd = 0
        for r in clubList {
            if r.name.lowercased().contains(name.lowercased()) {
                r.setSelected(true)
                fnd += 1
            }
            else {
                r.setSelected(false)
            }
        }
        //force an array change to publish the row change
        clubList.append(Rider(name: "", phone: "", emrg: "", email: ""))
        clubList.remove(at: clubList.count-1)
    }
    
    func setSelected(name: String) {
        for r in clubList {
            if r.name == name {
                r.setSelected(true)
            }
            else {
                r.setSelected(false)
            }
        }
        //force an array change to publish the row change
        clubList.append(Rider(name: "", phone: "", emrg: "", email: ""))
        clubList.remove(at: clubList.count-1)
    }
    
    func clearSelected() {
        for r in clubList {
            r.setSelected(false)
        }
        //force an array change to publish the row change
        clubList.append(Rider(name: "", phone: "", emrg: "", email: ""))
        clubList.remove(at: clubList.count-1)
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
                } else {
                    Messages.instance.reportError(context: "ClubRiders", msg:"Capacity is unavailable")
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
