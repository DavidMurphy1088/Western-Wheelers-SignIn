import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

struct MembersView: View {
    @ObservedObject var memberList = ClubMembers.instance

    var body: some View {
        VStack {
            Spacer()
            Text("Club Members").font(.title2).font(.callout).foregroundColor(.blue)

            ScrollView {
                ForEach(memberList.clubList, id: \.self) { member in
                    HStack {
                        Text(" ")
                        Text(member.name)
                        Spacer()
                        Text(member.phone)
                        Text(" ")
                    }
                }
            }
            .border(Color.blue)
            .padding()
            Spacer()
        }
    }
}
