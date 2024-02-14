import SwiftUI

struct ContentView: View {
    @ObservedObject private var spotlightModel = SpotlightModel.shared
    @ObservedObject private var NM = NavigationModel.shared
    
    var body: some View {
        switch NM.currentStep {
        case .homeScreen:
            HomeScreenView()
                //.animation(.bouncy, value: NM.currentStep == .homeScreen)
                .transition(.move(edge: .top))
        case .levelsView:
            LevelsView()
        case .levelView(let level):
            ZStack {
                Rectangle()
                    .fill(.black) // SceneKit's scene is black so we need to force the black background
                    .ignoresSafeArea()
                switch level {
                case .tutorial:
                    TutorialLevelView()
                case .boleroTheme:
                    BoleroLevelView()
                case .twoThemes:
                    TwoThemesView()
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
extension Notification.Name {
    static let shouldStopEveryEngineNotification: Notification.Name = .init("ShouldStopEveryEngineNotification")
    
    static let shouldStopAREngine: Notification.Name = .init("ShouldStopAREngine")
}
