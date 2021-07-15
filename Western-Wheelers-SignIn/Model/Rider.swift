import Foundation

class Rider : Hashable, Equatable, Identifiable, Encodable, Decodable, ObservableObject {
    var id:String
    var name:String
    var phone:String
    var emergencyPhone:String
    var email:String
    var isSelected: Bool
    var isHilighted: Bool
    var isLeader:Bool
    var isCoLeader:Bool
    var inDirectory:Bool
    var isGuest:Bool
    @Published var isPrivacyVerified: Bool //updated in background
    var accessEmail: Bool
    var accessEmergencyPhone: Bool
    var accessPhone: Bool

    init (id:String, name:String, phone:String, emrg:String, email:String, isGuest:Bool = false) {
        self.id = id
        self.name = name
        self.phone = Rider.formatPhone(phone: phone)
        self.emergencyPhone = Rider.formatPhone(phone: emrg)
        self.email = email
        self.isSelected = false
        self.isHilighted = false
        self.isLeader = false
        self.isCoLeader = false
        self.inDirectory = false
        self.isPrivacyVerified = false
        self.accessPhone = false
        self.accessEmergencyPhone = false
        self.accessEmail = false
        self.isGuest = isGuest
    }
    
    init (rider:Rider) {
        self.id = rider.id
        self.name = rider.name
        self.phone = rider.phone
        self.emergencyPhone = rider.emergencyPhone
        self.email = rider.email
        self.isSelected = rider.isSelected
        self.isHilighted = rider.isHilighted
        self.isLeader = rider.isLeader
        self.isCoLeader = rider.isCoLeader
        self.inDirectory = rider.inDirectory
        self.isPrivacyVerified = rider.isPrivacyVerified
        self.accessPhone = rider.accessPhone
        self.accessEmergencyPhone = rider.accessEmergencyPhone
        self.accessEmail = rider.accessEmail
        self.isGuest = rider.isGuest
    }
    
    enum CodingKeys: String, CodingKey {
        //requires hand crafted code if type contains any published types
        case id
        case name
        case phone
        case emergencyPhone
        case email
        case isSelected
        case isHilighted
        case isLeader
        case isCoLeader
        case inDirectory
        case isGuest
        case isPrivacyVerified
        case accessEmail
        case accessEmergencyPhone
        case accessPhone
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(phone, forKey: .phone)
        try container.encode(emergencyPhone, forKey: .emergencyPhone)
        try container.encode(email, forKey: .email)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isHilighted, forKey: .isHilighted)
        try container.encode(isLeader, forKey: .isLeader)
        try container.encode(isCoLeader, forKey: .isCoLeader)
        try container.encode(inDirectory, forKey: .inDirectory)
        try container.encode(isGuest, forKey: .isGuest)
        try container.encode(isPrivacyVerified, forKey: .isPrivacyVerified)
        try container.encode(accessEmail, forKey: .accessEmail)
        try container.encode(accessPhone, forKey: .accessPhone)
        try container.encode(accessEmergencyPhone, forKey: .accessEmergencyPhone)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.phone = try container.decode(String.self, forKey: .phone)
        self.emergencyPhone = try container.decode(String.self, forKey: .emergencyPhone)
        self.email = try container.decode(String.self, forKey: .email)
        self.isSelected = try container.decode(Bool.self, forKey: .isSelected)
        self.isHilighted = try container.decode(Bool.self, forKey: .isHilighted)
        self.isLeader = try container.decode(Bool.self, forKey: .isLeader)
        self.isCoLeader = try container.decode(Bool.self, forKey: .isCoLeader)
        self.inDirectory = try container.decode(Bool.self, forKey: .inDirectory)
        self.isGuest = try container.decode(Bool.self, forKey: .isGuest)
        self.isPrivacyVerified = try container.decode(Bool.self, forKey: .isPrivacyVerified)
        self.accessEmail = try container.decode(Bool.self, forKey: .accessEmail)
        self.accessPhone = try container.decode(Bool.self, forKey: .accessPhone)
        self.accessEmergencyPhone = try container.decode(Bool.self, forKey: .accessEmergencyPhone)
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
