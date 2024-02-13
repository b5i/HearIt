import SwiftUI

let appName: String = "[name of the app]"

@main
struct MyApp: App {
    @ObservedObject private var spotlightModel = SpotlightModel.shared
    var body: some Scene {
        WindowGroup {
            //TwoThemesTestView()
            //ActualSceneView()
            ContentView()
                .globalSpotlight(spotlights: spotlightModel.spotlights)
        }
    }
}

fileprivate extension View {
    @ViewBuilder func globalSpotlight2(center: CGPoint?, areaRadius: CGFloat?, isEnabled: Bool) -> some View {
        if #available(iOS 17.0, *), let center = center, let areaRadius = areaRadius {
            self.colorEffect(Shader(function: ShaderFunction(library: ShaderLibrary.bundle(.main), name: "spotlight"), arguments: [.float2(center.x, center.y), .float(areaRadius)]), isEnabled: isEnabled)
        } else {
            self
        }
    }
    @ViewBuilder func globalSpotlight(spotlights: [SpotlightModel.SpotlightType: (spotlight: SpotlightModel.Spotlight, isEnabled: Bool)]) -> some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(.black)
                self.mask({
                    ZStack {
                        Rectangle()
                            .opacity(spotlights.values.contains(where: {$0.isEnabled}) ? 0.1 : 1)
                        ForEach(Array(spotlights.values.enumerated()), id: \.offset) { (_, spotlight) in
                            
                            let (spotlight, _) = spotlight
                            Circle()
                                .frame(width: spotlight.areaRadius, height: spotlight.areaRadius)
                                .position(spotlight.position)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                })
            }
        }
        .ignoresSafeArea()
    }
}
