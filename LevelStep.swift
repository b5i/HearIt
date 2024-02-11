//
//  LevelStep.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

/// A protocol describing something than can represent a step into a level's UI.
protocol LevelStep {
    associatedtype Label: View
    var view: Label { get }
    
    var passCondition: (MusiciansManager, PlaybackManager) -> Bool { get }
    
    var stepAction: (() -> Void)? { get }
}
