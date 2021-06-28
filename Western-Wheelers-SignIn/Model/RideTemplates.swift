import Foundation
import GoogleAPIClientForREST

class RideTemplate: Identifiable, Hashable, Equatable {
    static func == (lhs: RideTemplate, rhs: RideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
        
    var id = UUID()
    var name: String = ""
    var isSelected: Bool = false

    init(name: String){
        self.name = name
    }
}

class RideTemplates : ObservableObject {
    static let shared = RideTemplates() //called when shared first referenced
    @Published var templates:[RideTemplate] = []

    private init() {
        print("RideTemplates:: init...")
        //DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            //self.load()
        //}
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
        templates.append(RideTemplate(name: ""))
        templates.remove(at: templates.count-1)
    }
    
    func loadTemplates() {
        print("RideTemplates:: loading temps...")
        if templates.count == 0 {
            let drive = GoogleDrive.shared
            drive.listFilesInFolder(onCompleted: self.saveTemplates)
        }
    }
    
    func saveTemplates(files: GTLRDrive_FileList?, error: Error?) {
        if let filesList : GTLRDrive_FileList = files as? GTLRDrive_FileList {
            if let filesShow : [GTLRDrive_File] = filesList.files {
                for Array in filesShow {
                    print(Array.name, Array.identifier, Array.appProperties)
//                    let mimeType = Array.mimeType
//                    let id = Array.identifier
//                    let folder = (mimeType as NSString?)?.pathExtension
//                    let isfolder = true
//                    let parents = Array.parents
//                    var parentPath : String!
                    self.templates.append(RideTemplate(name: Array.name ?? "no name"))
                }
            }
        }
    }
}
