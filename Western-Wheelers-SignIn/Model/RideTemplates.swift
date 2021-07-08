import Foundation
import GoogleAPIClientForREST

class RideTemplate: Identifiable, Hashable, Equatable {
    var id = UUID()
    var name: String = ""
    var ident: String = ""
    var isSelected: Bool = false
    init(name: String, ident: String){
        self.name = name
        self.ident = ident
    }
    
    static func == (lhs: RideTemplate, rhs: RideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    func requestLoad(ident:String) {
        GoogleDrive.instance.readSheet(id: self.ident, onCompleted:loadData(data:))
    }
    
    func loadData(data:[[String]]) {
        for row in data {
            if row.count > 1 && (row[1] == "TRUE" || row[1] == "FALSE") { // and row.count == 2
                if row[0] != "" {
                    let name = row[0]
                    var phone = ""
                    var email = ""
                    if let rider = ClubRiders.instance.get(name: name) {
                        phone = rider.phone
                        email = rider.email
                    }
                    else {
                        if row.count > 2 {
                            phone = row[2]
                        }
                        if row.count > 3 {
                            email = row[3]
                        }
                    }
                    let rider = Rider(name: name, phone: phone, emrg: "", email: email)
                    if row[1] == "TRUE" {
                        rider.setSelected(true)
                    }
                    SignedInRiders.instance.list.append(rider)
                }
            }
            else {
                var note = ""
                for fld in row {
                    note += fld
                }
                SignedInRiders.instance.notes.append(note)
            }
        }
    }
}

class RideTemplates : ObservableObject {
    static let instance = RideTemplates() //called when shared first referenced
    @Published var templates:[RideTemplate] = []

    private init() {
    }
    
    func setSelected(name: String) {
        for t in templates {
            if t.name == name {
                t.isSelected = true
            }
            else {
                t.isSelected = false
            }
        }
        //force an array change to publish the row change
        templates.append(RideTemplate(name: "", ident: ""))
        templates.remove(at: templates.count-1)
    }
    
    func loadTemplates() {
        let drive = GoogleDrive.instance
        drive.listFilesInFolder(onCompleted: self.saveTemplates)
    }
    
    func saveTemplates(files: GTLRDrive_FileList?, error: Error?) {
        templates = []
        if let filesList : GTLRDrive_FileList = files {
            if let filesShow : [GTLRDrive_File] = filesList.files {
                for file in filesShow {
                    if let name = file.name {
                        self.templates.append(RideTemplate(name: name, ident: file.identifier!))
                    }
                }
            }
        }
    }
}
