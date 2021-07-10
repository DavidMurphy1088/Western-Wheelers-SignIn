import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct RiderDetailView: View {
    @State var rider:Rider
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var signedInRiders = SignedInRiders.instance

    var body: some View {
        VStack {
            Text("\(self.rider.name)").font(.title2).foregroundColor(Color.blue)
            Text("")
            if rider.phone.count > 0 {
                Text("Cell Phone: \(rider.phone)")
            }
            if rider.emergencyPhone.count > 0 {
                Text("Emergency: \(rider.emergencyPhone)")
            }
            if rider.email.count > 0 {
                Text("Email: \(rider.email)")
            }
            if !rider.inDirectory {
                Text("Rider name not in member directory")
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
            Text("")
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Ok")
            })

        }
//        .onAppear(perform: {
//            self.rideLeader = self.rider.isLeader
//            self.coLeader = self.rider.isLeader
//        })
    }
}
