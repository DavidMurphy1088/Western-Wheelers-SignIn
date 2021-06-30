import Foundation

class SignedInRiders : ObservableObject{
    static let shared:SignedInRiders = SignedInRiders()
    @Published public var list:[Rider] = []
    
    private init() {
        for i in 0...20 {
            list.append(Rider(name:"David_\(i)", homePhone: "650 995 4261", cell: "", emrg: ""))
        }
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
        list.append(Rider(name: "", homePhone: "", cell: "", emrg: ""))
        list.remove(at: list.count-1)
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
        list.append(Rider(name: "", homePhone: "", cell: "", emrg: ""))
        list.remove(at: list.count-1)
    }
    
    func add(rider:Rider) {
        list.append(rider)
    }
}
