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
                Image(systemName: (self.rider.isSelected ? "checkmark.square" : "square"))
                .onTapGesture {
                    self.selectedAction()
                }
                Button(rider.name, action: {
                    self.selectedAction()
                })
                Spacer()
                Text(self.rider.cellPhone)
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

func addSelectedRider(name: String) {
    if let addedRider = ClubRiders.shared.get(name: name) {
        let newRider = Rider(rider: addedRider)
        SignedInRiders.instance.add(rider: newRider)
        SignedInRiders.instance.setSelected(name: newRider.name)
    }
}

struct RidersView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    @ObservedObject var clubMembers = ClubRiders.shared
    @State private var selectedRider = ""
    @State var enteredNameStr: String = ""
    @State var pickedName: String = "" //nil means the .onChange is never called but idea why ...
    @State var scrollToRiderName:String? = nil
    @State var showPicker = false
    @State var changeCount = 0
    
    var body: some View {
        VStack {
            let enteredName = Binding<String>(get: {
                self.enteredNameStr
            }, set: {
                self.enteredNameStr = $0.lowercased()
                clubMembers.filter(name: $0)
            })
//            var pickedNameBinding = Binding<String>(get: {
//                print("  BINDING GET:", self.pickedName, setCount)
//                return self.pickedName
//            }, set: {
//                self.pickedName = $0
//                print("  BINDING SET:", self.pickedName, setCount)
//                setCount += 1
//            })

            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(signedInRiders.list, id: \.self.name) { rider in
                            RiderRow(rider: rider, ident: rider.name, isSelected: rider.isSelected,
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
                    .padding()
                    .onChange(of: scrollToRiderName) { target in
                        if let rider = scrollToRiderName {
                            withAnimation {
                                proxy.scrollTo(rider)
                            }
                        }
                    }
                }
            }
            .border(Color.blue)
            .padding()
            
            HStack {
                //TextField("Search rider name", text: enteredName).multilineTextAlignment(.center)
                TextField("Enter rider name", text: enteredName, onEditingChanged: { (editingChanged) in
//                    if editingChanged {
//                        print("TextField focused")
//                        clubMembers.filter(name: "")
//                        self.showPicker = true
//
//                    } else {
//                        //print("TextField focus removed")
//                        self.showPicker = false
//                    }
                })
                .onTapGesture {
                    print("TextField focused")
                    clubMembers.filter(name: "")
                    self.showPicker = true
                }
                .multilineTextAlignment(.center)
                if self.showPicker {
//                    Button(action: {
//                        if let added = clubMembers.get(name: self.enteredNameStr) {
//                            signedInRiders.add(rider: added)
//                            self.addedRiderName = added.name
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                            self.enteredNameStr = ""
//                        }
//                    }, label: {
//                        Text("Add")
//                    })
                    Spacer()
                    Button(action: {
                        self.enteredNameStr = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        self.showPicker = false
                    }, label: {
                        Text("Cancel")
                    })
                    Spacer()
                }
            }
            
            if self.showPicker {
                Picker("", selection: $pickedName) {
                    //Text("").tag("")
                    ForEach(clubMembers.clubList, id: \.self) { rider in
                        if rider.isSelected {
                            Text(rider.name).tag(rider.name)
                        }
                    }
                }
                .onTapGesture {
                    //.onChange not triggered if user just clicks on the initially (the first) selected row
                    //order of calls is 1) .onTap 2) .onChange for rows > 1
                    //onTap is called before the pickers selection binding is set
                    //gotta be a better way - but the code below queues up the tap selection and only adds it if .onChange was not called
                    print("tapped picked:")
                    if let firstSel = clubMembers.getFirstSelected() {
                        print("queue tapped :", firstSel.name)
                        DispatchQueue.global().async {
                            sleep(1)
                            //pickedName = firstSel.name
                            if changeCount == 0 {
                                DispatchQueue.main.async {
                                    addSelectedRider(name: firstSel.name)
                                    self.scrollToRiderName = firstSel.name
                                    self.enteredNameStr = ""
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    self.showPicker = false
                                    self.pickedName = ""
                                }
                            }
                        }
                    }
                }
                .onChange(of:pickedName, perform: { pickedName in
                    print("Value Changed!", pickedName, changeCount)
                    addSelectedRider(name: pickedName)
                    self.scrollToRiderName = pickedName
                    self.enteredNameStr = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    self.showPicker = false
                    changeCount += 1
                    self.pickedName = ""
                })
                .onAppear() {
                    print("OnAppear")
                    changeCount = 0
                }

                //.pickerStyle(MenuPickerStyle())
                //.pickerStyle(InlinePickerStyle())
                //.pickerStyle(WheelPickerStyle())
                //.pickerStyle(SegmentedPickerStyle())
                //.frame(width: geometry.size.width/3, height: 100, alignment: .center)
                .clipped()
                .border(Color.blue)
                //.frame(width: 50)
            }
        }
    }
}

enum ActiveSheet: Identifiable {
    case templates, email
    var id: Int {
        hashValue
    }
}

struct CurrentRideView: View {
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State private var confirmShowing = false
    @State var activeSheet: ActiveSheet?
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @ObservedObject var signedInRiders = SignedInRiders.instance

    var body: some View {
        VStack {
            Spacer()
            Button("Select Ride Template") {
                activeSheet = .templates
            }
            Spacer()
            RidersView()
            Spacer()
            Button(action: {
                activeSheet = .email
            }, label: {
                Text("Email Sign Up Sheet")
            })
            Spacer()
            Text("Signed up rider count:\(SignedInRiders.instance.selectedCount())").font(.footnote)
//            HStack {
//                Spacer()
//                Button("sign out") {
//                    GIDSignIn.sharedInstance()?.signOut()
//                }
//                Spacer()
//            }
            Spacer()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .templates:
                SelectRideTemplateView()
            case .email:
                SendMailView(isShowing: $emailShowing, result: $result)
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
