//
//  HomeScreenView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI
import AVKit

struct HomeScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme.backgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            VStack {
                Text("[name of the app]")
                    .foregroundStyle(colorScheme.textColor)
                    .font(.largeTitle)
                    .bold()
                Spacer()
                HStack(spacing: 30) {
                    Image(systemName: "airpodsmax")
                        .resizable()
                        .foregroundStyle(colorScheme.textColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Image(systemName: "airpods.gen3") // check spatial audio compatiblity
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
                Text("For a better audio experience, connect this device to a Spatial Audio compatible device like AirPods.")
                    .foregroundStyle(colorScheme.textColor)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                
                AirPlayButton()
                    .scaledToFit()
                    .blendMode(.screen)
                    .frame(width: 50)
                
                Spacer()
                Button {
                    withAnimation {
                        NavigationModel.shared.currentStep = .levelsView
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colorScheme.textColor, style: StrokeStyle(lineWidth: 3))
                            .foregroundStyle(colorScheme.backgroundColor)
                            //.stroke(colorScheme.textColor, style: StrokeStyle(lineWidth: 3))
                            //.fill(colorScheme.backgroundColor)
                        Text("Start")
                            .foregroundStyle(colorScheme.textColor)
                            .bold()
                    }
                }
                .padding()
                .frame(width: 200, height: 100)
            }
        }
    }
}

#Preview {
    HomeScreenView()
}
