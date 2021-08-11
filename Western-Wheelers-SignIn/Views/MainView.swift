import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

var riderForDetail:Rider? = nil //cannot get binding approach to work :(

struct RiderView: View {
    var selectRider : ((Rider) -> Void)!
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
                Text(" ")

                Button(rider.getDisplayName(), action: {
                    riderForDetail = self.rider
                    if selectRider != nil {
                        selectRider(rider)
                    }
                })
                if rider.isHilighted {
                    //Image(systemName: ("arrow.left"))
                    Text("added").font(.footnote).foregroundColor(.gray)
                }
                Spacer()
                if self.rider.isLeader {
                    Text("Leader").italic()
                }
                else {
                    if self.rider.isCoLeader {
                        Text("Co-leader").italic()
                    }
                }
                Image(systemName: ("minus.circle")).foregroundColor(.purple)
                    .onTapGesture {
                        self.deletedAction()
                    }
                Text(" ")
            }
            Text("")
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .id(self.rider.id) 
    }
}

struct RidersView: View {
    var selectRider : ((Rider) -> Void)!
    @ObservedObject var riderList:RiderList
    @Binding var scrollToRiderId:String
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(riderList.list, id: \.self.id) { rider in
                            RiderView(selectRider: selectRider, rider: rider,
                                 selectedAction: {
                                     DispatchQueue.main.async {
                                         riderList.toggleSelected(id: rider.id)
                                     }
                                 },
                                 deletedAction: {
                                    DispatchQueue.main.async {
                                        riderList.remove(id: rider.id)
                                    }
                                 }
                            )
                        }
                    }
                    .onChange(of: scrollToRiderId) { target in
                        if scrollToRiderId != "" {
                            withAnimation {
                                proxy.scrollTo(scrollToRiderId)
                            }
                        }
                    }
                }
            }
            
            .border(Color.black)
            .padding()
        }
     }
}

enum ActiveSheet: Identifiable {
    case selectTemplate, selectRide, addRider, addGuest, email, riderDetail, rideInfoEdit
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

    private func presentMessageCompose(riders:[Rider], way:CommunicationType) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if way == CommunicationType.text {
            let composeVC = MFMessageComposeViewController()
            var recips:[String] = []
            for rider in riders {
                if rider.isSelected && !rider.phone.isEmpty {
                    recips.append(rider.phone)
                }
            }
            composeVC.recipients = recips
            composeVC.messageComposeDelegate = messageComposeDelegate
            vc?.present(composeVC, animated: true)
        }
        if way == CommunicationType.email {
            let mailVC = MFMailComposeViewController()
            mailVC.setToRecipients([riders[0].email])
            mailVC.mailComposeDelegate = mailComposeDelegate
            vc?.present(mailVC, animated: true)
        }
    }
}

struct CurrentRideView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    var rideTemplates = RideTemplates.instance
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State var emailResult: Result<MFMailComposeResult, Error>? = nil
    @State var scrollToRiderId:String = ""
    @State var confirmClean:Bool = false
    @State var emailConfirmed:Bool = false
    @State var activeSheet: ActiveSheet?
    private let messageComposeDelegate = MessageComposerDelegate()
    private let mailComposeDelegate = MailComposerDelegate()

    @ObservedObject var messages = Messages.instance
    @Environment(\.openURL) var openURL

    func addRide(ride:ClubRide) {
        signedInRiders.setRide(ride: ride)
    }
    
    func loadTemplate(name:String) {
        rideTemplates.load(name: name, signedIn: signedInRiders)
    }
    
    func selectRider(_: Rider) {
        activeSheet = ActiveSheet.riderDetail
    }

    func addRider(rider:Rider, clubMember: Bool) {
        rider.setSelected(true)
        if ClubMembers.instance.getByName(displayName: rider.getDisplayName()) != nil {
            rider.inDirectory = true
        }
        SignedInRiders.instance.add(rider: rider)
        SignedInRiders.instance.setSelected(id: rider.id)
        SignedInRiders.instance.setHilighted(id: rider.id)
        self.scrollToRiderId = rider.id
        ClubMembers.instance.clearSelected()
    }
    
    func version() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let bld = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let info = "Version \(version) build \(bld)"
        return info
    }
    
    func riderCommunicate(riders:[Rider], way:CommunicationType) {
        DispatchQueue.global(qos: .userInitiated).async {
            //only way to get this to work. i.e. wait for detail view to be shut down fully before text ui is displayed
            usleep(500000)
            DispatchQueue.main.async {
                if way == CommunicationType.phone {
                    //let url:NSURL = URL(string: "TEL://0123456789")! as NSURL
                    var phone = ""
                    for c in riders[0].phone {
                        if c.isNumber {
                            phone += String(c)
                        }
                    }
                    let url:NSURL = URL(string: "TEL://\(phone)")! as NSURL
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
                else {
                    self.presentMessageCompose(riders: riders, way: way)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            VStack{
                Text("")
                if signedInRiders.rideData.ride == nil {
                    Button("Select A Ride") {
                        activeSheet = .selectRide
                    }
                }
                else {
                    Button("Select Ride Template") {
                        activeSheet = .selectTemplate
                    }
                    .alert(isPresented:$confirmClean) {
                        Alert(
                            title: Text("Are you sure you want to clear this ride sheet?"),
                            message: Text("There are \(SignedInRiders.instance.selectedCount()) selected riders"),
                            primaryButton: .destructive(Text("Clear")) {
                                SignedInRiders.instance.clearData()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    if SignedInRiders.instance.getCount() > 0 && SignedInRiders.instance.selectedCount() < SignedInRiders.instance.getCount() {
                        Button("Remove Unselected Riders") {
                            SignedInRiders.instance.removeUnselected()
                        }
                    }
                    Button("Clear Ride Sheet") {
                        confirmClean = true
                    }
                    
                    RidersView(selectRider: selectRider, riderList: SignedInRiders.instance, scrollToRiderId: $scrollToRiderId)
                    
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                activeSheet = .addRider
                            }) {
                                HStack {
                                    Text("Add Rider")
                                }
                            }
                            .frame(alignment: .leading)
                            //Spacer()
                            Button(action: {
                                activeSheet = .addGuest
                            }) {
                                HStack {
                                    Text("Add Guest")
                                }
                            }
                            .frame(alignment: .leading)
                            Button(action: {
                                activeSheet = .rideInfoEdit
                            }, label: {
                                Text("Ride Info")
                            })
                        }
                        Spacer()
                        VStack {
                            Button(action: {
                                activeSheet = .email
                            }, label: {
                                Text("Email Ride Sheet")
                            })
                            .disabled(signedInRiders.selectedCount() == 0)
                            .alert(isPresented: $emailConfirmed) { () -> Alert in
                                Alert(title: Text("Signup sheet sent for \(SignedInRiders.instance.selectedCount()) riders."))
                            }
                            Button(action: {
                                riderCommunicate(riders: signedInRiders.getList(), way: CommunicationType.text)
                            }, label: {
                                Text("Text All Riders")
                            })

                        }
                        Spacer()
                    }
                }
            }
            Text("")
            Text("Signed up \(SignedInRiders.instance.selectedCount()) riders").font(.footnote)
            if let msg = messages.message {
                Text(msg).font(.footnote)
            }
            if let errMsg = messages.errMessage {
                Text(errMsg).font(.footnote).foregroundColor(Color.red)
            }
            HStack {
                Text(version())
//                Button(action: {
                //                    VerifiedMember.instance.signOut()
                //                }, label: {
                //                    Text("Sign Out") //TODO keep?
                //                })
            }
            .font(.footnote).foregroundColor(Color .gray)
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .selectTemplate:
                //SelectDriveTemplateView()
                SelectTemplateView(loadTemplate: self.loadTemplate(name:))
            case .selectRide:
                SelectRide( addRide: self.addRide(ride:)) 
            case .addRider:
                AddRiderView(addRider: self.addRider(rider:clubMember:))
            case .addGuest:
                AddGuestView(addRider: self.addRider(rider:clubMember:))
            case .email:
                let msg = SignedInRiders.instance.getHTMLContent(version: version())
                SendMailView(isShowing: $emailShowing, result: $emailResult,
                             messageRecipient:"stats@westernwheelers.org",
                             messageSubject: "Western Wheelers Ride Sign Up Sheet",
                             messageContent: msg)
            case .riderDetail:
                RiderDetailView(rider: riderForDetail!, prepareText: self.riderCommunicate(riders:way:))
            case .rideInfoEdit:
                RideInfoView(signedInRiders: signedInRiders)
            
            }
        }
        .onAppear() {
            GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
        }
        .onChange(of: emailResult.debugDescription) {result in
            if result.contains("success") {
                self.emailConfirmed = true
            }
        }
    }
}

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var verifiedMember:VerifiedMember = VerifiedMember.instance

    var body: some View {
        if verifiedMember.username != nil {
            TabView {
                CurrentRideView()
                .tabItem {
                    Label("Ride", systemImage: "bicycle.circle.fill")
                }
                TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet.rectangle")
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
                VerifiedMember.instance.save()
                SignedInRiders.instance.save()
              case .background:
                VerifiedMember.instance.save()
                SignedInRiders.instance.save()
              @unknown default:
                break
              }
            }
        }
        else {
            SignInView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
