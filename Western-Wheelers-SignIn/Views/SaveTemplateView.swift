import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct SaveTemplateView: View {
    var saveTemplate : (String, String) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State var name: String = ""
    @State var notes: String = ""
    
    var body: some View {
        VStack {
            //Text("\(self.rider.getDisplayName())").font(.title).foregroundColor(Color.blue)
            VStack {
                Text("")
                Text("Template Name:")
                TextField("name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    //.frame(maxWidth: maxText)
                    //.keyboardType(.numberPad)
                    //.border(Color.black)
                    .padding()
                Text("Notes:")
                TextField("notes", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 200)
                    //.border(Color.gray)
                    //.keyboardType(.numberPad)
                    .padding()
                    
                HStack {
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                        saveTemplate(name, notes)
                    }, label: {
                        Text("Ok")
                            //.font(.title2)
                    })
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                            //.font(.title2)
                    })
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
