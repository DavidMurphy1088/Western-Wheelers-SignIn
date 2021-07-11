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
                        ForEach(clubMembers.clubList, id: \.self.name) { rider in
                            if rider.selected() {
                                HStack {
                                    //Text(rider.name)
                                    Button(rider.name, action: {
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
    @State var enteredNameStr: String = ""
    @State var changeCount = 0

    var body: some View {
        VStack {
            let enteredName = Binding<String>(get: {
                self.enteredNameStr
            }, set: {
                self.enteredNameStr = $0.lowercased()
                clubMembers.filter(name: $0)
            })

            Text("Add a Rider").font(.title2).foregroundColor(Color.blue)
            
            HStack {
                Spacer()
                Image(systemName: "magnifyingglass")
                TextField("Enter club rider name", text: enteredName)
                    .frame(minWidth: 0, maxWidth: 250)  //, minHeight: 0, maxHeight: 200)
                    .simultaneousGesture(TapGesture().onEnded {
                    })
                .font(.title2).foregroundColor(Color.black)
                Spacer()
            }
        }
        
        SelectScrollView(addRider: addRider)
        
        Button(action: {
            self.enteredNameStr = ""
            clubMembers.clearSelected()
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })
        Spacer()
    }
}
