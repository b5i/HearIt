import SwiftUI

struct ContentView: View {
    @ObservedObject private var spotlightModel = SpotlightModel.shared
    @ObservedObject private var NM = NavigationModel.shared
    @ObservedObject private var LM = LevelsManager.shared
    
    @Namespace private var animation
    
    @State private var isLoadingAScene: Bool = false
    var body: some View {
        switch NM.currentStep {
        case .homeScreen:
            //GeometryReader { geometry in
                HomeScreenView(homeScreenAnimation: animation)
                .transition(.asymmetric(insertion: .identity, removal: .move(edge: .top)))
            //}

            //.animation(.bouncy, value: NM.currentStep == .homeScreen)
        case .levelsView:
            LevelsView(homeScreenAnimation: animation, shouldGradientGoToMiddle: LM.levelStarted || isLoadingAScene)
        case .levelView(let level):
            ZStack {
                Rectangle()
                    .fill(.black) // SceneKit's scene is black so we need to force the black background
                    .ignoresSafeArea()
                switch level {
                case .tutorial:
                    TutorialLevelView(isLoadingScene: $isLoadingAScene)
                case .boleroTheme:
                    BoleroLevelView(isLoadingScene: $isLoadingAScene)
                case .twoThemes:
                    TwoThemesView(isLoadingScene: $isLoadingAScene)
                }
            }
        }
        /*
         VStack {
         TutorialLevelView()
         //ActualSceneView()
         }*/
        //.globalSpotlight(center: spotlightModel.spotlight?.position, areaRadius: spotlightModel.spotlight?.areaRadius, isEnabled: spotlightModel.isEnabled)
    }
}
