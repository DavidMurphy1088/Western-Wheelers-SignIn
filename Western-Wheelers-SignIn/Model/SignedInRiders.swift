import Foundation

class SignedInRiders : ObservableObject {
    static let instance:SignedInRiders = SignedInRiders()
    @Published public var list:[Rider] = []
    var notes:[String] = []
    var templateName:String? = nil
    private static var savedDataName1 = "SIGNED_IN_RIDERS"
    private static var savedDataName2 = "SIGNED_IN_RIDERS_NOTES"
    private static var savedDataName3 = "SIGNED_IN_RIDERS_SIGNIN"
    var firstSignIn:String? = nil
    
    private init() {
    }
        
    func save() {
        do {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.list) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedDataName1)
            }
            if let data = try? encoder.encode(self.notes) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedDataName2)
            }
            if firstSignIn != nil {
                if let data = try? encoder.encode(self.firstSignIn) {
                    //let compressedData = try (data as NSData).compressed(using: .lzfse)
                    UserDefaults.standard.set(data, forKey: SignedInRiders.savedDataName3)
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
            let json = savedData as! NSData //.decompressed(using: .lzfse)
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(String.self, from: json as Data) {
                firstSignIn = decoded
            }
        }
    }
    
    func clearData() {
        list = []
        notes = []
        firstSignIn = nil
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
        list.append(Rider(name: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
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
        list.append(Rider(name: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
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
//        for i in 0...10 {
//            list.append(Rider(name:"David_\(i)", homePhone: "650 995 4361", cell: "", emrg: ""))
//        }
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
    
    func filter(name: String) {
        for r in list {
            if r.name.lowercased().contains(name.lowercased()) {
                r.setSelected(true)
            }
            else {
                r.setSelected(false)
            }
        }
        //force an array change to publish the row change
        list.append(Rider(name: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
    }
    
    func setFirstSignIn() {
        if firstSignIn == nil {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm EEEE, d MMM y"
            let dateStr = formatter.string(from: today)
            firstSignIn = dateStr
        }

    }
    func setSelected(name: String) {
        for r in list {
            if r.name == name {
                r.setSelected(true)
                break
            }
        }
        setFirstSignIn()
        //force an array change to publish the row change
        list.append(Rider(name: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
    }
    
    func toggleSelected(name: String) {
        var fnd = false
        for r in list {
            if r.name == name {
                r.setSelected(!r.selected())
                if r.selected() {
                    fnd = true
                    setFirstSignIn()
                }
            }
        }
        if !fnd {
            firstSignIn = nil
        }
        //force an array change to publish the row change
        list.append(Rider(name: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
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
    }
    
    func getHTMLContent() -> String {
        var content = "<html><body>"
        content += "<h3>Rider Leaders</h3>"
        for rider in self.list {
            if rider.isLeader {
                content += "Ride Leader:"+rider.name+"<br>"
            }
        }
        for rider in self.list {
            if rider.isCoLeader {
                content += "Ride Co-Leader:"+rider.name+"<br>"
            }
        }
        content += "<h3>Riders</h3>"
        for rider in self.list {
            if rider.selected() {
                content += rider.name+"<br>"
            }
        }
        if let first = self.firstSignIn  {
            content += "<h3>Sign In Date</h3>"
            content += first+"<br>"
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
