//
//  VerbaApp.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//
import SwiftUI

@main
struct VerbaApp: App {
    @StateObject private var viewModel = CourseListViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(viewModel: CourseListViewModel())

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
