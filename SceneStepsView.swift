//
//  SceneStepsView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

struct SceneStepsView: View {
    @StateObject var levelModel: LevelModel
    
    @ObservedObject var MM: MusiciansManager
    @ObservedObject var PM: PlaybackManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.cyan.opacity(0.3))
                    .background(RoundedRectangle(cornerRadius: 10).fill(.cyan))
                if let currentStep = levelModel.currentStep {
                    VStack {
                        Text(currentStep.text)
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                                .onTapGesture {
                                    levelModel.goToPreviousStep()
                                }
                                .disabled(!levelModel.previousStepExists)
                                .opacity(levelModel.previousStepExists ? 1 : 0)
                            Spacer()
                            Image(systemName: "arrow.forward.circle.fill")
                                .onTapGesture {
                                    levelModel.goToNextStep(musicianManager: MM, playbackManager: PM)
                                }
                                .disabled(!levelModel.nextStepExists)
                                .opacity(levelModel.nextStepExists ? 1 : 0)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width * 0.75, height: levelModel.currentStep != nil ? geometry.size.height * 0.2 : 0)
            .background(.black)
        }
    }
}
