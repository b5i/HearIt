//
//  TwoThemesView.swift
//  
//
//  Created by Antoine Bollengier on 11.02.2024.
//

import SwiftUI

struct TwoThemesView: View {
    @State private var finishedIntroduction: Bool = false
    
    @Binding var isLoadingScene: Bool
    var body: some View {
        if finishedIntroduction {
            TwoThemesTestView(isLoadingScene: $isLoadingScene)
        } else {
            TwoThemesIntroductionView(isLoadingScene: $isLoadingScene, finishedIntroduction: $finishedIntroduction)
        }
    }
}
