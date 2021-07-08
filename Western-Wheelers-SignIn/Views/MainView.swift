import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct RiderRow: View {
    var rider: Rider
    var isSelected: Bool
    var selectedAction: () -> Void
    var deletedAction: () -> Void
    var ident: String
    @State var showDetail = false
    
    init(rider: Rider, ident:String, isSelected: Bool, selectedAction: @escaping () -> Void, deletedAction: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.rider = rider
        self.isSelected = isSelected
        self.selectedAction = selectedAction
        self.deletedAction = deletedAction
        self.ident = ident
    }
    
    func riderDetail(rider:Rider) -> String {
        var str = ""
        if let member = ClubRiders.instance.get(name: rider.name) {
            if member.phone.count > 0 {
                str += "Phone \(member.phone)"
            }
            if member.emergencyPhone.count > 0 {
                str += "\nEmergency Phone \(member.emergencyPhone)"
            }
            if member.email.count > 0 {
                str += "\nEMail \(member.email)"
            }
        }
        else {
            if rider.phone.count > 0 {
                str += "Phone \(rider.phone)"
            }
            if rider.emergencyPhone.count > 0 {
                str += "\nEmergency Phone \(rider.emergencyPhone)"
            }
            if rider.email.count > 0 {
                str += "\nEMail \(rider.email)"
            }
        }
        return str
    }

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
                .font(isSelected ? Font.headline.weight(.semibold) : Font.headline.weight(.regular))
                Spacer()
                Image(systemName: ("phone.down.circle")).foregroundColor(.purple)
                    .onTapGesture {
                        showDetail = true
                    }
                    .alert(isPresented: $showDetail) {
                        Alert(title: Text("\(self.rider.name)"),
                              message: Text(self.riderDetail(rider: self.rider)),
                              dismissButton: .default(Text("OK")))
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
        .foregroundColor(isSelected ? .black : .secondary)
        .id(self.ident)
    }
}

struct RidersView: View {
    @Binding var scrollToRiderName:String
    @ObservedObject var signedInRiders = SignedInRiders.instance
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(signedInRiders.list, id: \.self.name) { rider in
                            RiderRow(rider: rider, ident: rider.name, isSelected: rider.selected(),
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
    case templates, addRider, addGuest, email
    var id: Int {
        hashValue
    }
}

struct CurrentRideView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    @ObservedObject var messages = Messages.instance
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State private var riderDetailShowing = false
    @State private var confirmShowing = false
    @State var activeSheet: ActiveSheet?
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var scrollToRiderName:String = ""
    @State var confirmClean:Bool = false
    
    func addRider(rider:Rider, clubMember: Bool) {
        rider.setSelected(true)
        SignedInRiders.instance.add(rider: rider)
        SignedInRiders.instance.setSelected(name: rider.name)
        self.scrollToRiderName = rider.name
        ClubRiders.instance.clearSelected()
    }
    
    func version() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        var bld = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        var info = "Version \(version) build \(bld)"
        return info
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
            
            RidersView(scrollToRiderName: $scrollToRiderName)
            
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
                AddRiderView(scrollToRiderName: $scrollToRiderName, addRider: self.addRider(rider:clubMember:))
            case .addGuest:
                AddGuestView(scrollToRiderName: $scrollToRiderName, addRider: self.addRider(rider:clubMember:))
            case .email:
                let msg = SignedInRiders.instance.getHTMLContent()
                SendMailView(isShowing: $emailShowing, result: $result,
                             messageRecipient:"stats@westernwheelers.org",
                             messageSubject: "Western Wheelers Ride Sign Up Sheet",
                             messageContent: msg)
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
