import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

//TODO Before ride submission is there a way to enter actual miles, climb and leader average speed and include that data in the notes.
//Can a template be added for a non-recurring ride which asks for the posted ride name, ride rating, mileage, distance and climb?

struct RideInfoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State var signedInRiders:SignedInRiders
    @State var title: String = ""
    @State var miles: String = ""
    @State var climbed: String = ""
    @State var avgSpeed: String = ""

    var body: some View {
        VStack {
            Spacer()
            Text("Ride Data").font(.title).foregroundColor(Color.blue)
            Text("Provide ride data for club statistics")
            .font(.footnote).padding()
            .multilineTextAlignment(.center)
            
            HStack {
                Text("Title")
                TextField("", text: $title).frame(width: 150)
            }
            HStack {
                Text("Miles")
                TextField("miles", text: $miles).frame(width: 150)
            }
            HStack {
                Text("Climbed")
                TextField("feet", text: $climbed).frame(width: 150)
            }
            HStack {
                Text("Average Speed")
                TextField("mph", text: $avgSpeed).frame(width: 150)
            }

            Button(action: {
                signedInRiders.rideData.title = title
                signedInRiders.rideData.totalMiles = miles
                signedInRiders.rideData.totalClimb = climbed
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

        }
        .border(Color.blue)
        .padding()
        .scaledToFit()
        .onAppear() {
            title = signedInRiders.rideData.title ?? ""
            miles = signedInRiders.rideData.totalMiles ?? ""
            climbed = signedInRiders.rideData.totalClimb ?? ""
        }
    }
}
