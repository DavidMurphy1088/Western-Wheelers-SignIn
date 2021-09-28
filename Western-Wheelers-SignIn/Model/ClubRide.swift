import Foundation

class ClubRide : Identifiable, Decodable, Encodable, ObservableObject {
    var id:String
    var sessionId:String
    var name:String = ""
    var timeWasSpecified:Bool = true
    var dateTime: Date = Date()
    var activeStatus: Int = 0
    var levels:[String] = []
    static let LONGEST_RIDE_IN_HOURS = 8.0 //asume max ride length of 8 hrs

    init(id:String, name:String) {
        self.id = id
        self.sessionId = ""
        self.setName(name: name)
    }
    
    func setName(name:String) {
        var rideName = ""
        let words = name.components(separatedBy: " ")
        var cnt = 0
        for word in words {
            if word.contains("/") || word.count <= 1 {
                rideName = rideName + " " + word
            }
            else {
                let x = String(word.suffix(word.count-1))
                rideName = rideName + " " + word.prefix(1) + x.lowercased()
            }
            cnt += 1
        }
        self.name = rideName.trimmingCharacters(in: .whitespaces)
    }
    
    func rideNameNoLevels() -> String {
        var name = ""
        let words = self.name.components(separatedBy: " ")
        for word in words {
            //"D/3-4/35-65"
            if !(word.contains("/") || word.contains("-")) {
                name = name + " " + word
            }
        }
        return name
    }
    
    func setLevels() {
        var titleLevels: [String] = []
        //let name = "C/3/15+; D/4/15+ TUESDAY EVENING RIDE"
        let specs = name.components(separatedBy: ";")
        for spec in specs {
            let parts = spec.components(separatedBy: "/")
            for part in parts {
                let upPart = part.uppercased().trimmingCharacters(in: .whitespaces)
                var lvl = ""
                for c in upPart {
                    if c >= "A" && c <= "E" {
                        if !lvl.isEmpty {
                            titleLevels.append(lvl)
                        }
                        lvl = String(c)
                    }
                    else {
                        if c == "+" || c == "-" {
                            lvl  += String(c)
                        }
                        else {
                            lvl = ""
                            break
                        }
                    }
                }
                if !lvl.isEmpty {
                    titleLevels.append(lvl)
                }
            }
        }
        let levelSet = Set(titleLevels)
        titleLevels = []
        titleLevels.append(contentsOf: levelSet)
        titleLevels.sort()
        levels = []
        levels.append(contentsOf: titleLevels)
    }
    
    func nearTerm() -> Bool {
        let seconds = Date().timeIntervalSince(self.dateTime) // > 0 => ride start in past
        let minutes = seconds / 60.0
        let startHours = minutes / 60
        let endHours = startHours - ClubRide.LONGEST_RIDE_IN_HOURS
        
        if endHours > 16.0 {
            return false
        }
        else {
            if endHours > 0 {
                return false
            }
            else {
                if startHours > 0 {
                    return true
                }
                else {
                    if abs(startHours) < 48.0 {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
        }
    }
    
    func dateDisplay() -> String {
        return Messages.dateDisplay(dateToShow: self.dateTime, addDay: true, addTime: self.timeWasSpecified)
//        let formatter = DateFormatter() // this formats the day,time according to users local timezone
//        formatter.dateFormat = "EEEE MMM d"
//        let dayDisp = formatter.string(from: self.dateTime)
//        if !self.timeWasSpecified {
//            return dayDisp
//        }
//        
//        // force 12-hour format even if they have 24 hour set on phone
//        let timeFmt = "h:mm a"
//        formatter.setLocalizedDateFormatFromTemplate(timeFmt)
//        formatter.dateFormat = timeFmt
//        formatter.locale = Locale(identifier: "en_US")
//        let timeDisp = formatter.string(from: self.dateTime)
//        let disp = dayDisp + ", " + timeDisp
//        return disp
    }
}


