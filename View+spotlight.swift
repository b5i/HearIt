//
//  View+spotlight.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import SwiftUI

extension View {
    /// Apply a spotlight effect on the view that can be activated later on using ``SpotlightModel/setSpotlightActiveStatus(ofType:to:)``.
    ///
    /// - Warning: You should **never** set the spotlight property for a type created with customWithAsset with a nil for the customAsset property (otherwise it'll activate every spotlight that has the same name).
    func spotlight(type: SpotlightModel.SpotlightType, areaRadius: CGFloat = 30, customPosition: (x: Double?, y: Double?) = (nil, nil)) -> some View {
        return self.overlay(alignment: .center) {
            GeometryReader { geometry in
                let spotlightCenter = CGPoint(x: customPosition.x ?? geometry.frame(in: .global).midX, y: customPosition.y ?? geometry.frame(in: .global).midY)
                Color.clear
                    .onAppear {
                        SpotlightModel.shared.setSpotlight(withType: type, to: SpotlightModel.Spotlight(position: spotlightCenter, areaRadius: areaRadius))
                    }
                    .id(spotlightCenter) // so it updates automatically
            }
        }
    }
}
