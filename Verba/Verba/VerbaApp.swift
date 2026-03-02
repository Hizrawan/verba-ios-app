//
//  VerbaApp.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI
import SwiftData

@main
struct VerbaApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var showSplash = true
    var body: some Scene {
        WindowGroup {
                    ZStack {
                        ContentView()

                        if showSplash {
                            SplashScreenView()
                                .transition(.opacity)
                                .zIndex(1)
                        }
                    }
                    .modelContainer(sharedModelContainer)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
                }
    }
}
