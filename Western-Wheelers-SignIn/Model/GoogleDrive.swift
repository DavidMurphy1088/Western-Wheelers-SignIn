import GoogleSignIn
import GoogleAPIClientForREST
import Foundation

class GoogleDrive : NSObject, GIDSignInDelegate {
    static let instance = GoogleDrive() //first called from AppDelegate didFinishLaunching
    var notificationName:String?
    var listFunc: ((GTLRDrive_FileList?, Error?) -> ())? = nil
    
    func application(_ application: UIApplication,
                   open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        //print("GoogleDrive::openURL", url)
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    override private init() {
        super.init()
    }

    private func signIn() {
        //print("GoogleDrive::start signIn")
        GIDSignIn.sharedInstance().restorePreviousSignIn()
        if GIDSignIn.sharedInstance().currentUser == nil {
            print("google drive init signing in")
            GIDSignIn.sharedInstance()?.signIn()
        }
        //print("GoogleDrive::END start signIn")
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        //print("GoogleDrive::BEGIN didSignIn")
        // called after a sign in -OR- after
        // a call to restorePreviousSignIn which will attempt to restore a previously authenticated user without interaction.
        // This delegate will then be called at the end of this process indicating success or failure
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            //return
        }
        else {
            print("GoogleDrive::The user was newly signed in")
        }

        //let fullName = user.profile.name
//        NotificationCenter.default.post(
//          name: Notification.Name(rawValue: "ToggleAuthUINotification"),
//          object: nil,
//          userInfo: ["statusText": "Signed in user:\n\(fullName!)"])
        NotificationCenter.default.post(name: Notification.Name(self.notificationName!), object: error)
        //print("GoogleDrive::END didSignIn")
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        //print("GoogleDrive::Did Disconnet")
    }

    public func getId(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        
        query.q = "name contains '\(fileName)'"
        let service = GTLRDriveService()
        if let user = GIDSignIn.sharedInstance().currentUser {
            service.authorizer = user.authentication.fetcherAuthorizer()
            service.executeQuery(query) { (ticket, results, error) in
                onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
            }
        }
    }
    
    public func listFilesInFolder(onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        if self.notificationName == nil {
            self.notificationName = "LIST_FILES"
            NotificationCenter.default.addObserver(self, selector: #selector(listFilesInFolderNotified), name: Notification.Name(self.notificationName!), object: nil)
        }
        listFunc = onCompleted
        signIn()
    }
    
    @objc func listFilesInFolderNotified() {
        getId("Ride_Templates") { (folderID, error) in
            guard let ID = folderID else {
                self.listFunc!(nil, error)
                return
            }
            self.listFiles(ID, onCompleted: self.listFunc!)
        }
    }
    
    private func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.q = "'\(folderID)' in parents"
        let service = GTLRDriveService()
        service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()
        service.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }

    func readSheet(id:String, onCompleted: @escaping ([[String]]) -> ())  {
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: id, range: "A1:B100")
        let service = GTLRSheetsService()
        service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()

        service.executeQuery(query) { (ticket:GTLRServiceTicket, result:Any?, error:Error?) in
            var sheetData:[[String]] = []
            if let error = error {
                print("GoogleDrive::Error", error.localizedDescription)
            } else {
                let data = result as? GTLRSheets_ValueRange
                let rows = data?.values as? [[String]] ?? [[""]]
                for row in rows {
                    sheetData.append(row)
                }
            }
            onCompleted(sheetData)
        }
    }

    public func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        let service = GTLRDriveService()
        service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()
        service.executeQuery(query) { (ticket, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }

}
