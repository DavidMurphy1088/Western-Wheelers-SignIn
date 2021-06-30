import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

struct MembersView: View {
    @ObservedObject var memberList = ClubRiders.shared

    var body: some View {
        VStack {
            Spacer()
            Text("Club Members").font(.title2).font(.callout).foregroundColor(.blue)

            ScrollView {
                ForEach(memberList.list, id: \.self) { member in
                    HStack {
                        Text(" ")
                        Text(member.name)
                        Spacer()
                        Text(member.cellPhone)
                        Text(" ")
                    }
                }
            }
            Spacer()
        }
    }

}
