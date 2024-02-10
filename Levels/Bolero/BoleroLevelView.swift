//
//  BoleroLevelView.swift
//
//
//  Created by Antoine Bollengier on 10.02.2024.
//

import SwiftUI

struct BoleroLevelView: View {
    @State private var finishedIntroduction: Bool = false
    var body: some View {
        if finishedIntroduction {
            BoleroLevelTestView()
        } else {
            BoleroLevelIntroductionView(finishedIntroduction: $finishedIntroduction)
        }
    }
}
