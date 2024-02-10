//
//  NavigationModel.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import Foundation

class NavigationModel: ObservableObject {
    static let shared = NavigationModel()
    
    @Published var currentStep: NavigationStep = .homeScreen
    
    enum NavigationStep: Equatable {
        case homeScreen
        case levelsView
        case levelView(level: Level)
    }
    
    enum Level: String, CaseIterable {        
        case tutorial = "Tutorial"
        case boleroTheme = "1. Theme and others."
    }
}
