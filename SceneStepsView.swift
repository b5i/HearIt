//
//  SceneStepsView.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

struct SceneStepsView: View {
    @StateObject var levelModel: LevelModel
    
    @ObservedObject var MM: MusiciansManager
    @ObservedObject var PM: PlaybackManager
    
    @State private var forwardArrowShakes: CGFloat = 0
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    if let currentStep = levelModel.currentStep {
                        ZStack {
                            //BlurView()
                            //    .clipShape(RoundedRectangle(cornerRadius: 25))
                            RoundedRectangle(cornerRadius: 25)
                                .strokeBorder(.white, lineWidth: 3)
                                .background(RoundedRectangle(cornerRadius: 25).fill(.black.opacity(1)))
                            .overlay(alignment: .bottom, content: {
                                HStack {
                                    Image(systemName: "arrow.backward.circle.fill")
                                        .foregroundStyle(.white)
                                        .onTapGesture {
                                            levelModel.goToPreviousStep()
                                        }
                                        .disabled(!levelModel.previousStepExists)
                                        .opacity(levelModel.previousStepExists ? 1 : 0)
                                        .spotlight(type: .goBackwardArrow, areaRadius: 30)
                                    Spacer()
                                    Image(systemName: "arrow.forward.circle.fill")
                                        .foregroundStyle(.white)
                                        .onTapGesture {
                                            if !levelModel.goToNextStep(musicianManager: MM, playbackManager: PM) {
                                                withAnimation {
                                                    self.forwardArrowShakes += 2
                                                }
                                            }
                                        }
                                        .disabled(!levelModel.nextStepExists)
                                        .opacity(levelModel.nextStepExists ? 1 : 0)
                                        .spotlight(type: .goForwardArrow, areaRadius: 30)
                                        .shake(with: forwardArrowShakes)
                                }
                                .padding([.horizontal, .bottom])
                            })
                            HStack {
                                VStack(alignment: .leading) {
                                    AnyView(currentStep.view)
                                        .padding()
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.bottom)
                                }
                                Spacer()
                            }
                            .clipped()
                        }
                        //.transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width * 0.75)
                .frame(maxHeight: geometry.size.height * 0.2, alignment: .top)
                //.frame(minWidth:  geometry.size.width * 0.4, maxWidth:  geometry.size.width * 0.75, maxHeight: levelModel.currentStep != nil ? geometry.size.height : 0)
                .padding()
            }
        }
        .padding(.top)
        .padding(.bottom)
    }
}
#Preview {
    Group {
        let isLoadingScene: Binding<Bool> = Binding(get: {
            return false
        }, set: { _ in
            return
        })
        BoleroLevelTestView(isLoadingScene: isLoadingScene)
    }
}
