import Foundation

class Rider : Hashable, Equatable, Identifiable {
    var name:String
    var phone:String
    var isSelected: Bool
    init (_ name:String, phone:String) {
        self.name = name
        self.phone = phone
        self.isSelected = false
    }
    static func == (lhs: Rider, rhs: Rider) -> Bool {
        return lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class Riders : ObservableObject{
    static let shared:Riders = Riders()
    @Published public var list:[Rider] = []
    private init() {
        for i in 0...20 {
            list.append(Rider("David_\(i)", phone: "650 995 4261"))
        }
    }
    func setSelected(name: String) {
        for r in list {
            if r.name == name {
                r.isSelected = true
            }
            else {
                r.isSelected = false
            }
        }
        //force an array change to publish the row change
        list.append(Rider("", phone: ""))
        list.remove(at: list.count-1)
    }
    
    func filter(name: String) {
        for r in list {
            if r.name.lowercased().contains(name.lowercased()) {
                r.isSelected = true
            }
            else {
                r.isSelected = false
            }
        }
        //force an array change to publish the row change
        list.append(Rider("", phone: ""))
        list.remove(at: list.count-1)
    }
}
