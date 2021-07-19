
import Foundation
import os.log

//TODO verify identity via ww sign in

class WAApi : ObservableObject {

    //static private var shared:WAApi! = nil
    private var token: String! = nil
    private var accountId:String! = nil

    var apiCallNum = 0
    
    enum ApiType {
        case LoadMembers, AuthenticateUser, None
    }
    
//    static func instance() -> WAApi {
//        if shared == nil {
//            shared = WAApi()
//        }
//        return shared
//    }
    
    func apiKey(key:String) -> String {
        let path = Bundle.main.path(forResource: "api_keys.txt", ofType: nil)!
        do {
            let fileData = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            let dict = try JSONSerialization.jsonObject(with: fileData.data(using: .utf8)!, options: []) as? [String:String]
            return dict?[key] ?? ""
        } catch {
            return ""
        }
    }
            
    func authenticateQuery() {
        let url = "https://api.wildapricot.org/publicview/v1/accounts/\(accountId)/contacts/me"
//        apiCallOld(path: url, withToken: true, usrMsg: "", completion: parseMembers, apiType: ApiType.LoadMembers, tellUsers: true)
    }

    func authenticateUserFromWASite (user: String, pwd: String) {
        let url = "https://oauth.wildapricot.org/auth/token"
//        makeApiCall(path: url, withToken: false, usrMsg: "Authenticating Wild Apricot Account", completion: parseAccessToken, apiType: ApiType.AuthenticateUser, tellUsers: false)
    }
    
    func runTask(req:URLRequest) -> Data? {
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var result:Data? = nil
        
        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                Messages.instance.reportError(context: "Privacy", msg: error.localizedDescription)
            }
            else {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 && response.statusCode != 501 {
                        Messages.instance.reportError(context: "WAApi", msg: "http status \(response.statusCode)")
                    }
                    else {
                        if let data = data {
                            result = data
                        }
                        else {
                            Messages.instance.reportError(context: "Privacy", msg: "no data in response")
                        }
                    }
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return result
    }
    
    func apiCall(url:String, username:String?, password:String?, completion: @escaping (Data) -> ()) {
        apiCallNum += 1
        if apiCallNum % 1 == 0 {
            print(apiCallNum, url)
        }
        var user = ""
        var pwd = ""
        if let uname = username {
            user = uname
            pwd = password!
        }
        else {
            user = apiKey(key: "WA_username")
            pwd = apiKey(key: "WA_pwd")
            pwd = pwd+pwd+pwd
        }
        
        //get API token
        let tokenUrl = "https://oauth.wildapricot.org/auth/token"
        var tokenRequest = URLRequest(url: URL(string: tokenUrl)!)

        let wwAuth = "Basic aXNleTBqYWZwOTplYzMxdDN1Zjl1dWFha2h6cXB3NXFsYWF1ZTFnaTY="
        tokenRequest.setValue(wwAuth, forHTTPHeaderField: "Authorization")
        tokenRequest.httpMethod = "POST"
        let postString = "grant_type=password&username=\(user)&password=\(pwd)&scope=auto"
        tokenRequest.httpBody = postString.data(using: String.Encoding.utf8);
        
        let data = self.runTask(req: tokenRequest)
        
        guard let tokenData = data else {
            Messages.instance.reportError(context: "WAApi", msg: "did not receive token data")
            return
        }
        var token:String?
        var accountId:String?
        
        do {
            let json = try JSONSerialization.jsonObject(with: tokenData, options: []) //as? [String: Any]
            if let data = json as? [String: Any] {
                if let tk = data["access_token"] as? String {
                    token = tk
                }
                if let perms = data["Permissions"] as? [[String: Any]] {
                    accountId = "\(perms[0]["AccountId"] as! NSNumber)"
                }
            }
        }
        catch {
            Messages.instance.reportError(context: "WAApi", msg: "cannot parse token data")
        }
        
        //make the API call with the token
        let components = url.components(separatedBy: "$id")
        let apiUrl = components[0]+accountId!+components[1]
        var request = URLRequest(url: URL(string: apiUrl)!)
        let tokenAuth = "Bearer \(token ?? "")"
        request.setValue(tokenAuth, forHTTPHeaderField: "Authorization")
        let apiData = self.runTask(req: request)
        if let data = apiData {
            completion(data)
        }
        else {
            Messages.instance.reportError(context: "WAApi", msg: "no data returned")
        }
    }
}


