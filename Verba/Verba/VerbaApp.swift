//
//  VerbaApp.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//
import SwiftUI
import FirebaseCore

@main
struct VerbaApp: App {
    @StateObject private var viewModel = CourseListViewModel()
    @StateObject private var session = SessionManager()
    @State private var showSplash = true
    
    
    init() {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(viewModel: viewModel, session: session)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
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
