//
//  SplashScreenView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct SplashScreenView: View {
       
       @Namespace private var ns
       @State private var phase: Int = 0
       @State private var scale: CGFloat = 0.7
       @State private var opacity: Double = 0
       
       var body: some View {
           ZStack {
               Color.white
                   .ignoresSafeArea()
               
               ZStack {
                   
                   if phase == 0 {
                       Image("SplashIcon")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 90, height: 90)
                           .clipShape(
                               RoundedRectangle(
                                   cornerRadius: 22,
                                   style: .continuous
                               )
                           )
                           .scaleEffect(scale)
                           .opacity(opacity)
                           .matchedGeometryEffect(id: "logo", in: ns)
                   }
                   
                   if phase >= 1 {
                       HStack(spacing: 6) {
                           
                           Image("SplashIcon")
                               .resizable()
                               .scaledToFit()
                               .frame(width: 90, height: 90)
                               .clipShape(
                                   RoundedRectangle(
                                       cornerRadius: 22,
                                       style: .continuous
                                   )
                               )
                           
                           if phase >= 2 {
                               Text("Verba")
                                   .font(.system(size: 34, weight: .ultraLight))
                                   .tracking(phase >= 3 ? 0 : 8)
                                   .opacity(phase >= 2 ? 1 : 0)
                                   .animation(.easeOut(duration: 0.4), value: phase)
                           }
                       }
                       .matchedGeometryEffect(id: "logo", in: ns)
                   }
               }
           }
           .onAppear {
               startAnimation()
           }
       }
       
       private func startAnimation() {
           
           withAnimation(.easeOut(duration: 0.6)) {
               scale = 1
               opacity = 1
           }
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
               withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                   phase = 1
               }
           }
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
               withAnimation(.easeOut(duration: 0.5)) {
                   phase = 2
               }
           }
           
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
               withAnimation(.easeOut(duration: 0.4)) {
                   phase = 3
               }
           }
       }
   }

#Preview {
    SplashScreenView()
}
