import Foundation
import SwiftSoup

//No longer required. This class attempted to look up the user's privacy settings for access to email and phone
//However WA finally advised (16Jul2021)that their 'non-admin' API now honors the usrs privacy settings so this class below is not needed now.

class PrivacyChecker {
    static let instance:PrivacyChecker = PrivacyChecker()
    var queue:[Rider] = []
    private let shared = URLSession.shared

    init() {
        shared.configuration.httpCookieStorage = HTTPCookieStorage.shared
        shared.configuration.httpCookieAcceptPolicy = .always
        shared.configuration.httpShouldSetCookies = true
    }

//    func start() {
//        DispatchQueue.global(qos: .background).async { [self] in
//            while true {
//                if queue.count > 0 {
//                    let checkMember = queue.remove(at: 0)
//                    print("\n---------> PrivacyChecker", checkMember.name)
//                    if checkMember.id != "" {
//                        getContact(rider: checkMember)
//                        DispatchQueue.main.async {
//                            checkMember.isPrivacyVerified = true
//                        }
//                    }
//                }
//                sleep(1)
//            }
//        }
//    }
    
//    func checkRider(rider:Rider) {
//        queue.append(rider)
//    }

//    func getContact(rider:Rider) {
//        let id = rider.id
//        get(url: "https://westernwheelersbicycleclub.wildapricot.org/Sys/Login?ReturnUrl=/admin/contacts/details/?contactId=\(id)")
//        
//        post(url: "https://westernwheelersbicycleclub.wildapricot.org/Sys/Login?ReturnUrl=/admin/contacts/details/?contactId==\(id)")
//"https://westernwheelersbicycleclub.wildapricot.org/Admin/Contacts/Details/ContactTab/ContactView.aspx?contactId=60826411", show: false)
//        
//        let html = get(url: "https://westernwheelersbicycleclub.wildapricot.org/Admin/Contacts/Details/ProfileAccessSettingsTab/ProfileAccessSettingsView.aspx?contactId=\(id)", show: false)
//        print("XXXXXX=======", rider.email, rider.id, html?.count, rider.email.isEmpty, html!.contains(rider.email))
//        if let html = html {
//        }
//        else {
//            //Messages.instance.reportError(context: "Privacy", msg: "Cannot get privacy for \(rider.name)")
//        }
//
//    }
    
    func getPrivacySetting(html:String, tag:String) -> String {
        var res = ""
        do {
            let doc = try SwiftSoup.parse(html)
            let spans = try doc.getElementsByClass("fieldTitle")
            for span in spans {
                let par = span.parent()
                let tds = try par?.getElementsByTag("td")
                if let tds = tds {
                    var cnt = 0
                    var fnd = false
                    for td in tds {
                        let tdstr = "\(td)"
                        if cnt==0 {
                            if tdstr.contains(tag) {
                                fnd = true
                            }
                            else {
                                break
                            }
                        }
                        res += String(td.children().count - 1)
                        cnt += 1
                    }
                    if fnd {
                        break
                    }
                }
            }
        }
        catch {
            let msg = "Error \(error.localizedDescription)"
            print(msg)
        }
        return res
    }
    
    func handleResponse(ctx:String, url:String, data:Data?, response:URLResponse?, error:Error?) -> String! {
        var ret:String! = nil
        guard error == nil else  {
            Messages.instance.reportError(context: "Privacy", msg: error?.localizedDescription ?? "")
            return ret
        }
        guard let response = response as? HTTPURLResponse else {
            return ret
        }
        if response.statusCode != 200 && response.statusCode != 501 {
            Messages.instance.reportError(context: "Privacy", msg: "http status \(response.statusCode)")
            return ret
        }
        //print("HTTP status", response.statusCode)

        if let data = data {
            ret = String(data: data, encoding: .utf8)
        }
        else {
            Messages.instance.reportError(context: "Privacy", msg: "no data in response")
        }
        return ret
    }
    
    func getReq(url:String, post:Bool) -> URLRequest {
        var req = URLRequest(url: URL(string: url)!)
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("keep-alive", forHTTPHeaderField: "Connection")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        req.setValue("westernwheelersbicycleclub.wildapricot.org", forHTTPHeaderField: "Host")
        return req
    }
    
    func post(url: String) {
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var request = getReq(url: url, post: true)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9", forHTTPHeaderField: "Accept")
        request.setValue("max-age=0", forHTTPHeaderField: "Cache-Control")
        request.setValue("https://westernwheelersbicycleclub.wildapricot.org", forHTTPHeaderField: "Origin")
        request.setValue("https://westernwheelersbicycleclub.wildapricot.org/Sys/Login?ReturnUrl=/admin/contacts/details/?contactId=60826411", forHTTPHeaderField: "Referer")
        
        request.httpMethod = "POST"
        var postString = "email=davidp.murphy@sbcglobal.net&password=zenzenzen&ReturnUrl=/admin/contacts/details/?contactId=60826411";
        postString += "&browserData=WebKit;Exec Command;Client Cookies Enabled;Platform Compatible;Javascript Enabled;" //required to avoid HTTP 501
        request.httpBody = postString.data(using: String.Encoding.utf8);

        let task = shared.dataTask(with: request) { data, response, error in
            //self.handleResponse(ctx: "Post", url: url, data: data, response: response, error: error)
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }
}
