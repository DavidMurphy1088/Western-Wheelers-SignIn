import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

var riderForDetail:Rider? = nil //cannot get binding approach to work :(

struct RiderView: View {
    var selectRider : ((Rider) -> Void)!
    @ObservedObject var rider: Rider
    @State var deleteNeedsConfirm:Bool
    @State var checkedAction: () -> Void
    @State var deletedAction: () -> Void
    @State var confirmDelete:Bool = false
    
    var showSelect:Bool
    
    var body: some View {
        VStack {
            HStack {
                Text(" ")
                if showSelect {
                    Image(systemName: (self.rider.selected() ? "checkmark.square" : "square"))
                    .onTapGesture {
                        self.checkedAction()
                    }
                    Text(" ")
                }

                Button(rider.getDisplayName(), action: {
                    riderForDetail = self.rider
                    if selectRider != nil {
                        selectRider(rider)
                    }
                })
                if rider.isHilighted {
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
                        if deleteNeedsConfirm {
                            self.confirmDelete = true
                        }
                        else {
                            self.deletedAction()
                        }
                    }
                    .alert(isPresented:$confirmDelete) {
                        Alert(
                            title: Text("Delete rider?"),
                            primaryButton: .destructive(Text("Delete")) {
                                //if let delName = delName {
                                    self.deletedAction()
                                //}
                            },
                            secondaryButton: .cancel()
                        )
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
    var deleteNeedsConfirm:Bool

    @Binding var scrollToRiderId:String
    var showSelect:Bool
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: true) {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(riderList.list, id: \.self.id) { rider in
                            RiderView(selectRider: selectRider, rider: rider, deleteNeedsConfirm: self.deleteNeedsConfirm,
                                      checkedAction: {
                                     DispatchQueue.main.async {
                                         riderList.toggleSelected(id: rider.id)
                                     }
                                 },
                                 deletedAction: {
                                    DispatchQueue.main.async {
                                        riderList.remove(id: rider.id)
                                    }
                                 },
                                 showSelect: showSelect
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
            .padding()
            .border(riderList.list.count == 0 ? Color.white : Color.gray)
            .padding()
        }
     }
}

enum ActiveSheet: Identifiable {
    case selectTemplate, selectRide, addRider, addGuest, emailStats, riderDetail, rideInfoEdit
    var id: Int {
        hashValue
    }
}
enum CommunicationType: Identifiable {
    case phone, text, email, waiverEmail
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
        if way == CommunicationType.email || way == CommunicationType.waiverEmail {
            let mailVC = MFMailComposeViewController()
            mailVC.setToRecipients([riders[0].email])
            mailVC.mailComposeDelegate = mailComposeDelegate
            if way == CommunicationType.waiverEmail {
                mailVC.setSubject("Western Wheelers Liability Waiver")
                mailVC.setMessageBody(self.guestWaiverDoc(), isHTML: true)
            }
            vc?.present(mailVC, animated: true)
        }
    }
}

struct CurrentRideView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    var rideTemplates = RideTemplates.instance
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State var emailResult: MFMailComposeResult? = nil
    @State var scrollToRiderId:String = ""
    @State var confirmClean:Bool = false
    @State var confirmAddTemplate:Bool = false
    @State var emailShowStatus:Bool = false
    @State var emailStatus:String?
    @State var emailWaiverRecipient:String?
    @State var activeSheet: ActiveSheet?
    @State var animateIcon = false
    @State var showInfo = false
    
    private let messageComposeDelegate = MessageComposerDelegate()
    private let mailComposeDelegate = MailComposerDelegate()

    @ObservedObject var messages = Messages.instance
    @Environment(\.openURL) var openURL

    func addRide(ride:ClubRide) {
        signedInRiders.setRide(ride: ride)
    }
    
    func loadTemplate(name:String) {
        rideTemplates.loadTemplate(name: name, signedIn: signedInRiders)
    }
    
    func selectRider(_: Rider) {
        activeSheet = ActiveSheet.riderDetail
    }

    func addRider(rider:Rider, clubMember: Bool) {
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
        
    func info() -> String {
        var info = "Thanks for using the Western Wheelers Sign-In app and I hope you find it useful. Feel free to send any suggestions or new ideas to davidp.murphy@sbcglobal.net"
        info += "\n\n\(version())"
        info += "\n\n"+Messages.instance.getMessages()
        return info
    }
    
    func guestWaiverDoc() -> String {
        var msg = "<html><body>"
        msg += "Welcome to your Western Wheelers ride today."
        msg += " \(signedInRiders.rideData.ride?.dateDisplay() ?? "")"
        msg += " Ride: \(signedInRiders.rideData.ride?.name ?? "")"

        msg += "<br><br>Please review the liability waiver below prior to starting the ride."
        msg += "<br><br>Then place your initials here ____ and reply to this email to indicate your consent to the waiver."
        msg += "<br><br>"
        if let fileURL = Bundle.main.url(forResource: "doc_waiver", withExtension: "txt") {
            if let fileContents = try? String(contentsOf: fileURL) {
                msg += fileContents
            }
        }
        msg += "</body></html>"
        return msg
    }
    
    var body: some View {
        VStack {
            VStack{
                Text("")
                if signedInRiders.rideData.ride == nil {
                    VStack {
                        Spacer()
                        Text("Western Wheelers").font(.title2)
                        Text("Ride Sign Up").font(.title2)
                        Image("Bike_Wheel")
                            .resizable()
                            .onAppear {
                                self.animateIcon.toggle()  //cause the animation to start
                            }
                            .rotationEffect(Angle(degrees: self.animateIcon ? 2160: 0)) //, anchor: UnitPoint(x: 1.0, y: 1.0))
                            .animation(Animation.linear(duration: 30).repeatForever(autoreverses: false))
                            .frame(width: 200, height: 200, alignment: .center)
                        Spacer()
                        Button("Select a Ride") {
                            activeSheet = .selectRide
                        }
                        .font(.title2)
                        Spacer()
                    }
                }
                else {
                    Text(signedInRiders.rideData.ride?.name ?? "").padding(.horizontal)
                    Text("")
                    Button("Select Ride Template") {
                        if SignedInRiders.instance.getCount() == 0 {
                            activeSheet = .selectTemplate
                        }
                        else {
                            confirmAddTemplate = true
                        }
                    }
                    .disabled(rideTemplates.list.count == 0)
                    .alert(isPresented:$confirmAddTemplate) {
                        Alert(
                            title: Text("Clear the ride sheet?"),
                            message: Text("Adding a template will clear the ride sheet. The sheet has \(SignedInRiders.instance.getCount()) riders."),
                            primaryButton: .destructive(Text("Clear")) {
                                activeSheet = .selectTemplate
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
                    .alert(isPresented:$confirmClean) {
                        Alert(
                            title: Text("Clear the ride sheet and start a new ride?"),
                            primaryButton: .destructive(Text("Clear")) {
                                signedInRiders.clearData(clearRide: true)
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    RidersView(selectRider: selectRider, riderList: SignedInRiders.instance, deleteNeedsConfirm: false, scrollToRiderId: $scrollToRiderId, showSelect: true)
                    
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
                                activeSheet = .emailStats
                            }, label: {
                                Text("Email Ride Sheet")
                            })
                            .disabled(signedInRiders.selectedCount() == 0)
                            .alert(isPresented: $emailShowStatus) { () -> Alert in
                                Alert(title: Text(emailStatus ?? ""))
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
            HStack {
                Text("Signed up \(SignedInRiders.instance.selectedCount()) riders").font(.footnote)
                Button(action: {
                    self.showInfo = true
                }) {
                    Image(systemName: "info.circle.fill").resizable().frame(width:30.0, height: 30.0)
                }
            }

            if let errMsg = messages.errMessage {
                Text(errMsg).font(.footnote).foregroundColor(Color.red)
            }
            else {
                Text("")
            }
        }
        .actionSheet(isPresented: self.$showInfo) {
            ActionSheet(
                title: Text("App Info"),
                message: Text(info()),
                buttons: [
                    .cancel {  },
                ]
            )
        }

        .sheet(item: $activeSheet) { item in
            switch item {
            case .selectTemplate:
                SelectTemplateView(loadTemplate: self.loadTemplate(name:))
            case .selectRide:
                SelectRide( addRide: self.addRide(ride:)) 
            case .addRider:
                AddRiderView(addRider: self.addRider(rider:clubMember:))
            case .addGuest:
                AddGuestView(addRider: self.addRider(rider:clubMember:))
            case .emailStats:
                let msg = SignedInRiders.instance.getHTMLContent(version: version())
                SendMailView(isShowing: $emailShowing, result: $emailResult,
                             messageRecipient:"stats@westernwheelers.org",
                             messageSubject: "Western Wheelers Ride Sign Up Sheet",
                             messageContent: msg)
            case .riderDetail:
                RiderDetailView(rider: riderForDetail!, prepareCommunicate: self.riderCommunicate(riders:way:))
            case .rideInfoEdit:
                RideInfoView(signedInRiders: signedInRiders)

            }
        }
        .onAppear() {
            GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
        }
        .onChange(of: emailResult) {result in
            self.emailShowStatus = true
            if result == MFMailComposeResult.sent {
                emailStatus = "Signup sheet sent for \(SignedInRiders.instance.selectedCount()) riders"
            }
            if result == MFMailComposeResult.cancelled {
                emailStatus = "Email cancelled"
            }
            if result == MFMailComposeResult.failed {
                emailStatus = "Email failed"
            }
            if result == MFMailComposeResult.saved {
                emailStatus = "Email saved"
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
