import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct AddRiderView: View {
    @Binding var scrollToRiderName:String
    var addRider : (Rider, Bool) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var clubMembers = ClubRiders.instance
    
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
                //Spacer()
                TextField("Enter club rider name", text: enteredName)
                    .frame(minWidth: 0, maxWidth: 250)  //, minHeight: 0, maxHeight: 200)
                    .simultaneousGesture(TapGesture().onEnded {
                    })
                //.multilineTextAlignment(.center)
                .font(.title2).foregroundColor(Color.black)
                Spacer()
            }
            
            Picker("", selection: $pickedName) {
                ForEach(clubMembers.clubList, id: \.self) { rider in
                    if rider.selected() {
                        Text(rider.name).tag(rider.name)
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
            .scaledToFit()
            .labelsHidden()
            .padding()
            .border(Color.blue)
            .onTapGesture {
                //.onChange not triggered if user just clicks on the initially (the first) selected row
                //order of calls is 1) .onTap 2) .onChange for rows > 1
                //onTap is called before the pickers selection binding is set
                //gotta be a better way - but the code below queues up the tap selection and only adds it if .onChange was not called
                if let firstSelected = clubMembers.getFirstSelected() {
                    DispatchQueue.global().async {
                        sleep(1)
                        if changeCount == 0 {
                            DispatchQueue.main.async {
                                addRider(Rider(rider: firstSelected), true)
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .onChange(of:pickedName, perform: { pickedName in
                changeCount += 1
                if let rider = ClubRiders.instance.get(name:pickedName) {
                    self.addRider(Rider(rider: rider), true)
                }
                self.presentationMode.wrappedValue.dismiss()

            })
            .onAppear() {
                changeCount = 0
                clubMembers.clearSelected()
                self.enteredNameStr = ""
                self.pickedName = ""
            }
        }

        Button(action: {
            self.enteredNameStr = ""
            clubMembers.clearSelected()
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })

    }
}
