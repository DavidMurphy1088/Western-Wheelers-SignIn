import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct RiderDetailView: View {
    @ObservedObject var rider:Rider
    var prepareText : (Rider, CommunicationType) -> Void
    @Environment(\.presentationMode) private var presentationMode

    @ObservedObject var signedInRiders = SignedInRiders.instance
    
    var body: some View {
        VStack {
            Text("\(self.rider.getDisplayName())").font(.title).foregroundColor(Color.blue)
            Text("")
            VStack {
                if rider.phone.count > 0 {
                    Text("Cell Phone: \(rider.phone)")
                }
                if rider.emergencyPhone.count > 0 {
                    Text("Emergency: \(rider.emergencyPhone)")
                }
                if rider.email.count > 0 {
                    Text("Email: \(rider.email)")
                }
            }
            Text("")
            VStack {
                HStack {
                    Text("Ride Leader")
                    Image(systemName: (self.rider.isLeader ? "checkmark.square" : "square"))
                        .onTapGesture {
                            signedInRiders.setLeader(rider:rider, way:!rider.isLeader)
                        }
                }
                Text("")
                HStack {
                    Text("Ride Co-Leader")
                    Image(systemName: (self.rider.isCoLeader ? "checkmark.square" : "square"))
                        .onTapGesture {
                            signedInRiders.setCoLeader(rider:rider, way:!rider.isCoLeader)
                        }
                }
            }
            VStack {
                if !rider.phone.isEmpty {
                    Text("")
                    Button(action: {
                        prepareText(rider, CommunicationType .text)
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Text Rider")
                    })
                }
                if !rider.phone.isEmpty {
                    Text("")
                    Button(action: {
                        prepareText(rider, CommunicationType .phone)
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Phone Rider")
                    })
                }
                if !rider.email.isEmpty {
                    Text("")
                    Button(action: {
                        prepareText(rider, CommunicationType .email)
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("EMail Rider")
                    })
                }

                Text("")
                Text("")
                Text("")
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Ok")
                        .font(.title2)
                })
                Text("")
            }
        }
    }
}
