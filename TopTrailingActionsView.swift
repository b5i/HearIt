//
//  TopTrailingActionsView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

struct TopTrailingActionsView: View {
    @ObservedObject private var SM = SpotlightModel.shared
    @ObservedObject private var ARM = ARManager.shared
    @ObservedObject private var AM = AnswersModel.shared
    var body: some View {
        HStack {
            /*
             Button {
             
             } label: {
             Image(systemName: "gear")
             .resizable()
             .scaledToFit()
             .frame(width: 30, height: 30)
             .foregroundStyle(colorScheme.textColor)
             }*/
                Button {
                    withAnimation {
                        AnswersModel.shared.showSheet = true
                    }
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: AM.shouldShowButton ? 30 : 0, height: 30)
                        .foregroundStyle(.green)
                }
                .padding()
                
            if ARManager.isAREnabled {
                Button {
                    ARM.toggleARMode()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(ARM.isAROn ? .clear : .green, lineWidth: 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(ARM.isAROn ? .green : .clear))
                        Text("AR")
                            .foregroundStyle(ARM.isAROn ? .black : .green)
                            .bold()
                    }
                    .frame(width: 50, height: 30)
                    /*
                     Image(systemName: ARM.isAROn ? "viewfinder.circle.fill" : "viewfinder.circle")
                     .resizable()
                     .scaledToFit()
                     .foregroundStyle(.green)
                     .frame(width: 30, height: 30)
                     */
                }
                .padding()
            }
            Image(systemName: SM.isOn ? "lightbulb.max.fill" : "lightbulb")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(.yellow)
                .gesture(
                    DragGesture(minimumDistance: 0.0) // infinite time longpressgesture
                        .onChanged({ currentValue in
                            SM.turnOnSpotlight()
                        })
                        .onEnded({ _ in
                            SM.turnOffSpotlight()
                        })
                )
                .spotlight(type: .lightBulb, areaRadius: 50)
                .padding()
            Button {
                SpotlightModel.shared.clearCache()
                LevelsManager.shared.returnToLevelsView(unlockingLevel: Model.shared.unlockedLevel) // TODO: add a confirmation dialog
            } label: {
                Image(systemName: "door.left.hand.open")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.red)
            }
            .padding()
            .spotlight(type: .door, areaRadius: 50)
        }
        .padding(.top)
    }
    
    class Model {
        static let shared = Model()
        
        var unlockedLevel: LevelsManager.Level? = nil
    }
}

#Preview {
    TopTrailingActionsView()
}
