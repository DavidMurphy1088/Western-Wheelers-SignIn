//
//  Western_Wheelers_SignInApp.swift
//  Western-Wheelers-SignIn
//
//  Created by David Murphy on 6/20/21.
//

import SwiftUI

@main
struct Western_Wheelers_SignInApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
