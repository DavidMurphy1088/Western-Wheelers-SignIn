import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

var riderForDetail:Rider? = nil //cannot get binding approach to work :(
//TODO message waiting on first list download

struct RiderView: View {
    @Binding var activeSheet:ActiveSheet?
    @State var rider: Rider
    @State var selectedAction: () -> Void
    @State var deletedAction: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(" ")
                Image(systemName: (self.rider.selected() ? "checkmark.square" : "square"))
                .onTapGesture {
                    self.selectedAction()
                }
                Button(rider.name, action: {
                    self.selectedAction()
                })
                //.font(rider.selected() ? Font.headline.weight(.semibold) : Font.headline.weight(.regular))
                //.foregroundColor(.black)
                Spacer()
                if self.rider.isLeader {
                    Text("Leader").italic()
                }
                else {
                    if self.rider.isCoLeader {
                        Text("Co-leader").italic()
                    }
                }

                Image(systemName: ("ellipsis.bubble")).foregroundColor(.purple)
                    .onTapGesture {
                        riderForDetail = self.rider
                        activeSheet = .showDetail
                    }
                Text("  ")
                Image(systemName: ("minus.circle")).foregroundColor(.purple)
                    .onTapGesture {
                        self.deletedAction()
                    }
                Text(" ")
            }
            Text("")
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        //.foregroundColor(rider.selected() ? .black : .secondary)
        .id(self.rider.name)
    }
}

struct RidersView: View {
    @Binding var activeSheet:ActiveSheet?
    @Binding var scrollToRiderName:String
    @ObservedObject var signedInRiders = SignedInRiders.instance
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(signedInRiders.list, id: \.self.name) { rider in
                            RiderView(activeSheet: $activeSheet, rider: rider,
                                     selectedAction: {
                                         DispatchQueue.main.async {
                                             signedInRiders.toggleSelected(name: rider.name)
                                         }
                                     },
                                     deletedAction: {
                                        DispatchQueue.main.async {
                                            signedInRiders.remove(name: rider.name)
                                        }
                                     })
                        }
                    }
                    .onChange(of: scrollToRiderName) { target in
                        if scrollToRiderName != "" {
                            withAnimation {
                                proxy.scrollTo(scrollToRiderName)
                            }
                        }
                    }
                }
            }
            .border(Color.blue)
            .padding()

        }
     }
}

enum ActiveSheet: Identifiable {
    case templates, addRider, addGuest, email, showDetail
    var id: Int {
        hashValue
    }
}
enum CommunicationType: Identifiable {
    case phone, text, email
    var id: Int {
        hashValue
    }
}

extension  CurrentRideView {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
    private class MailComposerDelegate: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }

    private func presentMessageCompose(rider:Rider, way:CommunicationType) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if way == CommunicationType.text {
            let composeVC = MFMessageComposeViewController()
            composeVC.recipients = [rider.phone]
            composeVC.messageComposeDelegate = messageComposeDelegate
            vc?.present(composeVC, animated: true)
        }
        if way == CommunicationType.email {
            let mailVC = MFMailComposeViewController()
            mailVC.setToRecipients([rider.email])
            mailVC.mailComposeDelegate = mailComposeDelegate
            vc?.present(mailVC, animated: true)
        }
    }
}

struct CurrentRideView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State private var confirmShowing = false
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var scrollToRiderName:String = ""
    @State var confirmClean:Bool = false
    @State var activeSheet: ActiveSheet?
    private let messageComposeDelegate = MessageComposerDelegate()
    private let mailComposeDelegate = MailComposerDelegate()

    @ObservedObject var messages = Messages.instance

    func addRider(rider:Rider, clubMember: Bool) {
        rider.setSelected(true)
        if ClubMembers.instance.get(name: rider.name) != nil {
            rider.inDirectory = true
        }
        SignedInRiders.instance.add(rider: Rider(rider: rider))
        SignedInRiders.instance.setSelected(name: rider.name)
        self.scrollToRiderName = rider.name
        ClubMembers.instance.clearSelected()
    }
    
    func version() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let bld = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let info = "Version \(version) build \(bld)"
        return info
    }
    
    func riderCommunicate(rider:Rider, way:CommunicationType) {
        DispatchQueue.global(qos: .userInitiated).async {
            //only way to get this to work. i.e. wait for detail view to be shut down fully before text ui is displayed
            usleep(500000)
            DispatchQueue.main.async {
                if way == CommunicationType.phone {
                    //let url:NSURL = URL(string: "TEL://0123456789")! as NSURL
                    var phone = ""
                    for c in rider.phone {
                        if c.isNumber {
                            phone += String(c)
                        }
                    }
                    let url:NSURL = URL(string: "TEL://\(phone)")! as NSURL
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
                else {
                    self.presentMessageCompose(rider: rider, way: way)
                }
            }
        }
    }

    var body: some View {
        VStack {
            if SignedInRiders.instance.list.count > 0 {
                Button("Clear Ride Sheet") {
                    confirmClean = true
                }
                .alert(isPresented:$confirmClean) {
                    Alert(
                        title: Text("Are you sure you want to clear this ride sheet?"),
                        message: Text("There are \(SignedInRiders.instance.selectedCount()) selected riders"),
                        primaryButton: .destructive(Text("Clear")) {
                            SignedInRiders.instance.clearData()
                            //activeSheet = .templates
                        },
                        secondaryButton: .cancel()
                    )
                }
                .font(.title2).font(.callout).foregroundColor(.blue)
            }

            Button("Select Ride Template") {
                if SignedInRiders.instance.list.count > 0 {
                    confirmClean = true
                }
                else {
                    activeSheet = .templates
                }
            }
            .font(.title2).font(.callout).foregroundColor(.blue)
            
            RidersView(activeSheet: $activeSheet, scrollToRiderName: $scrollToRiderName)
            
            HStack {
                Spacer()
                Button(action: {
                    activeSheet = .addRider
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .foregroundColor(.purple)
                            .frame(width: 30, height: 30)
                        Text("Add Rider")
                    }
                }
                Spacer()
                Button(action: {
                    activeSheet = .addGuest
                    
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .foregroundColor(.purple)
                            .frame(width: 30, height: 30)
                        Text("Add Guest")
                    }
                }
                Spacer()
            }
            if signedInRiders.selectedCount() > 0 {
                Button(action: {
                    activeSheet = .email
                }, label: {
                    Text("Email Sign Up Sheet")
                })
                .font(.title2).font(.callout).foregroundColor(.blue)
                Text("Signed up \(SignedInRiders.instance.selectedCount()) riders").font(.footnote)
            }
            if let msg = messages.message {
                Text(msg).font(.footnote)
            }
            if let errMsg = messages.errMessage {
                Text(errMsg).font(.footnote).foregroundColor(Color.red)
            }
            Text(version()).font(.footnote).foregroundColor(Color .gray)
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .templates:
                SelectRideTemplateView()
            case .addRider:
                AddRiderView(addRider: self.addRider(rider:clubMember:))
            case .addGuest:
                AddGuestView(addRider: self.addRider(rider:clubMember:))
            case .email:
                let msg = SignedInRiders.instance.getHTMLContent()
                SendMailView(isShowing: $emailShowing, result: $result,
                             messageRecipient:"stats@westernwheelers.org",
                             messageSubject: "Western Wheelers Ride Sign Up Sheet",
                             messageContent: msg)
            case .showDetail:
                RiderDetailView(rider: riderForDetail!, prepareText: self.riderCommunicate(rider:way:))
            }
        }
        .onAppear() {
//            if signedInRiders.list.count == 0 {
//                activeSheet = .templates
//            }
            GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
        }
    }
}



//struct MessageView: View {
//    @Environment(\.scenePhase) var scenePhase
//
//    private let messageComposeDelegate = MessageComposerDelegate()
//
//    var body: some View {
//        VStack {
//            Text("MESSAE VIEW")
//        }
//        .onAppear() {
//            print("ON APPEAR ...........................")
//            self.presentMessageCompose()
//        }
//    }
//}

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        TabView {
            CurrentRideView()
            .tabItem {
                Label("Ride", systemImage: "bicycle.circle.fill")
            }
            MembersView()
            .tabItem {
                Label("Members", systemImage: "person.3.fill")
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
          switch newScenePhase {
          case .active:
            break
          case .inactive:
            SignedInRiders.instance.save()
         case .background:
            SignedInRiders.instance.save()
          @unknown default:
            break
          }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
