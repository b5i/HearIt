//
//  LevelStep.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

/// A protocol describing something than can represent a step into a level's UI.
protocol LevelStep {
    associatedtype Label: View
    var view: Label { get }
    
    /// The percentage of the height of the screen that should be used to display the view
    var heightNeeded: Double { get }
    
    var passCondition: (MusiciansManager, PlaybackManager) -> Bool { get }
    
    var stepAction: (() -> Void)? { get }
}

extension LevelStep {
    var heightNeeded: Double {
        return 0.2
    }
}
