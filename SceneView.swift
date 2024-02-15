//
//  SceneView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 07.01.2024.
//

import SwiftUI
import SceneKit
import UIKit
import PHASE

extension String: Error {}

typealias DisabledFeatures = UInt8

struct ActualSceneView: View {
    @StateObject private var PM = PlaybackManager()
    
    @State private var isLoadingScene: Bool = false
    @State private var isSceneLoaded: Bool = false
    @State private var scene: SCNScene?
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
        
    var body: some View {
        if isLoadingScene {
            ProgressView()
        } else if let scene = scene, let MM = MM {
            NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
        } else {
            Color.clear
                .onAppear {
                    if self.scene == nil && !self.isLoadingScene {
                        self.isLoadingScene = true
                        let scene = createScene()
                        self.scene = scene
                        let manager = MusiciansManager(scene: scene)
                        self.MM = manager
                        Task {
                            await setupTutorial(MM: manager)
                            DispatchQueue.main.async {
                                self.isLoadingScene = false
                                self.isSceneLoaded = true
                            }
                        }
                    }
                }
        }
    }
    
    private func createScene() -> SCNScene {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/musicScene.scn")!
        
        let secondRootNote = SCNNode()
        
        scene.rootNode.addChildNode(secondRootNote)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.name = "WWDC24-Camera"
        cameraNode.camera = SCNCamera()
        secondRootNote.addChildNode(cameraNode)
        
        // place the camera and observe its position to adapt the listener position in space
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        self.positionObserver = cameraNode.observe(\.transform, options: [.new], changeHandler: { [weak PM] /* avoid memory leak */ node, _ in
            var matrix = matrix_identity_float4x4
            matrix.columns.3 = .init(x: node.transform.m41, y: node.transform.m42, z: node.transform.m43, w: 1)
            PM?.listener.transform = matrix
        })
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.light?.intensity = 100
        secondRootNote.addChildNode(lightNode)
        
        let spotlightLightNode = SCNNode()
        spotlightLightNode.light = SCNLight()
        spotlightLightNode.light?.type = .spot
        spotlightLightNode.light?.intensity = 1000
        secondRootNote.addChildNode(spotlightLightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        secondRootNote.addChildNode(ambientLightNode)
                
        return scene
    }
    
    private func setupTutorial(MM: MusiciansManager) async {
        func createMusician(withSongName songName: String, audioLevel: Double = 0, index: Int) async {
            if PM.sounds[songName] == nil {
                let newMusician = MM.createMusician(index: index)
                
                newMusician.node.scale = .init(x: 0.05, y: 0.05, z: 0.05)
                newMusician.node.position = .init(x: 4 * Float(index), y: 0, z: 0)
                
                let distanceParameters = PHASEGeometricSpreadingDistanceModelParameters()
                distanceParameters.rolloffFactor = 0.5
                distanceParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 30)
                
                
                
                let result = await PM.loadSound(soundPath: songName, emittedFromPosition: .init(), options: .init(distanceModelParameters: distanceParameters, playbackMode: .looping, audioCalibration: (.relativeSpl, audioLevel)))
                
                switch result {
                case .success(let sound):
                    newMusician.setSound(sound)
                    newMusician.soundDidChangePlaybackStatus(isPlaying: false)
                    sound.delegate = newMusician
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
        
        await createMusician(withSongName: "TutorialSounds/la_panterra.mp3", index: 0)
        
        PM.replaceLoop(by: .init(startTime: 50, endTime: 100, shouldRestart: false, lockLoopZone: false, isEditable: true))
        
        PM.changeConfiguration(for: .init(
            songParts: [
                .init(startTime: 0, type: .introduction, label: "Intro"),
                .init(startTime: 40, type: .themeA, label: "Theme A"),
                .init(startTime: 60, type: .ending, label: "Big pausssssssss")
            ]
        ))
    }
}
struct NonOptionalSceneView: View {
    let scene: SCNScene
    let disabledFeatures: DisabledFeatures
    
    /// Will try to take observe the playback of the song that has this string as assetName
    let soundToObserveName: String?

    @State private var isStarting: Bool = false
        
    @State private var spotlightIt: Bool = false
    
    @ObservedObject private var MM: MusiciansManager
    @ObservedObject var PM: PlaybackManager
        
    init(scene: SCNScene, musicianManager: MusiciansManager, playbackManager: PlaybackManager, disabledFeatures: DisabledFeatures = 0 /* nothing */, soundToObserveName: String? = nil) {
        self.scene = scene
        self._MM = ObservedObject(wrappedValue: musicianManager)
        self._PM = ObservedObject(wrappedValue: playbackManager)
        self.disabledFeatures = disabledFeatures
        self.soundToObserveName = soundToObserveName
    }
    
    var body: some View {
        SceneOptionalARWrapper(scene: scene, musicianManager: MM, playbackManager: PM)
            .takeFullSpace()
            .overlay(alignment: .center, content: {
                if self.isStarting {
                    ZStack {
                        Rectangle()
                            .fill(.black)
                            .frame(width: .infinity, height: .infinity)
                        ProgressView()
                    }
                }
            })
            .overlay(alignment: .bottom) {
                VStack {
                    Spacer()
                    HStack {
                        Button("Spotlight") {
                            withAnimation {
                                spotlightIt.toggle()
                            }
                        }
                        Button("loop") {
                            withAnimation {
                                if PM.currentLoop == nil {
                                    PM.replaceLoop(by: .init(startTime: 0, endTime: 50, shouldRestart: false, lockLoopZone: false, isEditable: true))
                                } else {
                                    PM.removeLoop()
                                }
                            }
                        }
                        /*
                         Button("Load tutorial") {
                         self.isStarting = true
                         Task {
                         await setupTutorial()
                         DispatchQueue.main.async {
                         self.isStarting = false
                         PM.restartAndSynchronizeSounds()
                         }
                         }
                         }
                         
                         Button("Duplicate new sprite") {
                         let newMusician = MM.createMusician()
                         
                         newMusician.node.scale = .init(x: 0.05, y: 0.05, z: 0.05)
                         newMusician.node.position = .init(x: 4 * Float(amountOfSprites), y: 0, z: 0)
                         amountOfSprites += 1
                         
                         let distanceParameters = PHASEGeometricSpreadingDistanceModelParameters()
                         distanceParameters.rolloffFactor = 0.5
                         distanceParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 30)
                         if PlaybackManager.shared.sounds["kick.m4a"] == nil {
                         PlaybackManager.shared.loadSound(soundPath: "kick.m4a", emittedFromPosition: .init(), options: .init(distanceModelParameters: distanceParameters, playbackMode: .looping), completionHandler: { result in
                         switch result {
                         case .success(let sound):
                         newMusician.addSound(sound)
                         case .failure(let error):
                         print("Error: \(error)")
                         }
                         })
                         } else if PlaybackManager.shared.sounds["kick2.m4a"] == nil {
                         PlaybackManager.shared.loadSound(soundPath: "kick2.m4a", emittedFromPosition: .init(), options: .init(distanceModelParameters: distanceParameters, playbackMode: .looping), completionHandler: { result in
                         switch result {
                         case .success(let sound):
                         newMusician.addSound(sound)
                         case .failure(let error):
                         print("Error: \(error)")
                         }
                         })
                         }
                         }
                         */
                        
                        Button("front") {
                            scene.rootNode.getFirstCamera()?.transform.m43 -= 1
                        }
                        Button("back") {
                            scene.rootNode.getFirstCamera()?.transform.m43 += 1
                        }
                        Button("down") {
                            scene.rootNode.getFirstCamera()?.transform.m42 -= 1
                        }
                        Button("up") {
                            scene.rootNode.getFirstCamera()?.transform.m42 += 1
                        }
                        Button("<-") {
                            scene.rootNode.getFirstCamera()?.transform.m41 -= 1
                        }
                        Button("->") {
                            scene.rootNode.getFirstCamera()?.transform.m41 += 1
                        }
                        Button("Synchronize sounds") {
                            PM.restartAndSynchronizeSounds()
                        }
                         
                    }
                    VStack {
                        Spacer()
                        ForEach(Array(MM.musicians.values).filter({!$0.musician.status.isHidden}).sorted(by: {$0.index < $1.index}), id: \.index) { (_, musician) in
                            MusicianHeaderView(disabledFeatures: disabledFeatures, musician: musician)
                            //.spotlight(areaRadius: 100, isEnabled: spotlightIt)
                        }
                        .horizontallyCentered()
                        .padding(40)
                        var soundToUse: Sound? {
                            if let soundToObserveName = soundToObserveName, let sound = PM.sounds.first(where: {$0.value.infos.assetName == soundToObserveName})?.value {
                                return sound
                            } else {
                                return PM.sounds.first?.value
                            }
                        }
                        
                        if let soundToUse = soundToUse {
                            PlayingBarView(playbackManager: PM, sound: soundToUse, soundObserver: soundToUse.timeObserver)
                                .disabled(disabledFeatures.contains(feature: .seekFeature))
                            /*
                             PlayingBarView(endOfSlideAction: { newValue in
                             sound.seek(to: newValue * sound.timeObserver.soundDuration)
                             print("endOfSlideAction: \(newValue)")
                             }, endOfZoomAction: { normalSliderValue, zoomedInSliderValue in
                             sound.seek(to: sound.timeObserver.currentTime * normalSliderValue + 20 * (zoomedInSliderValue - 0.5))
                             print("endOfZoomAction: \(normalSliderValue), \(zoomedInSliderValue)")
                             }, externalSliderValue: sliderValue, isPlaying: isPlaying)
                             .frame(alignment: .bottom)
                             */
                            //PlayingBarWrapperView(sound: sound, soundObserver: sound.timeObserver)
                        }
                        
                        /*
                         ForEach(Array(PM.sounds.enumerated()), id: \.offset) { (_, sound) in
                         let sound = sound.1
                         VStack {
                         HStack {
                         Text(sound.infos.soundPath)
                         Button("Play") {
                         PlaybackManager.shared.playSound(soundPath: sound.infos.soundPath)
                         }
                         Button("Pause") {
                         PlaybackManager.shared.pause(soundPath: sound.infos.soundPath)
                         }
                         }
                         }
                         }
                         */
                    }
                    .padding(.bottom)
                }
            }
    }
    
    /*
    private struct PlayingBarWrapperView: View {
        let sound: PlaybackManager.Sound
        @ObservedObject var soundObserver: PlaybackManager.Sound.SoundPlaybackObserver
        var body: some View {
            let sliderValue: Binding<Double> = Binding(get: {
                return soundObserver.currentTime / soundObserver.soundDuration
            }, set: {_ in})
            let isPlaying: Binding<Bool> = Binding {
                return soundObserver.isPlaying
            } set: { newValue in
                if newValue {
                    sound.pause()
                } else {
                    sound.play()
                }
            }

            
            PlayingBarView(endOfSlideAction: { newValue in
                sound.seek(to: newValue * sound.timeObserver.soundDuration)
                print("endOfSlideAction: \(newValue)")
            }, endOfZoomAction: { normalSliderValue, zoomedInSliderValue in
                sound.seek(to: sound.timeObserver.currentTime * normalSliderValue + 20 * (zoomedInSliderValue - 0.5))
                print("endOfZoomAction: \(normalSliderValue), \(zoomedInSliderValue)")
            }, externalSliderValue: sliderValue, isPlaying: isPlaying)
                .frame(alignment: .bottom)
        }
    }     */

    
    private struct PlaybackProgressView: View {
        let sound: Sound
        @StateObject var playbackObserver: Sound.SoundPlaybackObserver
        
        init(sound: Sound) {
            self.sound = sound
            self._playbackObserver = StateObject(wrappedValue: sound.timeObserver)
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(.gray)
                        .frame(width: geometry.size.width, height: 10)
                    RoundedRectangle(cornerRadius: 50)
                        .fill(.white)
                        .frame(width: geometry.size.width * (playbackObserver.currentTime / playbackObserver.soundDuration), height: 10)
                }
            }
        }
    }
}

#Preview {
    TutorialLevelView()
}

struct SceneOptionalARWrapper: View {
    let scene: SCNScene
    let musicianManager: MusiciansManager
    let playbackManager: PlaybackManager
    
    @ObservedObject private var ARM: ARManager = .shared
    var body: some View {
        Group {
            if ARM.isAROn {
                ARSceneView(scene: scene, musicianManager: musicianManager, playbackManager: playbackManager)
            } else {
                SceneViewWrapper(scene: scene, musicianManager: musicianManager, playbackManager: playbackManager)
            }
        }
        .onAppear {
            ARM.setup(MM: musicianManager, PM: playbackManager)
        }
        .onDisappear {
            ARM.reset()
        }
    }
}

struct SceneViewWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = SceneViewController
    
    let scene: SCNScene
    let showsStatistics: Bool = false
    let musicianManager: MusiciansManager
    let playbackManager: PlaybackManager
    
    func makeUIViewController(context: Context) -> SceneViewController {
        let controller = SceneViewController(scene: scene, showStatistics: showsStatistics, musicianManager: musicianManager, playbackManager: playbackManager)
        
        return controller
    }
    
    func updateUIViewController(_ uiView: SceneViewController, context: Context) {}
}

class SceneViewController: UIViewController, SCNSceneRendererDelegate {
    let scene: SCNScene
    var showStatistics: Bool = false
    let musicianManager: MusiciansManager
    let playbackManager: PlaybackManager
    
    init(scene: SCNScene, showStatistics: Bool = false, musicianManager: MusiciansManager, playbackManager: PlaybackManager) {
        self.scene = scene
        self.showStatistics = showStatistics
        self.musicianManager = musicianManager
        self.playbackManager = playbackManager
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let view = SCNView()
        view.scene = self.scene
        view.delegate = self
        view.showsStatistics = self.showStatistics
        //view.allowsCameraControl = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        self.view = view
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
                
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        
        var didToggleSpotlight: Bool = false // avoid having two hit results on the same part that will let the spotlight's power status unchanged
        var didTogglePlayback: Bool = false
        
        for result in hitResults {
            guard let musician = result.node.getMusicianParent(), let musicianName = musician.name else { continue }
            if result.node.isSpotlightPart {
                if !didToggleSpotlight {
                    musicianManager.musicians[musicianName]?.musician.goToNextColor()
                    didToggleSpotlight = true
                }
            } else if result.node.isMusicianBodyPart {
                if !didTogglePlayback {
                    musicianManager.musicians[musicianName]?.musician.sound?.isMuted.toggle() // won't do anything if the result is not a musician
                    didTogglePlayback = true
                }
            }
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if let camera = scene.rootNode.getFirstCamera() {
            if let headphonesPosition = self.playbackManager.headphonesPosition {
                self.playbackManager.listener.worldTransform = matrix_multiply(camera.simdWorldTransform, headphonesPosition.toSIMDMatrix())
            } else {
                self.playbackManager.listener.worldTransform = camera.simdWorldTransform
            }
        } else {
            self.playbackManager.listener.worldTransform = matrix_identity_float4x4
        }
    }
}

extension View {
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
}
