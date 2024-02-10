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


struct ActualSceneView: View {
    @State private var scene: SCNScene?
    @State private var isLoadingScene: Bool = false
    
    @ObservedObject var PM: PlaybackManager
    
    @State private var MM: MusiciansManager?
    
    @State private var positionObserver: NSKeyValueObservation? = nil
    
    var body: some View {
        if let scene = scene, let MM = MM {
            NonOptionalSceneView(scene: scene, musicianManager: MM, playbackManager: PM)
        } else if isLoadingScene {
            ProgressView()
        } else {
            Color.clear.onAppear {
                self.isLoadingScene = true
                self.scene = createScene()
                self.isLoadingScene = false
            }
        }
    }
    private func createScene() -> SCNScene {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/musicScene.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.name = "WWDC24-Camera"
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera and observe its position to adapt the listener position in space
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        self.positionObserver = cameraNode.observe(\.transform, options: [.new], changeHandler: { node, _ in
            var matrix = matrix_identity_float4x4
            matrix.columns.3 = .init(x: node.transform.m41, y: node.transform.m42, z: node.transform.m43, w: 1)
            PM.listener.transform = matrix
        })
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.light?.intensity = 100
        scene.rootNode.addChildNode(lightNode)
        
        let spotlightLightNode = SCNNode()
        spotlightLightNode.light = SCNLight()
        spotlightLightNode.light?.type = .spot
        spotlightLightNode.light?.intensity = 1000
        scene.rootNode.addChildNode(spotlightLightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
                
        return scene
    }
}

struct NonOptionalSceneView: View {
    let scene: SCNScene
    
    @State private var isStarting: Bool = false
        
    @State private var spotlightIt: Bool = false
    
    @ObservedObject private var MM: MusiciansManager
    @ObservedObject var PM: PlaybackManager
        
    init(scene: SCNScene, musicianManager: MusiciansManager, playbackManager: PlaybackManager) {
        self.scene = scene
        self._MM = ObservedObject(wrappedValue: musicianManager)
        self._PM = ObservedObject(wrappedValue: playbackManager)
    }
    
    var body: some View {
        SceneViewWrapper(scene: scene, musicianManager: MM)
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
                        Button("Place loop") {
                            self.PM.replaceLoop(by: .init(startTime: 0, endTime: 20, shouldRestart: false))
                        }
                        Button("Spotlight") {
                            withAnimation {
                                spotlightIt.toggle()
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
                        Button("^") {
                            scene.rootNode.getFirstCamera()?.transform.m43 -= 1
                        }
                        Button("v") {
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
                        HStack(alignment: .center) {
                            ForEach(Array(MM.musicians.values), id: \.index) { (_, musician) in
                                LittleMusicianView(musician: musician)
                                    .spotlight(areaRadius: 100, isEnabled: spotlightIt)
                            }
                        }
                        if let sound = PM.sounds.first?.value {
                            PlayingBarView(playbackManager: PM, sound: sound, soundObserver: sound.timeObserver)
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
    
    private struct LittleMusicianView: View {
        @ObservedObject var musician: Musician
        var body: some View {
            VStack {
                Image(systemName: self.musician.status.isSpotlightOn ? "figure.wave.circle.fill" : "figure.wave.circle")
                    .resizable()
                    .sfReplaceEffect()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .animation(.spring, value: self.musician.status.isSpotlightOn)
                    .foregroundStyle(Color(cgColor: self.musician.status.spotlightColor.getCGColor()))
                    .animation(.spring, value: self.musician.status.spotlightColor)
                    .onTapGesture {
                        self.musician.goToNextColor()
                    }
                HStack(spacing: 10) {
                    Button {
                        self.musician.sound?.isMuted.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.white)
                                .opacity(0.3)
                                .frame(width: 35, height: 35)
                            Image(systemName: self.musician.status.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .resizable()
                                .sfReplaceEffect()
                                .scaledToFit()
                                .frame(width: 20)
                                .foregroundStyle(self.musician.status.isMuted ? .red : .white)
                                .padding(5)
                        }
                    }
                    .frame(width: 35, height: 35)
                    Button {
                        self.musician.sound?.isSoloed.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.white)
                                .opacity(0.3)
                                .frame(width: 35, height: 35)
                            Image(systemName: self.musician.status.isSoloed ? "s.circle.fill" : "s.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                                .foregroundStyle(self.musician.status.isSoloed ? .yellow : .white)
                                .padding(5)
                        }
                    }
                    .frame(width: 35, height: 35)
                }
            }
        }
    }

    
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


struct SceneViewWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = SceneViewController
    
    let scene: SCNScene
    let showsStatistics: Bool = false
    let musicianManager: MusiciansManager
    
    func makeUIViewController(context: Context) -> SceneViewController {
        let controller = SceneViewController(scene: scene, showStatistics: showsStatistics, musicianManager: musicianManager)
        
        return controller
    }
    
    func updateUIViewController(_ uiView: SceneViewController, context: Context) {}
}

class SceneViewController: UIViewController {
    let scene: SCNScene
    var showStatistics: Bool = false
    let musicianManager: MusiciansManager
    
    init(scene: SCNScene, showStatistics: Bool = false, musicianManager: MusiciansManager) {
        self.scene = scene
        self.showStatistics = showStatistics
        self.musicianManager = musicianManager
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        let view = SCNView()
        view.scene = self.scene
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
}
