import Foundation
class Rider : Hashable, Equatable, Identifiable, Encodable, Decodable {
    var name:String
    var homePhone:String
    var cellPhone:String
    var emergencyPhone:String
    var isSelected: Bool
    
    init (name:String, homePhone:String, cell:String, emrg:String) {
        self.name = name
        self.homePhone = Rider.formatPhone(phone: homePhone)
        self.cellPhone = Rider.formatPhone(phone: cell)
        self.emergencyPhone = Rider.formatPhone(phone: emrg)
        self.isSelected = false
    }
    
    init (rider:Rider) {
        self.name = rider.name
        self.homePhone = rider.homePhone
        self.cellPhone = rider.cellPhone
        self.emergencyPhone = rider.emergencyPhone
        self.isSelected = false
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
