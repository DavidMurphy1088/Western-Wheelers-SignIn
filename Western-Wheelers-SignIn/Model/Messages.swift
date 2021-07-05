
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
    func reportError(context:String, msg: String) {
        DispatchQueue.main.async {
            print("ERROR", context, msg)
            self.errMessage = context + " " + msg
        }
    }
    func clearError() {
        self.errMessage = ""
    }

}
