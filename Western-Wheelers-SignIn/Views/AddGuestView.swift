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
    @State var maxText: CGFloat = 200

    var body: some View {
        VStack {
            Spacer()
            Text("Add a Guest Rider").font(.title2).foregroundColor(Color.blue)
            Text("Use this form to enter a guest rider\nwho is not a club member")
            .font(.footnote).padding()
            .multilineTextAlignment(.center)
            
            HStack {
                Spacer()
                Text("First Name").multilineTextAlignment(.trailing)
                TextField("first name", text: $enteredGuestNameFirst).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Last Name").multilineTextAlignment(.trailing)
                TextField("last name", text: $enteredGuestNameLast).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Cell Phone").multilineTextAlignment(.trailing)
                TextField("cell phone", text: $enteredPhone).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Emergency").multilineTextAlignment(.trailing)
                TextField("emergency phone", text: $enteredEmergecny).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
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
