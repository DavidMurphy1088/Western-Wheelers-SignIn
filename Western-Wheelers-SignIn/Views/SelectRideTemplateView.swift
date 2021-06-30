import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

struct RideTemplateCell: View {
    var template: RideTemplate
    var isSelected: Bool 
    var Action: () -> Void

    init(template: RideTemplate, isSelected: Bool, action: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.template = template
        self.isSelected = isSelected  // Added this
        self.Action = action
    }

    var body: some View {
        Button(template.name, action: {
            self.Action()
        })
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .foregroundColor(isSelected ? .red : .blue)
    }
}

struct SelectRideTemplateView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State var selectionKeeper: Int?
    @ObservedObject var templates = RideTemplates.shared
    
    var body: some View {
        Spacer()
//        ForEach(0..<templates.templates.count) { i in
//            RideTemplateCell(module: templates.templates[i],
//                       isSelected: i == self.selectionKeeper,
//                       action: { self.changeSelection(index: i) })
//        }
        ForEach(templates.templates, id: \.self) { temp in
            //Text(temp.name)
            RideTemplateCell(template: temp,
                             isSelected: temp.isSelected,
                             action: {
                                templates.setSelected(name: temp.name)
                             })
        }
        Spacer()
        Button(action: {
           self.presentationMode.wrappedValue.dismiss()
        }) {
          Text("Dismiss")
        }
        Spacer()
        .onAppear() {
            //force a load if a previous load was cancelled e.g. google sign in cancelled
            RideTemplates.shared.loadTemplates()
        }
    }

}


