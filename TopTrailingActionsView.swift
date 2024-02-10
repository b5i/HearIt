//
//  TopTrailingActionsView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

struct TopTrailingActionsView: View {
    @ObservedObject private var SM = SpotlightModel.shared
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
            Image(systemName: SM.isEnabled ? "lightbulb.max.fill" : "lightbulb")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(.yellow)
                .gesture(
                    DragGesture(minimumDistance: 0.0) // infinite time longpressgesture
                        .onChanged({ currentValue in
                            SM.setSpotlightActiveStatus(to: true)
                        })
                        .onEnded({ _ in
                            SM.setSpotlightActiveStatus(to: false)
                        })
                )
            Button {
                LevelsManager.shared.returnToLevelsView(unlockingLevel: Model.shared.unlockedLevel) // TODO: add a confirmation dialog
            } label: {
                Image(systemName: "door.left.hand.open")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.red)
            }
            .padding()
        }
    }
    
    class Model {
        static let shared = Model()
        
        var unlockedLevel: LevelsManager.Level? = nil
    }
}

#Preview {
    TopTrailingActionsView()
}
