import Foundation
class Rider : Hashable, Equatable, Identifiable, Encodable, Decodable {
    var name:String
    var phone:String
    var emergencyPhone:String
    var email:String
    private var isSelected: Bool
    
    init (name:String, phone:String, emrg:String, email:String) {
        self.name = name
        self.phone = Rider.formatPhone(phone: phone)
        self.emergencyPhone = Rider.formatPhone(phone: emrg)
        self.email = email
        self.isSelected = false
    }
    
    init (rider:Rider) {
        self.name = rider.name
        self.phone = rider.phone
        self.emergencyPhone = rider.emergencyPhone
        self.email = rider.email
        self.isSelected = false
    }
    
    static func == (lhs: Rider, rhs: Rider) -> Bool {
        return lhs.name == rhs.name
    }
    
    func setSelected(_ way:Bool) {
        self.isSelected = way
    }
    
    func selected() -> Bool {
        return self.isSelected
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
