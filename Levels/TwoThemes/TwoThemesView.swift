//
//  TwoThemesView.swift
//  
//
//  Created by Antoine Bollengier on 11.02.2024.
//

import SwiftUI

struct TwoThemesView: View {
    @State private var finishedIntroduction: Bool = false
    var body: some View {
        if finishedIntroduction {
            TwoThemesTestView()
        } else {
            TwoThemesIntroductionView(finishedIntroduction: $finishedIntroduction)
        }
    }
}
