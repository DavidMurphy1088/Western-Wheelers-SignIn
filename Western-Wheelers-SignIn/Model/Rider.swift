import Foundation

class Rider : Hashable, Equatable, Identifiable, Encodable, Decodable, ObservableObject {
    var name:String
    var phone:String
    var emergencyPhone:String
    var email:String
    var isSelected: Bool
    var isLeader:Bool
    var isCoLeader:Bool
    var inDirectory:Bool

    init (name:String, phone:String, emrg:String, email:String) {
        self.name = name
        self.phone = Rider.formatPhone(phone: phone)
        self.emergencyPhone = Rider.formatPhone(phone: emrg)
        self.email = email
        self.isSelected = false
        self.isLeader = false
        self.isCoLeader = false
        self.inDirectory = false
    }
    
    init (rider:Rider) {
        self.name = rider.name
        self.phone = rider.phone
        self.emergencyPhone = rider.emergencyPhone
        self.email = rider.email
        self.isSelected = rider.isSelected
        self.isLeader = rider.isLeader
        self.isCoLeader = rider.isCoLeader
        self.inDirectory = rider.inDirectory
    }
    
    func selected() -> Bool {
        return self.isSelected
    }
    func setSelected(_ way:Bool) {
        self.isSelected = way
    }
    
    func setLeader(_ way:Bool) {
        self.isLeader = way
    }
    
    func getLeader() -> Bool {
        return self.isLeader
    }

    static func == (lhs: Rider, rhs: Rider) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func formatPhone(phone:String) -> String {
        if phone.count==0 {
            return ""
        }
        var num = "("
        for c in phone {
            if c.isNumber {
                num += String(c)
                if num.count == 4 {
                    num += String(") ")
                }
                if num.count == 9 {
                    num += String("-")
                }
            }
        }
        return num
    }
}
