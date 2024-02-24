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
    
    enum LevelsViewCategories: String, CaseIterable {
        case homeScreen
        case tutorial
        case boleroTheme
        case twoThemes
        
        func getLevel() -> Level? {
            switch self {
            case .homeScreen:
                return nil
            case .tutorial:
                return .tutorial
            case .boleroTheme:
                return .boleroTheme
            case .twoThemes:
                return .twoThemes
            }
        }
    }
    
    enum Level: String, CaseIterable {   
        case tutorial = "Tutorial"
        case boleroTheme = "3 Elements"
        case twoThemes = "2 Themes"
    }
}
