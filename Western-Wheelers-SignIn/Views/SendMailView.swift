import MessageUI
import SwiftUI
import CoreData
import MessageUI

struct SendMailView: UIViewControllerRepresentable {
    //TODO mail errors?
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(isShowing: Binding<Bool>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _isShowing = isShowing
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            print ("DISMISS MAIL...")
            defer {
                isShowing = false
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
            controller.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing,
                           result: $result)
    }
    func makeUIViewController(context: UIViewControllerRepresentableContext<SendMailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setSubject("Test from WW")
        vc.setToRecipients(["davidp.murphy@sbcglobal.net"])
        let msg = "<html><body><h1>My First Heading</h1><p>My first paragraph.</p></body></html>"
        vc.setMessageBody(msg, isHTML: true)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<SendMailView>) {

    }
}

