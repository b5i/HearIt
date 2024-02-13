//
//  MusicianHeaderView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 12.02.2024.
//

import SwiftUI

struct MusicianHeaderView: View {
    let disabledFeatures: DisabledFeatures
    
    @ObservedObject var musician: Musician
    var body: some View {
        VStack {
            SpotlightColorButton(isDisabled: disabledFeatures.contains(feature: .changeSpotlightColorFeature), musician: musician)
            HStack(spacing: 10) {
                MuteButton(isDisabled: disabledFeatures.contains(feature: .soloFeature), musician: musician)
                SoloButton(isDisabled: disabledFeatures.contains(feature: .soloFeature), musician: musician)
            }
        }
    }
    
    struct SpotlightColorButton: View {
        let isDisabled: Bool
        
        @State private var shakeNumber: CGFloat = 0
        
        @ObservedObject var musician: Musician
        var body: some View {
            Button {
                if isDisabled {
                    self.shakeNumber += 2
                } else {
                    self.musician.goToNextColor()
                }
            } label: {
                Image(systemName: self.musician.status.isSpotlightOn ? "figure.wave.circle.fill" : "figure.wave.circle")
                    .resizable()
                    .sfReplaceEffect()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .animation(.spring, value: self.musician.status.isSpotlightOn)
                    .foregroundStyle(Color(cgColor: self.musician.status.spotlightColor.getCGColor()))
                    .animation(.spring, value: self.musician.status.spotlightColor)
            }
            .shake(with: shakeNumber)
        }
    }
    
    struct MuteButton: View {
        let isDisabled: Bool
        
        @State private var shakeNumber: CGFloat = 0
        
        @ObservedObject var musician: Musician
        var body: some View {
            Button {
                if isDisabled {
                    withAnimation {
                        shakeNumber += 2
                    }
                } else {
                    self.musician.sound?.isMuted.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.white)
                        .opacity(0.3)
                        .frame(width: 35, height: 35)
                    Image(systemName: self.musician.status.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .resizable()
                        .sfReplaceEffect()
                        .scaledToFit()
                        .frame(width: 20)
                        .foregroundStyle(self.musician.status.isMuted ? .red : .white)
                        .padding(5)
                }
            }
            .frame(width: 35, height: 35)
            .shake(with: shakeNumber)
        }
    }
    
    struct SoloButton: View {
        let isDisabled: Bool
        
        @State private var shakeNumber: CGFloat = 0
        
        @ObservedObject var musician: Musician
        var body: some View {
            Button {
                if isDisabled {
                    withAnimation {
                        shakeNumber += 2
                    }
                } else {
                    self.musician.sound?.isSoloed.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.white)
                        .opacity(0.3)
                        .frame(width: 35, height: 35)
                    Image(systemName: self.musician.status.isSoloed ? "s.circle.fill" : "s.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .foregroundStyle(self.musician.status.isSoloed ? .yellow : .white)
                        .padding(5)
                }
            }
            .frame(width: 35, height: 35)
            .shake(with: shakeNumber)
        }
    }
}
