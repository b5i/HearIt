//
//  SongPartsConfiguration+getColor.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 13.02.2024.
//

import SwiftUI

extension PlaybackManager.SongPartsConfiguration.Part {
    func getColor() -> Color {
        switch self {
        case .themeA:
            return .yellow
        case .themeB:
            return .purple
        case .introduction:
            return .blue
        case .ending:
            return .red
        case .bridge:
            return .green
        case .pause:
            return .cyan
        }
    }
}
