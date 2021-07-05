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
    //date in email
    init(rider: Rider, ident:String, isSelected: Bool, selectedAction: @escaping () -> Void, deletedAction: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.rider = rider
        self.isSelected = isSelected
        self.selectedAction = selectedAction
        self.deletedAction = deletedAction
        self.ident = ident
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
                Spacer()
                Text(self.rider.phone)
                Image(systemName: ("minus.circle")).foregroundColor(.purple)
                .onTapGesture {
                    self.deletedAction()
                }
                Text(" ")
            }
            Text("")
        }
        //.padding()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .foregroundColor(isSelected ? .blue : .black)
        .id(self.ident)
    }
}

struct SelectRider: View {
    @Binding var scrollToRiderName:String

    @Environment(\.presentationMode) private var presentationMode
    @State var scrollToRider:String?
    @State var pickedName: String = "" //nil means the .onChange is never called but idea why ...
    @State var enteredNameStr: String = ""
    @State var changeCount = 0
    @ObservedObject var clubMembers = ClubRiders.shared
    
    func addRider(_ rider:String) {
        if let addedRider = ClubRiders.shared.get(name: rider) {
            let newRider = Rider(rider: addedRider)
            SignedInRiders.instance.add(rider: newRider)
            SignedInRiders.instance.setSelected(name: newRider.name)
            self.scrollToRiderName = rider
            changeCount += 1
            clubMembers.clearSelected()
        }
        self.presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        VStack {
            Text("Add a Rider").font(.title2).foregroundColor(Color.blue)
            
            let enteredName = Binding<String>(get: {
                self.enteredNameStr
            }, set: {
                self.enteredNameStr = $0.lowercased()
                clubMembers.filter(name: $0)
            })
            HStack {
                Spacer()
                Image(systemName: "magnifyingglass")
                //Image(systemName: "plus.circle")
                Spacer()
                TextField("Enter rider name", text: enteredName)
                //.multilineTextAlignment(.center)
                .font(.title2).foregroundColor(Color.black)
                Spacer()
            }
            
            Picker("", selection: $pickedName) {
                ForEach(clubMembers.clubList, id: \.self) { rider in
                    if rider.selected() {
                        Text(rider.name).tag(rider.name)
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
            .labelsHidden()
            .padding()
            .border(Color.blue)
            .onTapGesture {
                //.onChange not triggered if user just clicks on the initially (the first) selected row
                //order of calls is 1) .onTap 2) .onChange for rows > 1
                //onTap is called before the pickers selection binding is set
                //gotta be a better way - but the code below queues up the tap selection and only adds it if .onChange was not called
                if let firstSel = clubMembers.getFirstSelected() {
                    DispatchQueue.global().async {
                        sleep(1)
                        if changeCount == 0 {
                            DispatchQueue.main.async {
                                addRider(firstSel.name)
                            }
                        }
                    }
                }
            }
            .onChange(of:pickedName, perform: { pickedName in
                addRider(pickedName)
            })
            .onAppear() {
                changeCount = 0
                clubMembers.clearSelected()
                self.enteredNameStr = ""
                self.pickedName = ""
            }

            Spacer()
            Button(action: {
                self.enteredNameStr = ""
                clubMembers.clearSelected()
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            Spacer()
        }

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
                    //.padding()
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
    case templates, selectRider, email
    var id: Int {
        hashValue
    }
}

struct CurrentRideView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    @ObservedObject var messages = Messages.instance
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State private var confirmShowing = false
    @State var activeSheet: ActiveSheet?
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var scrollToRiderName:String = ""
    @State var confirmClean:Bool = false

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
            Image(systemName: "plus.circle")
            .resizable()
            .foregroundColor(.purple)
            .frame(width: 30, height: 30)
            .onTapGesture {
                activeSheet = .selectRider
            }
            Button(action: {
                activeSheet = .email
            }, label: {
                Text("Email Sign Up Sheet")
            })
            .font(.title2).font(.callout).foregroundColor(.blue)
            Text("Signed up \(SignedInRiders.instance.selectedCount()) riders").font(.footnote)
            if let msg = messages.message {
                Text(msg).font(.footnote)
            }
            if let errMsg = messages.errMessage {
                Text(errMsg).font(.footnote).foregroundColor(Color.red)
            }

        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .templates:
                SelectRideTemplateView()
            case .selectRider:
                SelectRider(scrollToRiderName: $scrollToRiderName)
            case .email:
                let msg = SignedInRiders.instance.getHTMLContent()
                SendMailView(isShowing: $emailShowing, result: $result,
                             messageRecipient:"",
                             messageSubject: "Western Wheelers Ride Sign Up Sheet",
                             messageContent: msg)
            }
        }
        .onAppear() {
            if signedInRiders.list.count == 0 {
                activeSheet = .templates
            }
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
