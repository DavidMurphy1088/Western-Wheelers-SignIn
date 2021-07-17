import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct SelectScrollView : View {
    @ObservedObject var clubMembers = ClubMembers.instance
    @Environment(\.presentationMode) private var presentationMode
    var addRider : (Rider, Bool) -> Void

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(clubMembers.clubList, id: \.self.id) { rider in
                            if rider.selected() {
                                HStack {
                                    //Text(rider.name)
                                    Button(rider.getDisplayName(), action: {
                                        self.addRider(Rider(rider: rider), true)
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                }
                                Text("")
                            }
                        }
                    }
                }
            }
            .border(Color.blue)
            .padding()
        }
     }
}

struct AddRiderView: View {
    var addRider : (Rider, Bool) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var clubMembers = ClubMembers.instance
    
    @State var scrollToRider:String?
    @State var pickedName: String = "" //nil means the .onChange is never called but idea why ...
    @State var enteredNameFirstStr: String = ""
    @State var enteredNameLastStr: String = ""
    @State var changeCount = 0

    var body: some View {
        VStack {
            let enteredNameLast = Binding<String>(get: {
                self.enteredNameLastStr
            }, set: {
                self.enteredNameLastStr = $0.lowercased()
                clubMembers.filter(nameLast: enteredNameLastStr, nameFirst: enteredNameFirstStr)
            })

            let enteredNameFirst = Binding<String>(get: {
                self.enteredNameFirstStr
            }, set: {
                self.enteredNameFirstStr = $0.lowercased()
                clubMembers.filter(nameLast: enteredNameLastStr, nameFirst: enteredNameFirstStr)
            })


            Text("Add a Rider").font(.title2).foregroundColor(Color.blue)
            HStack {
                Spacer()
                Image(systemName: "magnifyingglass")
                Text("Last Name")
                TextField("name", text: enteredNameLast)
                    .frame(minWidth: 0, maxWidth: 250)  //, minHeight: 0, maxHeight: 200)
                    .simultaneousGesture(TapGesture().onEnded {
                    })
                //.font(.title2).foregroundColor(Color.black)
                Text("First Name")
                TextField("name", text: enteredNameFirst)
                    .frame(minWidth: 0, maxWidth: 250)  //, minHeight: 0, maxHeight: 200)
                    .simultaneousGesture(TapGesture().onEnded {
                    })
                //.font(.title2).foregroundColor(Color.black)
                Spacer()
            }
        }
        
        SelectScrollView(addRider: addRider)
        
        Button(action: {
            self.enteredNameFirstStr = ""
            clubMembers.clearSelected()
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })
        Spacer()
    }
}
