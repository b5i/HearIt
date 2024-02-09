//
//  View+centered.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 09.02.2024.
//

import SwiftUI

extension View {
    func horizontallyCentered() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
    
    func verticallyCentered() -> some View {
        VStack {
            Spacer()
            self
            Spacer()
        }
    }
}
