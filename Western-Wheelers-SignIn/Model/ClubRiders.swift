import Foundation

class ClubRiders : ObservableObject {
    @Published public var list:[Rider] = []
    static let shared:ClubRiders = ClubRiders()
    
    private init() {
        WAApi.instance()
        list.append(Rider(name:"fred1", homePhone: "650 995 4261", cell: "650 995 4261", emrg: ""))
        list.append(Rider(name:"david2", homePhone: "650 995 4261", cell: "650 995 4261", emrg: ""))
    }
    
    func get(name:String) -> Rider? {
        for r in list {
            if r.name == name {
                return r
            }
        }
        return nil
    }
    
    func getFirstSelected() -> Rider? {
        for r in list {
            if r.isSelected {
                return r
            }
        }
        return nil
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
}
