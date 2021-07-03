import Foundation

class ClubRiders : ObservableObject {
    @Published public var clubList:[Rider] = []
    static let shared:ClubRiders = ClubRiders()
    static let savedDataName = "MemberListData"
    
    private init() {
        //WAApi.instance() TODO Put back
        //TODO add info somewhere when the list is refreshed
        //clubList.append(Rider(name:"fred1", homePhone: "650 995 4261", cell: "650 995 4261", emrg: ""))
        let savedData = UserDefaults.standard.object(forKey: ClubRiders.savedDataName)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                print(json)
                let decoder = JSONDecoder()
                if let list = try? decoder.decode([Rider].self, from: json as Data) {
                    clubList = list
                    print("ClubRiders::restored member list:", clubList.count)
                }
            }
            catch {
                print("ClubRiders::Error restoring member list", error.localizedDescription)
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
    
    func getFirstSelected() -> Rider? {
        for r in clubList {
            if r.isSelected {
                return r
            }
        }
        return nil
    }

    func filter(name: String) {
        for r in clubList {
            if r.name.lowercased().contains(name.lowercased()) {
                r.isSelected = true
            }
            else {
                r.isSelected = false
            }
        }
        //force an array change to publish the row change
        clubList.append(Rider(name: "", homePhone: "", cell: "", emrg: ""))
        clubList.remove(at: clubList.count-1)
    }
    
    func setSelected(name: String) {
        for r in clubList {
            if r.name == name {
                r.isSelected = true
            }
            else {
                r.isSelected = false
            }
        }
        //force an array change to publish the row change
        clubList.append(Rider(name: "", homePhone: "", cell: "", emrg: ""))
        clubList.remove(at: clubList.count-1)
    }
    
    func updateList(updList: [Rider]) {
        DispatchQueue.main.async {
            self.clubList = []
            for r in updList {
                self.clubList.append(r)
            }
            print("ClubRiders::updated member list from API, count:", self.clubList.count)

            do {
                var capacity:Int64 = 0
                //In iOS, the home directory is the application’s sandbox directory
                //let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
                let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                //print("FILE", fileURL)
                print("ClubRiders::Doc Path", docPath)
                
                let values = try docPath.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                if let cap = values.volumeAvailableCapacityForImportantUsage {
                    capacity = cap
                    print("ClubRiders::Doc Available capacity for important usage: \(capacity)")
                } else {
                    print("ClubRiders::Capacity is unavailable")
                }

                let encoder = JSONEncoder()
                if let data = try? encoder.encode(self.clubList) {
                    let compressedData = try (data as NSData).compressed(using: .lzfse)
                    print ("ClubRiders::Sizes", data.count, compressedData.count)
                    if compressedData.count < capacity {
                        UserDefaults.standard.set(compressedData, forKey: ClubRiders.savedDataName)
                        print("ClubRiders::saved member list")
                    }
                }
            }
            catch {
                print("ClubRiders::Error saving member list", error.localizedDescription)
            }
        }
    }
}
