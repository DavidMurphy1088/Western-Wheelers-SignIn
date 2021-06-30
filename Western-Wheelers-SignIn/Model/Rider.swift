import Foundation
class Rider : Hashable, Equatable, Identifiable {
    var name:String
    var homePhone:String
    var cellPhone:String
    var emergencyPhone:String
    var isSelected: Bool
    
    init (name:String, homePhone:String, cell:String, emrg:String) {
        self.name = name
        self.homePhone = homePhone
        self.cellPhone = cell
        self.emergencyPhone = emrg
        self.isSelected = false
    }
    
    static func == (lhs: Rider, rhs: Rider) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
