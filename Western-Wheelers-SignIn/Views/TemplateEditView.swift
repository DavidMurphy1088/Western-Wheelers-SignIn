import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct TemplateEditView: View {
    @State var template:RideTemplate
    var saveTemplate : (RideTemplate) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State var activeSheet: ActiveSheet?
    @State var scrollToRiderId:String = ""
    
    enum ActiveSheet: Identifiable {
        case addRider
        var id: Int {
            hashValue
        }
    }
    
    func addRider(rider:Rider, clubMember:Bool = false) {
        rider.setSelected(true)
        if ClubMembers.instance.getByName(displayName: rider.getDisplayName()) != nil {
            rider.inDirectory = true
        }
        template.add(rider: rider)
        self.scrollToRiderId = rider.id
        template.setHilighted(id: rider.id)

        ClubMembers.instance.clearSelected()
    }

    var body: some View {
        VStack {
            VStack {
                Text("")
                Text("Template Name:")
                TextField("name", text: $template.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Text("Notes:")
                TextField("notes", text: $template.notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.leading)
                    //.frame(minHeight: 100)
                    //.border(Color.gray)
                    .padding()
                
                RidersView(riderList: template, scrollToRiderId: $scrollToRiderId)

                HStack {
                    Spacer()
                    Button(action: {
                        activeSheet = ActiveSheet.addRider
                    }, label: {
                        Text("Add Rider")
                    })
                    Spacer()
                }
                Text("")
                HStack {
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                        saveTemplate(template)
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
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .addRider:
                AddRiderView(addRider: self.addRider(rider:clubMember:))
            }
        }
    }
}
