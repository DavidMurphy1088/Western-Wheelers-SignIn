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

    init(rider: Rider, isSelected: Bool, action: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.rider = rider
        self.isSelected = isSelected
        self.Action = action
    }

    var body: some View {
        HStack {
            Button(rider.name, action: {
                self.Action()
            })
            Image(systemName: (self.rider.isSelected ? "checkmark.square" : "square")) //.tapAction {
                //self.updateTodo(self.todoCellViewModel.getId())
            //}
            Text(self.rider.phone)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .foregroundColor(isSelected ? .red : .blue)
    }
}

struct RidersView: View {
    @ObservedObject var riders = Riders.shared
    @State private var inp: String = ""
    @State private var selectedRider = ""
    @State var enteredNameStr: String = ""
    @State var selectedNameStr: String = ""
    
    var body: some View {
        VStack {
            let enteredName = Binding<String>(get: {
                self.enteredNameStr
            }, set: {
                self.enteredNameStr = $0.lowercased()
                print("entered", self.enteredNameStr)
                riders.filter(name: $0)
            })

            ScrollView {
                ForEach(riders.list, id: \.self) { rider in
                    RiderRow(rider: rider, isSelected: rider.isSelected,
                        action: {
                            Riders.shared.setSelected(name: rider.name)
                        })
                }
            }
            TextField("Search rider name", text: enteredName).multilineTextAlignment(.center).textCase(.lowercase)
            Picker("", selection: $selectedNameStr) {
                ForEach(riders.list, id: \.self) { rider in
                    if rider.isSelected {
                        Text(rider.name).tag(rider.name)
                    }
                }
            }
            .onChange(of:selectedNameStr, perform: { value in
                    print("Value Changed!", value)
                self.enteredNameStr = value
                })
            //.pickerStyle(MenuPickerStyle())
            //.pickerStyle(InlinePickerStyle())
            //.pickerStyle(WheelPickerStyle())
            //.pickerStyle(SegmentedPickerStyle())
            //.frame(width: geometry.size.width/3, height: 100, alignment: .center)
            .clipped()
            .border(Color.green)

        }

    }
}

struct MainView: View {
    @State private var selectRideTemplateSheet = false
    
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
                    MailComposeViewController.shared.sendEmail()
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
                SelectRideView()
            }
            .tabItem {
                Label("Ride", systemImage: "list.dash")
            }
            .onAppear() {
                GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
