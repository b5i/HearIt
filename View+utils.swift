//
//  View+castedOnChange.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import SwiftUI

extension View {
    func castedOnChange<V>(of value: V, perform action: @escaping () -> Void) -> some View where V: Equatable {
        if #available(iOS 17.0, *) {
            return self.onChange(of: value, {
                action()
            })
        } else {
            return self.onChange(of: value, perform: {_ in
                action()
            })
        }
    }
    
    /// apply the content transition only if the device is iOS 17.0 or later
    func sfReplaceEffect() -> some View {
        if #available(iOS 17.0, *) {
            return self.contentTransition(.symbolEffect(.replace))
        } else {
            return self
        }
    }
    
    func takeFullSpace() -> some View {
        GeometryReader { geometry in
            self
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
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
