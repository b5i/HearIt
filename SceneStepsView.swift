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
            VStack {
                if let currentStep = levelModel.currentStep {
                    ZStack {
                        //BlurView()
                        //    .clipShape(RoundedRectangle(cornerRadius: 25))
                        RoundedRectangle(cornerRadius: 25)
                            .strokeBorder(.white, lineWidth: 3)
                            .background(RoundedRectangle(cornerRadius: 25).fill(.black.opacity(1)))
                        HStack {
                            VStack(alignment: .leading) {
                                AnyView(currentStep.view)
                                    .padding()
                                    .padding(.bottom) // right and left arrows
                                Spacer()
                            }
                            Spacer()
                        }
                        VStack {
                            Spacer()
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
                                        levelModel.goToNextStep(musicianManager: MM, playbackManager: PM)
                                    }
                                    .disabled(!levelModel.nextStepExists)
                                    .opacity(levelModel.nextStepExists ? 1 : 0)
                                    .spotlight(type: .goForwardArrow, areaRadius: 30)
                            }
                            .padding()
                        }
                    }
                    .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
                }
            }
            .frame(minWidth:  geometry.size.width * 0.4, maxWidth:  geometry.size.width * 0.75, maxHeight: levelModel.currentStep != nil ? geometry.size.height : 0)
            .padding()
        }
        .padding(.top, 20)
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
            BoleroLevelIntroductionView(isLoadingScene: isLoadingScene, finishedIntroduction: isLoadingScene)
        }
    }

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        return blurEffectView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
