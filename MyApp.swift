import SwiftUI

let appName: String = "Hear it!" /* "[name of the app]" */

@main
struct MyApp: App {
    @ObservedObject private var spotlightModel = SpotlightModel.shared
    var body: some Scene {
        WindowGroup {
            //TwoThemesTestView()
            //ActualSceneView()
            ContentView()
            //ARTestView2()
                .globalSpotlight()
        }
    }
}

fileprivate extension View {
    @ViewBuilder func globalSpotlight() -> some View {
        self.modifier(GlobalSpotlightModifier())
    }
}

struct GlobalSpotlightModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject private var spotlightModel: SpotlightModel = SpotlightModel.shared
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(spotlightModel.isOn ? .black : colorScheme.backgroundColor)
                content.mask({
                    ZStack {
                        Rectangle()
                            .opacity(spotlightModel.spotlights.values.contains(where: {$0.isEnabled}) && spotlightModel.isOn ? 0.1 : 1)
                        ForEach(Array(spotlightModel.spotlights.enumerated()), id: \.offset) { (_, spotlight) in
                            
                            let (type, (spotlight, isEnabled)) = spotlight
                            
                            var computedIsEnabled: Bool {
                                switch type {
                                case .customWithAsset(let name, let assetName):
                                    if assetName != nil {
                                        return isEnabled || spotlightModel.spotlights.contains(where: {$0.key == .customWithAsset(name: name, uniqueIdentifier: nil) && $0.value.isEnabled})
                                    } else { // muteAll like spotlight (it activates the other but doesn't activate itself)
                                        return false
                                    }
                                case .custom:
                                    return isEnabled
                                default:
                                    return isEnabled
                                }
                            }
                            
                            Circle()
                                .frame(width: spotlight.areaRadius, height: spotlight.areaRadius)
                                .position(spotlight.position)
                                .opacity(computedIsEnabled ? 1 : 0)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                })
            }
        }
        .ignoresSafeArea()
    }
}
