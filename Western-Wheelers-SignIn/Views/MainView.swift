import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

//class Send : UIViewController, MFMailComposeViewControllerDelegate {
//
//    func sendMail(msg:String) {
//        if !MFMailComposeViewController.canSendMail() {
//            print("Mail services are not available")
//            return
//        }
//
//        //DispatchQueue.main.async {
//            let composeVC = MFMailComposeViewController()
//            composeVC.mailComposeDelegate = self
//
//        // Configure the fields of the interface.
//            composeVC.setToRecipients(["davidp.murphy@sbcglobal.net"])
//            composeVC.setSubject("WW Ride")
//            composeVC.setMessageBody("<p>"+msg+"</p>", isHTML: true)
//            //self.present(picker, animated: true)
//            self.present(composeVC, animated: true, completion: nil)
//        //}
//        //self.present(composeVC, animated: true, completion: nil)
//    }
//
//    private func mailComposeController(controller: MFMailComposeViewController,
//                               didFinishWithResult result: MFMailComposeResult, error: NSError?) {
//        // Check the result or perform other tasks.
//        // Dismiss the mail compose view controller.
//        controller.dismiss(animated: true, completion: nil)
//    }
//}

struct RiderRow: View {
    var rider: Rider
    var isSelected: Bool
    var Action: () -> Void
    var ident: String

    init(rider: Rider, ident:String, isSelected: Bool, action: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.rider = rider
        self.isSelected = isSelected
        self.Action = action
        self.ident = ident
    }

    var body: some View {
        HStack {
            Button(rider.name, action: {
                self.Action()
            })
            Image(systemName: (self.rider.isSelected ? "checkmark.square" : "square")) //.tapAction {
                //self.updateTodo(self.todoCellViewModel.getId())
            //}
            Text(self.rider.cellPhone)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .foregroundColor(isSelected ? .red : .blue)
        .id(self.ident)
    }
}

extension UIScrollView {
   func scrollToBottom(animated: Bool) {
     if self.contentSize.height < self.bounds.size.height { return }
     let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
     self.setContentOffset(bottomOffset, animated: animated)
  }
}

var backButton: some View {
    Button(action: {  }) {
        Text("Cancel")
    }
}

struct RidersView: View {
    @ObservedObject var signedInRiders = SignedInRiders.shared
    @ObservedObject var clubMembers = ClubRiders.shared
    @State private var inp: String = ""
    @State private var selectedRider = ""
    @State var enteredNameStr: String = ""
    @State var selectedNameStr: String = ""
    @State var addedRider:Rider? = nil
    @State var showPicker = false
    //@State private var scrollTarget: Int?

    var body: some View {
        VStack {
            let enteredName = Binding<String>(get: {
                self.enteredNameStr
            }, set: {
                self.enteredNameStr = $0.lowercased()
                //print("entered", self.enteredNameStr)
                clubMembers.filter(name: $0)
            })

            ScrollView {
                ScrollViewReader { proxy in
//                    Button("Jump to end") {
//                        //value.scrollTo(self.addedRider)
//                        value.scrollTo(self.addedRider!.name)
//                    }

//                    ForEach(0..<signedInRiders.list.count) { i in
//                        //Text("Example \(i)").id(i)
//                        RiderRow(rider: signedInRiders.list[i], ident: i, isSelected: signedInRiders.list[i].isSelected,
//                            action: {
//                                //SignedInRiders.shared.setSelected(name: rider.name)
//                            }
//                        )
//                    }
                    VStack {
                        //ForEach(signedInRiders.list, id: \.self) { rider in
                        ForEach(signedInRiders.list, id: \.self.name) { rider in
                            RiderRow(rider: rider, ident: rider.name, isSelected: rider.isSelected,
                                action: {
                                    DispatchQueue.main.async {
                                        signedInRiders.setSelected(name: rider.name)
                                    }
                                })
                        }
                    }
                    .padding()
                    .onChange(of: addedRider) { target in
                        //if let target = target {
                            //addedRider = nil
                            withAnimation {
                                //proxy.scrollTo(target, anchor: .center)
                                proxy.scrollTo(self.addedRider!.name)
                            }
                        //}
                    }
                }
            }
            //.navigationBarItems(leading: backButton, trailing: backButton)
            
            
            //TextField("Search rider name", text: enteredName).multilineTextAlignment(.center).textCase(.lowercase)
            HStack {
                Spacer()
                //TextField("Search rider name", text: enteredName).multilineTextAlignment(.center)
                TextField("Enter rider name", text: enteredName, onEditingChanged: { (editingChanged) in
                    if editingChanged {
                        //print("TextField focused")
                        clubMembers.filter(name: "")
                        self.showPicker = true
                        
                    } else {
                        //print("TextField focus removed")
                        self.showPicker = false
                    }
                })
                .multilineTextAlignment(.center)
                if self.showPicker {
                    Button(action: {
                        if let added = clubMembers.get(name: self.enteredNameStr) {
                            addedRider = added
                            print ("added id", added)
                            signedInRiders.add(rider: added)
                            //remove keyboard
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            self.enteredNameStr = ""
                        }
                        //scrollView.setContentOffset(12, animated: true)
                    }, label: {
                        Text("Add")
                    })
                    Spacer()
                    Button(action: {
                        self.enteredNameStr = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }, label: {
                        Text("Cancel")
                    })
                    Spacer()
                }
            }
            if self.showPicker {
                Picker("", selection: $selectedNameStr) {
                    ForEach(clubMembers.list, id: \.self) { rider in
                        if rider.isSelected {
                            Text(rider.name).tag(rider.name)
                        }
                    }
                }
                .onChange(of:selectedNameStr, perform: { value in
                        print("Value Changed!", value)
                    self.enteredNameStr = value
                })
                .onTapGesture {
                    //.onChange not triggered if user just clicks on the initially (the first) selected row
                    let rider = clubMembers.get(name: enteredNameStr)
                    if rider == nil {
                        if let sel = clubMembers.getFirstSelected() {
                            self.enteredNameStr = sel.name
                        }
                    }
                }
                //.pickerStyle(MenuPickerStyle())
                //.pickerStyle(InlinePickerStyle())
                //.pickerStyle(WheelPickerStyle())
                //.pickerStyle(SegmentedPickerStyle())
                //.frame(width: geometry.size.width/3, height: 100, alignment: .center)
                .clipped()
                .border(Color.blue)
                .frame(width: 50)
            }
        }
    }
}

struct RideView: View {
    @State private var selectRideTemplateSheet = false

    var body: some View {
        VStack {
            Spacer()
            Button("Select Ride Template") {
                selectRideTemplateSheet.toggle()
            }
            Spacer()
            Spacer()
            RidersView()
            Spacer()
            Spacer()
            Button(action: {
                //MailComposeViewController.shared.sendEmail()
            }, label: {
                Text("Email Sign_up Sheet")
            })
            HStack {
                Spacer()
                Button("sign out") {
                    GIDSignIn.sharedInstance()?.signOut()
                }
                Spacer()
            }
            Spacer()
        }
        .sheet(isPresented: $selectRideTemplateSheet) {
            SelectRideTemplateView()
        }
        .onAppear() {
            GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
        }
    }
}

struct MainView: View {
    
    class MailComposeViewController: UIViewController, MFMailComposeViewControllerDelegate {
        static let shared = MailComposeViewController()
        func sendEmail() {
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients(["davidp.murphy@sbcglobal.net"])

                UIApplication.shared.windows.last?.rootViewController?.present(mail, animated: true, completion: nil)
            } else {
                // Alert
            }
        }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
    var body: some View {
        TabView {
            RideView()
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
