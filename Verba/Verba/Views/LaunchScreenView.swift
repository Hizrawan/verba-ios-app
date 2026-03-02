//
//  SwiftUIView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            Image("SplashIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}
