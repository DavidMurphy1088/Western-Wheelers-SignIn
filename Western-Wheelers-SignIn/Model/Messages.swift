
import Foundation

class Messages : ObservableObject {
    static public let instance = Messages()
    @Published public var message:String? = nil
    @Published public var errMessage:String? = nil

    func sendMessage(msg: String) {
        DispatchQueue.main.async {
            print("MESSAGE", msg)
            self.message = msg
        }
    }
    func reportError(context:String, msg: String? = nil, error:Error? = nil) {
        DispatchQueue.main.async {
            var message:String = msg ?? ""
            if !NetworkReachability().checkConnection() {
                message += "\nInternet appears to be offline"
            }
            if let err = error {
                message += " " + err.localizedDescription
            }
            print("ERROR", context, message)
            self.errMessage = context + " " + message
        }
    }
    func clearError() {
        DispatchQueue.main.async {
            self.errMessage = ""
        }
    }

}
