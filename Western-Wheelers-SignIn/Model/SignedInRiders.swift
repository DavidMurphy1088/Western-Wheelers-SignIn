import Foundation

class SignedInRiders : ObservableObject {
    static let instance:SignedInRiders = SignedInRiders()
    @Published private var list:[Rider] = []
    
    var notes:[String] = []
    var templateName:String? = nil
    var rideTitle:String? = nil
    var lastSignIn:String? = nil

    private static var savedDataName1 = "SIGNED_IN_RIDERS"
    private static var savedDataName2 = "SIGNED_IN_RIDERS_NOTES"
    private static var savedDataName3 = "SIGNED_IN_RIDERS_SIGNIN"
    private static var savedDataName4 = "SIGNED_IN_RIDERS_TITLE"
    
    private init() {
    }
    
    func getCount() -> Int {
        return list.count
    }
    
    func getList() -> [Rider] {
        return list
    }
    func show() {
        for r in self.list {
            print(r.name, r.isPrivacyVerified)
        }
    }
    func save() {
        do {
            show()
            let encoder = JSONEncoder()

            if let data = try? encoder.encode(self.list) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedDataName1)
            }
            if let data = try? encoder.encode(self.notes) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedDataName2)
            }
            if lastSignIn != nil {
                if let data = try? encoder.encode(self.lastSignIn) {
                    UserDefaults.standard.set(data, forKey: SignedInRiders.savedDataName3)
                }
            }
            if rideTitle != nil {
                if let data = try? encoder.encode(self.rideTitle) {
                    UserDefaults.standard.set(data, forKey: SignedInRiders.savedDataName4)
                }
            }
        }
        catch {
            let msg = "Error saving rider list \(error.localizedDescription)"
            Messages.instance.reportError(context: "SignedInRiders", msg: msg)
        }
    }
    
    func restore() {
        var savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedDataName1)
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
        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedDataName2)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode([String].self, from: json as Data) {
                    notes = decoded
                }
            }
            catch {
                let msg = "Error restoring rider list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedDataName3)
        if let savedData = savedData {
            let json = savedData as! NSData
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(String.self, from: json as Data) {
                lastSignIn = decoded
            }
        }
        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedDataName4)
        if let savedData = savedData {
            let json = savedData as! NSData
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(String.self, from: json as Data) {
                rideTitle = decoded
            }
        }
    }
    
    func clearData() {
        list = []
        notes = []
        lastSignIn = nil
        rideTitle = nil
    }
    
    func setLeader(rider:Rider, way:Bool) {
        for r in list {
            if r.name == rider.name {
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
            if r.name == rider.name {
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
        self.templateName = name
        for template in RideTemplates.instance.templates {
            if template.name == name {
                template.requestLoad(ident: template.ident)
                break
            }
        }
        rideTitle = name
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
            if r.name.lowercased().contains(name.lowercased()) {
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
        lastSignIn = dateStr
    }

    func setSelected(name: String) {
        for r in list {
            if r.name == name {
                r.setSelected(true)
                break
            }
        }
        setSignInDate()
        self.pushChange()
    }
    
    func pushChange() {
        //force an array change to publish the row change
        list.append(Rider(id: "", name: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
    }
    
    func setHilighted(name: String) {
        for r in list {
            if r.name == name {
                r.isHilighted = true
            }
            else {
                r.isHilighted = false
            }
        }
        self.pushChange()
    }

    func toggleSelected(name: String) {
        var fnd = false
        for r in list {
            if r.name == name {
                r.setSelected(!r.selected())
                if r.selected() {
                    fnd = true
                    setSignInDate()
                }
            }
        }
        if !fnd {
            lastSignIn = nil
        }
        self.pushChange()
    }

    func sort () {
        list.sort {
            $0.name < $1.name
        }
    }
    
    func add(rider:Rider) {
        var fnd = false
        for r in list {
            if r.name == rider.name {
                fnd = true
                break
            }
        }
        if !fnd {
            list.append(rider)
        }
        sort()
        if rider.inDirectory && !rider.isPrivacyVerified {
            PrivacyChecker.instance.checkRider(rider: rider)
        }
    }
    
    func remove(name:String) {
        var i = 0
        for r in list {
            if r.name == name {
                list.remove(at: i)
                break
            }
            i += 1
        }
        sort()
    }
    
    func getHTMLContent() -> String {
        var content = "<html><body>"
        if let title = rideTitle {
            content += "<h3>\(title)</h3>"
        }
        content += "<h3>Ride Info</h3>"
        if let first = self.lastSignIn  {
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
                content += "Ride Leader: "+rider.name+"<br>"
            }
        }
        for rider in self.list {
            if rider.isCoLeader {
                content += "Ride Co-Leader: "+rider.name+"<br>"
            }
        }
        content += "<h3>Riders</h3>"
        for rider in self.list {
            if rider.selected() {
                content += rider.name
                if rider.isGuest {
                    content += " (guest)"
                }
                content += "<br>"
            }
        }

        if self.notes.count > 0 {
            content += "<h3>Notes</h3>"
            for note in self.notes {
                content += note+"<br>"
            }
        }
        if let templateName = self.templateName {
            content += "Ride Template:"+templateName+"<br>"
        }
        content += "</body></html>"
        return content        
    }
}
