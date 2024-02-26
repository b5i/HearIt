//
//  BackgroundGradientView.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 16.02.2024.
//

import SwiftUI
import Combine

struct BackgroundGradientView: View {
    static let middleAnimationDuration: Double = 0.7
    
    @Environment(\.colorScheme) private var colorScheme
    
    let level: LevelsManager.Level
    let shouldGoToMiddle: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<4) { index in
                    var topLeadingPoint: CGPoint {
                        
                        switch index {
                        case 0:
                            return .zero
                        case 1:
                            return .init(x: geometry.size.width / 2, y: 0)
                        case 2:
                            return .init(x: 0, y: geometry.size.height / 2)
                        case 3:
                            return .init(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        default:
                            return .zero
                        }
                    }
                    
                    var colors: [Color] {
                        /*
                         let redCombination: [Color] = [.red, .orange, shouldGoToMiddle ? colorScheme.backgroundColor : .yellow]
                         let yellowCombination: [Color] = [.yellow, .green, shouldGoToMiddle ? colorScheme.backgroundColor : .cyan]
                         let cyanCombination: [Color] = [.cyan, .blue, shouldGoToMiddle ? colorScheme.backgroundColor : .purple]
                         let purpleCombination: [Color] = [.purple, .pink, shouldGoToMiddle ? colorScheme.backgroundColor : .red]
                         */
                        let redCombination: [Color] = [.red, .orange, shouldGoToMiddle ? .black : .yellow]
                        let yellowCombination: [Color] = [.yellow, .green, shouldGoToMiddle ? .black : .cyan]
                        let cyanCombination: [Color] = [.cyan, .blue, shouldGoToMiddle ? .black : .purple]
                        let purpleCombination: [Color] = [.purple, .pink, shouldGoToMiddle ? .black : .red]
                        switch index {
                        case 1:
                            switch level {
                            case .tutorial:
                                return redCombination
                            case .boleroTheme:
                                return yellowCombination
                            case .twoThemes:
                                return cyanCombination
                            }
                        case 2:
                            switch level {
                            case .tutorial:
                                return yellowCombination
                            case .boleroTheme:
                                return cyanCombination
                            case .twoThemes:
                                return purpleCombination
                            }
                        case 3:
                            switch level {
                            case .tutorial:
                                return cyanCombination
                            case .boleroTheme:
                                return purpleCombination
                            case .twoThemes:
                                return redCombination
                            }
                        case 4:
                            switch level {
                            case .tutorial:
                                return purpleCombination
                            case .boleroTheme:
                                return redCombination
                            case .twoThemes:
                                return yellowCombination
                            }
                        default:
                            return redCombination
                        }
                    }
                    Point(geometry: geometry, shouldStayInRect: .init(x: topLeadingPoint.x, y: topLeadingPoint.y, width: geometry.size.width / 2, height: geometry.size.height / 2), gradientColors: colors, shouldGoToMiddle: shouldGoToMiddle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(geometry.size)
                }
            }
        }
        .animation(.smooth(duration: Self.middleAnimationDuration), value: self.shouldGoToMiddle)
        .overlay(alignment: .center, content: {
            if shouldGoToMiddle {
                ProgressView()
                    .tint(.white)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.smooth(duration: Self.middleAnimationDuration - 0.5).delay(0.5), value: shouldGoToMiddle)
            }
        })
    }
    
    struct Point: View {
        let geometry: GeometryProxy
        let destinationDistance: Double = 70
        let rectArea: CGRect
        let colors: [Color]
        let refreshTime: Double
        @State private var position: CGPoint
        let timer: Publishers.Autoconnect<Timer.TimerPublisher>
        
        let defaultEclipseSize = CGSize(width: 200, height: 200)
        @State private var currentElipseSize: CGSize = CGSize(width: 200, height: 200)
        let elipseVariation: Double = 50
        let elipseBlur: Double = 35
        let isMiddleCentered: Bool
        
        
        init(geometry: GeometryProxy, shouldStayInRect: CGRect, timeTillRefresh: Double = 5, gradientColors: [Color], shouldGoToMiddle: Bool) {
            self.geometry = geometry
            self.rectArea = shouldStayInRect
            self.colors = gradientColors
            self.refreshTime = timeTillRefresh
            self.timer = Timer.publish(every: timeTillRefresh, on: .main, in: .common).autoconnect()
            self.isMiddleCentered = shouldGoToMiddle
            self._currentElipseSize = State(wrappedValue: self.defaultEclipseSize)
            self._position = State(wrappedValue: CGPoint(x: shouldStayInRect.midX * Double.random(in: 0.7...1.3), y: shouldStayInRect.midY * Double.random(in: 0.7...1.3)))
        }
        var body: some View {
            Ellipse()
                .fill(EllipticalGradient(gradient: Gradient(colors: colors), center: .center, startRadiusFraction: 0.5, endRadiusFraction: isMiddleCentered ? 0.25 : 0.1))
                .frame(width: isMiddleCentered ? defaultEclipseSize.width : currentElipseSize.width, height: isMiddleCentered ? defaultEclipseSize.height : currentElipseSize.height)
                .blur(radius: elipseBlur)
                .position(isMiddleCentered ? .init(x: geometry.size.width / 2, y: geometry.size.height / 2) : position)
                .onReceive(timer, perform: { _ in
                    goToNewPoint()
                })
                .onAppear {
                    goToNewPoint()
                }
        }
        
        private func goToNewPoint() {
            Task { // avoid blocking the thread if it can't find the next destination
                var foundSolution: Bool = false
                
                var newDirection = Double.random(in: 0...2*Double.pi)
                var newDestination = CGPoint(x: self.position.x + destinationDistance * cos(newDirection), y: self.position.y + destinationDistance * sin(newDirection))
                var newWidth = currentElipseSize.width + Double.random(in: -elipseVariation...elipseVariation)
                var newHeight = currentElipseSize.height + Double.random(in: -elipseVariation...elipseVariation)
                for _ in 0..<100 { // try only a hundred times to avoid using all the ressources
                    if
                        newDestination.x - newWidth / 2 < rectArea.minX ||
                            newDestination.y - newHeight / 2 < rectArea.minY ||
                            newDestination.x + newWidth / 2 > rectArea.maxX ||
                            newDestination.y + newHeight / 2 > rectArea.maxY ||
                            abs(newHeight - defaultEclipseSize.height) > elipseVariation ||
                            abs(newWidth - defaultEclipseSize.width) > elipseVariation { // check if the bubbles stay in their attributed rectangle, otherwise regenerate the values
                        newDirection = Double.random(in: 0...2*Double.pi)
                        newDestination = CGPoint(x: self.position.x + destinationDistance * cos(newDirection), y: self.position.y + destinationDistance * sin(newDirection))
                        newHeight = currentElipseSize.height + Double.random(in: -elipseVariation...elipseVariation)
                        newWidth = currentElipseSize.width + Double.random(in: -elipseVariation...elipseVariation)                        
                    } else {
                        foundSolution = true
                        break
                    }
                }
                
                if foundSolution {
                    // avoid being annoyed with the concurrent code warning
                    let finalDestination = newDestination
                    let finalNewWidth = newWidth
                    let finalNewHeight = newHeight
                    
                    DispatchQueue.main.async {
                        withAnimation(.linear(duration: refreshTime)) {
                            self.position.x = finalDestination.x
                            self.position.y = finalDestination.y
                            self.currentElipseSize = CGSize(width: finalNewWidth, height: finalNewHeight)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BackgroundGradientView(level: .tutorial, shouldGoToMiddle: false)
}
