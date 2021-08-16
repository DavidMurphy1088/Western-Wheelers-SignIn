import Foundation

class Preferences : ObservableObject {
    static let instance:Preferences = Preferences()
    @Published var lastNameFirst:Bool?
    private static var savedKey = "PREFERENCES"

    private init() {
        lastNameFirst = false
    }
    

//    func save() {
//        do {
//            let encoder = JSONEncoder()
//            if self.lastNameFirst == nil {
//                UserDefaults.standard.removeObject(forKey: Preferences.savedKey)
//            }
//            else {
//                if let data = try? encoder.encode(self.lastNameFirst) {
//                    let compressedData = try (data as NSData).compressed(using: .lzfse)
//                    UserDefaults.standard.set(compressedData, forKey: Preferences.savedKey)
//                }
//            }
//        }
//        catch {
//            let msg = "Error saving rider list \(error.localizedDescription)"
//            Messages.instance.reportError(context: "Preferences", msg: msg)
//        }
//    }
    
//    func restore() {
//        let savedData = UserDefaults.standard.object(forKey: Preferences.savedKey)
//        if let savedData = savedData {
//            do {
//                let json = try (savedData as! NSData).decompressed(using: .lzfse)
//                let decoder = JSONDecoder()
//                if let decoded = try? decoder.decode(String.self, from: json as Data) {
//                    //lastNameFirst = decoded
//                    //Messages.instance.sendMessage(msg: "Restored \(self.username ?? "") verification from local")
//                }
//            }
//            catch {
//                let msg = "Error restoring preferences \(error.localizedDescription)"
//                Messages.instance.reportError(context: "Preferences", msg: msg)
//            }
//        }
//    }
    

}
