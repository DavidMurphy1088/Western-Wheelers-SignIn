import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct AddGuestView: View {
    var addRider : (Rider, Bool) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State var enteredGuestNameFirst: String = ""
    @State var enteredGuestNameLast: String = ""
    @State var enteredPhone: String = ""
    @State var enteredEmergecny: String = ""

    var body: some View {
        VStack {
            Spacer()
            Text("Add a Guest Rider").font(.title2).foregroundColor(Color.blue)
            Text("Use this form to enter a guest rider\nwho is not a club member")
            .font(.footnote).padding()
            .multilineTextAlignment(.center)
            
            HStack {
                Spacer()
                Text(" First Name").multilineTextAlignment(.trailing)
                TextField("First Name", text: $enteredGuestNameFirst).frame(width: 150)
                Spacer()
            }
            HStack {
                Spacer()
                Text("  Last Name").multilineTextAlignment(.trailing)
                TextField("Last Name", text: $enteredGuestNameLast).frame(width: 150)
                Spacer()
            }
            HStack {
                Spacer()
                Text("      Phone").multilineTextAlignment(.trailing)
                TextField("Cell phone", text: $enteredPhone).frame(width: 150)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Emergency").multilineTextAlignment(.trailing)
                TextField("Emergency phone", text: $enteredEmergecny).frame(width: 150) //.multilineTextAlignment(.leading).
                Spacer()
            }
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    addRider(Rider(id: SignedInRiders.instance.getGuestId(), nameFirst: enteredGuestNameFirst, nameLast: enteredGuestNameLast, phone: enteredPhone, emrg: enteredEmergecny, email: "", isGuest:true), false)
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Add")
                })
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                Spacer()
            }
            Spacer()

        }
        .border(Color.blue)
        .padding()
        .scaledToFit()
    }
}
