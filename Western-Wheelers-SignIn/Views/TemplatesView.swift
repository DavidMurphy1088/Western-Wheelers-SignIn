import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

enum ActiveTemplateSheet: Identifiable {
    case editTemplate
    var id: Int {
        hashValue
    }
}

var templateToEdit:String? //TODO this should be part of view

struct TemplatesView: View {
    @ObservedObject var templates = RideTemplates.instance
    @State var activeSheet: ActiveTemplateSheet?
    @State var confirmDel:Bool = false

    func saveTemplate (template:RideTemplate) {
        if !template.name.isEmpty {
            templates.save(saveTemplate: template)
        }
    }
    
    func editTemplate() -> RideTemplate {
        if let templateForDetail = templateToEdit {
            if let templateForDetail = templates.get(name: templateForDetail) {
                return templateForDetail
            }
        }
        return RideTemplate(name: "", notes: "", riders: [])
    }

    var body: some View {
        VStack {
            Spacer()
            Text("Ride Templates").font(.title2).font(.callout).foregroundColor(.blue)

            ScrollView {
                ForEach(templates.list, id: \.self) { template in
                    HStack {
                        Text(" ")
                        Button(template.name, action: {
                            templateToEdit = template.name
                            activeSheet = ActiveTemplateSheet.editTemplate
                        })
                        Spacer()
                        Text("\(template.list.count) riders")
                        Text("   ")
                        Button(action: {
                            confirmDel = true
                        }, label: {
                            Image(systemName: ("minus.circle")).foregroundColor(.purple)
                        })
                        .alert(isPresented:$confirmDel) {
                            Alert(
                                title: Text("Are you sure you want to delete this template?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    templates.delete(name: template.name)
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        Text(" ")
                    }
                    Text("")
                }
            }
            .border(Color.gray)
            .padding()
            Spacer()
            Button(action: {
                templateToEdit = nil
                activeSheet = ActiveTemplateSheet.editTemplate
            }, label: {
                Text("New Ride Template")
            })
            Spacer()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .editTemplate:
                TemplateEditView(template: self.editTemplate(), saveTemplate: saveTemplate(template:))
            }
        }
    }
    
}
