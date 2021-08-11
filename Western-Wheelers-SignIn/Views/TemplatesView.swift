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

var templateForDetail:String? //TODO this should be part of view

struct TemplatesView: View {
    @ObservedObject var templates = RideTemplates.instance
    @State var activeSheet: ActiveTemplateSheet?
    @State var confirmDel:Bool = false

    func saveTemplate (template:RideTemplate) {
        templates.save(saveTemplate: template)
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
                            templateForDetail = template.name
                            activeSheet = ActiveTemplateSheet.editTemplate
                        })

                        Spacer()
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
            .border(Color.black)
            .padding()
            Spacer()
            Button(action: {
                activeSheet = ActiveTemplateSheet.editTemplate
            }, label: {
                Text("New Ride Template")
            })
            Spacer()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .editTemplate:
                //print("==-", templateForDetail)
                //Text(templateForDetail ?? "...")
                TemplateEditView(template: templates.get(name: templateForDetail!)!, saveTemplate: saveTemplate(template:))
            }
        }
    }
}
