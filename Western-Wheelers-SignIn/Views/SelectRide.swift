import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct SelectRide : View {
    @ObservedObject var rides = ClubRides.instance
    @Environment(\.presentationMode) private var presentationMode
    var addRide : (ClubRide) -> Void

    var body: some View {
        VStack {
            if rides.list.count == 0 {
                Text("Sorry, no rides were loaded yet. Try - \n1) cancel and wait another a minute \n2) ensure you have internet connectivity \n3) close and restart the app" ).font(.body).foregroundColor(Color.black)
            }
            else {
                Text("Select Ride").font(.title2).foregroundColor(Color.blue)
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack {
                            ForEach(rides.list, id: \.self.id) { ride in
                                HStack {
                                    VStack {
                                    Button(action: {
                                        self.addRide(ride)
                                        self.presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Text(ride.name)
                                    })
                                    Text(ride.dateDisplay())
                                    }
                                    //.padding()
                                    
                                }
                                Text("")
                            }
                        }
                    }
                }
                .border(Color.black)
                .padding()
            }
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            Spacer()
        }
     }
}

