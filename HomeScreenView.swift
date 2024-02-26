//
//  HomeScreenView.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI
import AVKit

struct HomeScreenView: View {    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var NM = NavigationModel.shared
    
    let homeScreenAnimation: Namespace.ID
    var body: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme.backgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                //.matchedGeometryEffect(id: "HomeScreen", in: homeScreenAnimation, isSource: false)

            VStack {
                Text(appName)
                    .foregroundStyle(colorScheme.textColor)
                    .font(.system(size: 100))
                    .bold()
                    .padding()
                Spacer()
                HStack(spacing: 30) {
                    Image(systemName: "airpodsmax")
                        .resizable()
                        .foregroundStyle(colorScheme.textColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Image(systemName: "airpods.gen3")
                        .resizable()
                        .foregroundStyle(colorScheme.textColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Image(systemName: "airpodspro")
                        .resizable()
                        .foregroundStyle(colorScheme.textColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Image(systemName: "beats.headphones")
                        .resizable()
                        .foregroundStyle(colorScheme.textColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
                .padding()
                Text("For an enhanced audio experience, connect this device to a compatible Spatial Audio device such as AirPods. If you don't connect this device to anything make sure that silent mode is off.")
                    .foregroundStyle(colorScheme.textColor)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                
                AirPlayButton(color: colorScheme.textColor == .white ? .white : .black)
                    .scaledToFit()
                    .frame(width: 50)
                
                Spacer()
                StartButton {
                    withAnimation {
                        NavigationModel.shared.currentStep = .levelsView
                    }
                }
                .padding(.bottom)
                //.matchedGeometryEffect(id: "StartButton", in: homeScreenAnimation)
                //.animation(.spring, value: NM.currentStep)
            }
        }
    }
}
