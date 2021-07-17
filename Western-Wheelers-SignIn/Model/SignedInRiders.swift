import Foundation

class RideData : Encodable, Decodable {
    var title:String?
    var totalMiles:String?
    var totalClimb:String?
    var lastSignIn:String?
    var notes:[String] = []

    func clear() {
        title = nil
        totalMiles = nil
        lastSignIn = nil
        notes = []
    }
}

class SignedInRiders : ObservableObject {
    static let instance:SignedInRiders = SignedInRiders()
    @Published private var list:[Rider] = []
    
    var nextGuestId = 100
    var rideData:RideData
    
    private static var savedList = "RIDE_LIST"
    private static var savedData = "RIDE_DATA"
    
    private init() {
       rideData = RideData()
    }
    
    func getCount() -> Int {
        return list.count
    }
    
    func getGuestId() -> String {
        self.nextGuestId += 1
        return String(nextGuestId)
    }
    
    func getList() -> [Rider] {
        return list
    }

    func save() {
        do {
            let encoder = JSONEncoder()

            if let data = try? encoder.encode(self.list) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedList)
            }
//            if let data = try? encoder.encode(self.notes) {
//                let compressedData = try (data as NSData).compressed(using: .lzfse)
//                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedDataName2)
//            }
                if let data = try? encoder.encode(self.rideData) {
                    UserDefaults.standard.set(data, forKey: SignedInRiders.savedData)
                }
        }
        catch {
            let msg = "Error saving rider list \(error.localizedDescription)"
            Messages.instance.reportError(context: "SignedInRiders", msg: msg)
        }
    }
    
    func restore() {
        var savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedList)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode([Rider].self, from: json as Data) {
                    list = decoded
                    Messages.instance.sendMessage(msg: "Restored \(self.selectedCount()) signed in riders from local")
                }
            }
            catch {
                let msg = "Error restoring member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
//        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedDataName2)
//        if let savedData = savedData {
//            do {
//                let json = try (savedData as! NSData).decompressed(using: .lzfse)
//                let decoder = JSONDecoder()
//                if let decoded = try? decoder.decode([String].self, from: json as Data) {
//                    notes = decoded
//                }
//            }
//            catch {
//                let msg = "Error restoring rider list \(error.localizedDescription)"
//                Messages.instance.reportError(context: "ClubRiders", msg: msg)
//            }
//        }
//        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedDataName3)
//        if let savedData = savedData {
//            let json = savedData as! NSData
//            let decoder = JSONDecoder()
//            if let decoded = try? decoder.decode(String.self, from: json as Data) {
//                lastSignIn = decoded
//            }
//        }
        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedData)
        if let savedData = savedData {
            let json = savedData as! NSData
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(RideData.self, from: json as Data) {
                rideData = decoded
            }
        }
    }
    
    func clearData() {
        list = []
        rideData.clear()
    }
    
    func setLeader(rider:Rider, way:Bool) {
        for r in list {
            if r.id == rider.id {
                r.isLeader = way
                r.isSelected = true
            }
            else {
                r.isLeader = false
            }
        }
        self.pushChange()
    }
    
    func setCoLeader(rider:Rider, way:Bool) {
        for r in list {
            if r.id == rider.id {
                r.isCoLeader = way
                r.isSelected = true
            }
            else {
                r.isCoLeader = false
            }
        }
        self.pushChange()
    }

    func loadTempate(name:String) {
        list = []
        for template in RideTemplates.instance.templates {
            if template.name == name {
                self.rideData.title = name
                template.requestLoad(ident: template.ident)
                break
            }
        }
    }
    
    func selectedCount() -> Int {
        var count = 0
        for r in list {
            if r.selected() {
                count += 1
            }
        }
        return count
    }
    
    func removeUnselected() {
        var dels:[Int] = []
        for cnt in 0...list.count-1 {
            print("====", cnt)
            if !list[cnt].selected() {
                dels.append(cnt)
            }
        }
        var i = 0
        for d in dels {
            list.remove(at: d-i)
            i += 1
        }
    }
    
    func filter(name: String) {
        for r in list {
            if r.nameFirst.lowercased().contains(name.lowercased()) {
                r.setSelected(true)
            }
            else {
                r.setSelected(false)
            }
        }
        self.pushChange()
    }
    
    func setSignInDate() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm EEEE, d MMM y"
        let dateStr = formatter.string(from: today)
        rideData.lastSignIn = dateStr
    }

    func setSelected(id: String) {
        for r in list {
            if r.id == id {
                r.setSelected(true)
                break
            }
        }
        setSignInDate()
        self.pushChange()
    }
    
    func pushChange() {
        //force an array change to publish the row change
        list.append(Rider(id: "", nameFirst: "", nameLast: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
    }
    
    func setHilighted(id: String) {
        for r in list {
            if r.id == id {
                r.isHilighted = true
            }
            else {
                r.isHilighted = false
            }
        }
        self.pushChange()
    }

    func toggleSelected(id: String) {
        var fnd = false
        for r in list {
            if r.id == id {
                r.setSelected(!r.selected())
                if r.selected() {
                    fnd = true
                    setSignInDate()
                }
            }
        }
        if !fnd {
            rideData.lastSignIn = nil
        }
        self.pushChange()
    }

    func sort () {
        list.sort {
            $0.getDisplayName() < $1.getDisplayName()
        }
    }
    
    func add(rider:Rider) {
        var fnd = false
        for r in list {
            if r.id == rider.id {
                fnd = true
                break
            }
        }
        if !fnd {
            list.append(rider)
        }
        sort()
//        if rider.inDirectory && !rider.isPrivacyVerified {
//            PrivacyChecker.instance.checkRider(rider: rider)
//        }
    }
    
    func remove(id:String) {
        var i = 0
        for r in list {
            if r.id == id {
                list.remove(at: i)
                break
            }
            i += 1
        }
        sort()
    }
    
    func getHTMLContent() -> String {
        var content = "<html><body>"
        if let title = rideData.title {
            content += "<h3>\(title)</h3>"
        }
        content += "<h3>Ride Info</h3>"
        if let first = self.rideData.lastSignIn  {
            content += "Ride Date: \(first)<br>"
        }
        var members = 0
        var guests = 0
        for rider in self.list {
            if rider.isSelected {
                if rider.isGuest {
                    guests += 1
                }
                else {
                    members += 1
                }
            }
        }

        content += "Member Riders Total: \(members)<br>"
        content += "Guest  Riders Total: \(guests)<br>"

        content += "<h3>Ride Leaders</h3>"
        for rider in self.list {
            if rider.isLeader {
                content += "Ride Leader: "+rider.getDisplayName()+"<br>"
            }
        }
        for rider in self.list {
            if rider.isCoLeader {
                content += "Ride Co-Leader: "+rider.getDisplayName()+"<br>"
            }
        }
        content += "<h3>Riders</h3>"
        for rider in self.list {
            if rider.selected() {
                content += rider.getDisplayName()
                if rider.isGuest {
                    content += " (guest)"
                }
                content += "<br>"
            }
        }

        if self.rideData.notes.count > 0 {
            content += "<h3>Notes</h3>"
            for note in self.rideData.notes {
                content += note+"<br>"
            }
        }
        if let title = self.rideData.title {
            content += "Title:"+title+"<br>"
        }
        content += "</body></html>"
        return content        
    }
}
