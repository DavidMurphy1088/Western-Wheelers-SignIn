import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct RideInfoEditView: View {
    //var addRider : (Rider, Bool) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State var enteredGuestName: String = ""
    @State var enteredPhone: String = ""
    @State var enteredEmergecny: String = ""

    var body: some View {
        VStack {
            Spacer()
            Text("Ride Info").font(.title2).foregroundColor(Color.blue)
            Text("Use this form to enter a guest rider\nwho is not a club member")
            .font(.footnote).padding()
            .multilineTextAlignment(.center)
            
            HStack {
                Spacer()
                Button(action: {
                    //addRider(Rider(name: enteredGuestName, phone: enteredPhone, emrg: enteredEmergecny, email: "", isGuest:true), false)
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Ok")
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
