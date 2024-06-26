//
//  PlaybackManager.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 10.01.2024.
//

import PHASE
import CoreMotion

class PlaybackManager: NSObject, ObservableObject {
    //static let shared = PlaybackManager()
    
    struct SoundCharacteristic {
        enum SpatialFlag {
            case directPathTransmission
            case earlyReflections
            case lateReverb
            
            func getPHASESpatialCategory() -> PHASESpatialCategory {
                switch self {
                case .directPathTransmission:
                    return .directPathTransmission
                case .earlyReflections:
                    return .earlyReflections
                case .lateReverb:
                    return .lateReverb
                }
            }
        }
        
        /// Flags used to define the ways the sound will be ouput by the source. Will be set to a normal sound output without reverb by default.
        var spatialFlags: [(categories: SpatialFlag, entries: PHASESpatialPipelineEntry)] = []
        
        /// The way the sound volume will decrease when the listener is farther from the source. By default the distance will be set to 10 meters with a linear decrease of the sound.
        var distanceModelParameters: PHASEGeometricSpreadingDistanceModelParameters
        
        /// The mode of playback for the sound.
        var playbackMode: PHASEPlaybackMode
        
        /// The way the source will act when the listener is more than a certain distance (in meters).
        var cullOption: PHASECullOption
        
        var audioCalibration: (calibrationMode: PHASECalibrationMode, level: Double)
        
        init(
            spatialFlags: [(categories: SpatialFlag, entries: PHASESpatialPipelineEntry)] = [],
            distanceModelParameters: PHASEGeometricSpreadingDistanceModelParameters? = nil,
            playbackMode: PHASEPlaybackMode = .oneShot,
            cullOption: PHASECullOption = .doNotCull,
            audioCalibration: (calibrationMode: PHASECalibrationMode, level: Double) = (.relativeSpl, 0)
        ){
            if let distanceModelParameters = distanceModelParameters {
                self.distanceModelParameters = distanceModelParameters
            } else {
                self.distanceModelParameters = PHASEGeometricSpreadingDistanceModelParameters()
                self.distanceModelParameters.fadeOutParameters =
                PHASEDistanceModelFadeOutParameters(cullDistance: 10) // stops playing if the distance to the listener is more or equal to 10 meters
            }
            self.playbackMode = playbackMode
            self.cullOption = cullOption
            self.audioCalibration = audioCalibration
        }
        
        func getPHASESpatialPipelineFlags() -> PHASESpatialPipeline.Flags {
            let categories = self.spatialFlags.map({$0.categories})
            if categories.contains(.directPathTransmission), categories.contains(.earlyReflections), categories.contains(.lateReverb) {
                return [.directPathTransmission, .earlyReflections, .lateReverb]
            } else if categories.contains(.directPathTransmission) {
                if categories.contains(.earlyReflections) {
                    return [.directPathTransmission, .earlyReflections]
                } else if categories.contains(.lateReverb) {
                    return [.directPathTransmission, .lateReverb]
                } else {
                    return [.directPathTransmission]
                }
            } else if categories.contains(.earlyReflections) {
                if categories.contains(.lateReverb) {
                    return [.earlyReflections, .lateReverb]
                } else {
                    return [.earlyReflections]
                }
            } else if categories.contains(.lateReverb) {
                return [.lateReverb]
            } else {
                return [.directPathTransmission] // PHASESpatialPipeline.Flags has to contain at least one flag so we choose the default one
            }
        }
    }
    
    let engine: PHASEEngine
    let listener: PHASEListener
    
    private let headphonesManager: CMHeadphoneMotionManager
    
    @Published var sounds: [String: Sound] = [:]
    
    @Published private(set) var currentSongPartsConfiguration: SongPartsConfiguration? = nil
        
    private(set) var currentLoop: LoopEvent? = nil
        
    private weak var stopNotificationObserver: NSObjectProtocol? = nil
    
    private var headphoneAvailabilityObserver: NSKeyValueObservation? = nil
    
    private var headphoneTrackingObserver: NSKeyValueObservation? = nil
    
    private(set) var headphonesPosition: CMRotationMatrix? = nil
    
    override init() {
        self.engine = PHASEEngine(updateMode: .automatic)
        self.listener = PHASEListener(engine: self.engine)
        self.listener.transform = matrix_identity_float4x4
        try? self.engine.rootObject.addChild(self.listener) // shouldn't throws as listener doesn't have any other parent
                        
        self.headphonesManager = CMHeadphoneMotionManager()
        super.init()
        
        self.headphonesManager.delegate = self
                        
        if self.headphonesManager.isDeviceMotionAvailable, CMHeadphoneMotionManager.requestAuthorizationStatus() == .authorized {
            self.startHeadphoneTrackingObservation()
        }
        
        self.headphoneAvailabilityObserver = self.headphonesManager.observe(\.isDeviceMotionAvailable, changeHandler: { [weak self] manager, _ in
            guard let self = self else { manager.stopDeviceMotionUpdates(); return }
            if self.headphonesManager.isDeviceMotionAvailable, CMHeadphoneMotionManager.authorizationStatus() == .authorized {
                if self.headphoneTrackingObserver == nil {
                    self.startHeadphoneTrackingObservation()
                }
            } else {
                self.stopHeadphoneTrackingObservation()
            }
        })
                
        self.engine.defaultReverbPreset = .largeChamber
        self.startEngine()
        
        self.stopNotificationObserver = NotificationCenter.default.addObserver(forName: .shouldStopEveryEngineNotification, object: nil, queue: nil, using: { [weak self] _ in
            self?.prepareForDeletion()
        })
    }
    
    /// Load the song into the engine.
    func loadSound(soundPath: String, emittedFromPosition position: simd_float3, options: SoundCharacteristic = .init(), completionHandler handler: ((Result<Sound, Error>) -> Void)? = nil) {
        guard let url = Bundle.main.url(forResource: soundPath, withExtension: nil) else { handler?(.failure("Could not find sound at path: \(soundPath)")); return }
        
        guard self.sounds[soundPath] == nil else { print("Sound already loaded."); return }
        
        let source: PHASESource
        switch createSource(withName: soundPath, atPosition: position) {
        case .success(let createdSource):
            source = createdSource
        case .failure(let error):
            handler?(.failure("Could not create source with name: \(soundPath), error: \(error.localizedDescription)"))
            return
        }
                
        let audioIdentifier: String = url.deletingPathExtension().lastPathComponent
        
        do {
            try engine.assetRegistry.registerSoundAsset(
                url: url, identifier: audioIdentifier, assetType: .resident,
                channelLayout: nil, normalizationMode: .dynamic
            )
        } catch {
            handler?(.failure("Could not register sound (part 1): \(error.localizedDescription)"))
            return
        }
        
        
        // Define the spatial audio behavior
        
        let spatialPipelineFlags : PHASESpatialPipeline.Flags = options.getPHASESpatialPipelineFlags()
        let spatialPipeline = PHASESpatialPipeline(flags: spatialPipelineFlags)! // not nil as defined in SoundCharacteristic
        
        for (parameterType, entry) in options.spatialFlags {
            spatialPipeline.entries[parameterType.getPHASESpatialCategory()]?.sendLevel = entry.sendLevel
            spatialPipeline.entries[parameterType.getPHASESpatialCategory()]?.sendLevelMetaParameterDefinition = entry.sendLevelMetaParameterDefinition
        }

        let spatialMixerDefinition = PHASESpatialMixerDefinition(spatialPipeline: spatialPipeline)
        spatialMixerDefinition.distanceModelParameters = options.distanceModelParameters
        
        let nodeIdentifier = audioIdentifier + "_node"
        
        let samplerNodeDefinition = PHASESamplerNodeDefinition(
            soundAssetIdentifier: audioIdentifier,
            mixerDefinition: spatialMixerDefinition,
            identifier: nodeIdentifier
        )
        
        
        // Create the group
        
        let groupIdentifier = audioIdentifier + "_group"
        
        let soundGroup = PHASEGroup(identifier: groupIdentifier)
        soundGroup.register(engine: self.engine)
        
        samplerNodeDefinition.group = soundGroup
        
        
        // Define the sound playback behavior
        
        samplerNodeDefinition.playbackMode = options.playbackMode
        samplerNodeDefinition.setCalibrationMode(calibrationMode: options.audioCalibration.calibrationMode, level: options.audioCalibration.level)
        samplerNodeDefinition.cullOption = options.cullOption
        
        let anchorName = audioIdentifier + "_anchor"
        
        do {
            try engine.assetRegistry.registerSoundEventAsset(rootNode: samplerNodeDefinition, identifier: anchorName)
        } catch {
            handler?(.failure("Could not register sound (part 2): \(error.localizedDescription)"))
            return
        }
        
        let mixerParameters = PHASEMixerParameters()
        mixerParameters.addSpatialMixerParameters(
            identifier: spatialMixerDefinition.identifier,
            source: source, listener: listener
        )
        
        do {
            let event = try PHASESoundEvent(
                engine: engine, assetIdentifier: anchorName,
                mixerParameters: mixerParameters
            )
            
            Task {
                let audioAsset = AVURLAsset(url: url, options: nil)
                let soundDuration = try? await audioAsset.load(.duration).seconds
                
                guard let soundDuration = soundDuration else { handler?(.failure("Could not get duration of sound, stopping.")); return }
                
                let sound = Sound(
                    event: event,
                    infos: Sound.SoundEventInfos(soundPath: soundPath, soundDuration: soundDuration, assetName: audioIdentifier, anchorName: anchorName),
                    source: source,
                    group: soundGroup
                )
                
                DispatchQueue.main.async {
                    self.sounds.updateValue(sound, forKey: soundPath)
                }
                
                let result = await event.prepare()
                
                if result == .prepared {
                    soundGroup.gain = 0
                    event.resume()
                    await event.seek(to: 0.0) // avoid a weird crash
                    event.pause()
                    soundGroup.gain = 1 // avoid having a little noise during the time it resumes, seeks and pauses.
                    handler?(.success(sound))
                } else {
                    handler?(.failure("Asset preparation failed: \(String(describing: result))"))
                }
            }
            
            return
        } catch {
            handler?(.failure("Could not register event: \(error.localizedDescription)"))
            return
        }
    }
    
    /// Load the song into the engine.
    func loadSound(soundPath: String, emittedFromPosition position: simd_float3, options: SoundCharacteristic = .init()) async -> Result<Sound, Error> {
        return await withCheckedContinuation({ (continuation: CheckedContinuation<Result<Sound, Error>, Never>) in
            loadSound(soundPath: soundPath, emittedFromPosition: position, options: options) { result in
                continuation.resume(returning: result)
            }
        })
    }
    
    /// Will load the song if it isn't already and play it. It is recommended to load the song before calling this method as the loading time is not defined in advance.
    ///
    /// - Warning: Calling this function with a sound that hasn't been loaded previously may have some unwanted behaviors as you can't set options with this method. If you want to be able to set custom options for the sound you should use ``PlaybackManager/loadSound(soundPath:emittedFromPosition:options:completionHandler:)`` instead.
    func playSound(atPosition position: simd_float3 = .init(x: 0, y: 0, z: 0), soundPath: String) {
        if let sound = self.sounds[soundPath] {
            sound.play()
        } else {
            loadSound(soundPath: soundPath, emittedFromPosition: position) { result in
                switch result {
                case .success(let sound):
                    sound.play()
                case .failure(let error):
                    print("Could not load song: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func resume(soundNames: [String]? = nil) {
        // synchronize the sounds
        guard let currentTime = self.sounds.first?.value.timeObserver.currentTime else { return }
        self.seekTo(time: currentTime, soundNames: soundNames)
        
        for soundName in soundNames ?? self.sounds.keys.map({$0}) {
            self.sounds[soundName]?.play()
        }
    }
    
    /// Restart and synchronize the sounds corresponding to the provided names, you can set `soundNames` to nil to synchronize all sounds.
    func restartAndSynchronizeSounds(withNames soundNames: [String]? = nil) {
        pause(soundNames: soundNames)
        seekTo(time: 0.0, soundNames: soundNames)
        resume(soundNames: soundNames)
    }
    
    /// Pause the playback of a sound.
    func pause(soundNames: [String]? = nil) {
        for soundName in soundNames ?? self.sounds.keys.map({$0}) {
            self.sounds[soundName]?.pause()
        }
    }
    
    /// Seek to a certain time (in seconds), if that time is beyond (>) the endTime of the currentLoop (if it's not nil), then it will remove that loop.
    func seekTo(time: Double, soundNames: [String]? = nil) {
        if time > self.currentLoop?.endTime ?? -1 {
            self.removeLoop()
        }
        for soundName in soundNames ?? self.sounds.keys.map({$0}) {
            self.sounds[soundName]?.seek(to: time)
        }
    }
    
    /// Place the loop on the provided soundNames or all the sounds if its value is nil.
    ///
    /// If the endTime of the loop is already behind the currentTime of the first sound in soundNames or in ``PlaybackManager/sounds``, the method will automatically seek to the startTime of the loop.
    func replaceLoop(by loop: LoopEvent, soundNames: [String]? = nil) {
        self.currentLoop = loop
        
        if loop.shouldRestart {
            self.seekTo(time: loop.startTime, soundNames: soundNames)
            self.resume(soundNames: soundNames)
        } else if let currentTime = self.sounds[soundNames?.first ?? UUID().uuidString]?.timeObserver.currentTime ?? self.sounds.first?.value.timeObserver.currentTime, loop.endTime <= currentTime {
            self.seekTo(time: loop.startTime, soundNames: soundNames)
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1 /* lower number => less efficiency */ , repeats: true, block: { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            
            if self.currentLoop?.id != loop.id {
                timer.invalidate()
            } else {
                guard let firstSound = self.sounds[soundNames?.first ?? UUID().uuidString] ?? self.sounds.first?.value else { timer.invalidate(); self.removeLoop(); return }
                guard firstSound.timeObserver.isPlaying else { return /* We don't need to make a system call (costly) to get the current time */ }
                
                if firstSound.timeObserver.currentTime >= loop.endTime {
                    self.seekTo(time: loop.startTime, soundNames: soundNames)
                }
            }
        })
        
        self.update()
    }
    
    /// Remove the current loop.
    func removeLoop() {
        self.currentLoop = nil
        self.update()
    }
    
    /// Override the current SongPartsConfiguration for a new one, put nil if you want to erase the current configuration.
    func changeConfiguration(for configuration: SongPartsConfiguration?) {
        self.currentSongPartsConfiguration = configuration
        self.update()
    }
    
    /// Sounds may have some weird problems at the when they weren't played once, to avoid this, call this function.
    func reloadEngine() async {
        for sound in self.sounds.values {
            sound.gain = 0
            sound.play()
            try? await Task.sleep(nanoseconds: 200_000_000)
            await sound.seek(to: 0.0)
            sound.pause()
            sound.gain = 1
        }
    }
    
    /// Send the objectWillChange notification.
    func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
            
    /// Start the engine.
    private func startEngine() {
        do {
            try self.engine.start()
        } catch {
            print("Could not start engine: \(error.localizedDescription)")
        }
    }
    
    /// Create a source to emit a sound.
    private func createSource(withName name: String, atPosition position: simd_float3) -> Result<PHASESource, Error> {
        guard self.sounds[name] == nil else { return .failure("A source with this name has already been initialized.") }
        
        let mesh = MDLMesh.newIcosahedron(withRadius: 0.08, inwardNormals: false, allocator: nil)
        
        let shape = PHASEShape(engine: engine, mesh: mesh)
        let source = PHASESource(engine: engine, shapes: [shape])
        source.transform = simd_float4x4(position: position)
        do {
            try engine.rootObject.addChild(source)
            return .success(source)
        } catch {
            return .failure("Could not add source to engine: \(error.localizedDescription)")
        }
    }
    
    /// Struct representing a loop in the whole ``PlaybackManager``.
    ///
    /// - Note: You should not place too close ``PlaybackManager/LoopEvent/startTime`` and ``PlaybackManager/LoopEvent/endTime`` as it could introduce some bugs like delays in the ``PlaybackManager/engine`` or graphical bugs in the PlayingBarView.
    struct LoopEvent {
        /// The unique identifier of the loop, should not be set up anywhere else otherwise the timer that controls the loop might have some unknown behaviors.
        let id = UUID()
        
        /// The time when the loop starts in seconds of the track, shoud be less than ``PlaybackManager/LoopEvent/endTime``.
        let startTime: Double
        
        /// The time when the loop ends in seconds of the track, shoud be more than ``PlaybackManager/LoopEvent/startTime``.
        let endTime: Double
        
        /// Boolean indicating whether the playback should get back to the startTime when the loop is activated.
        let shouldRestart: Bool
        
        /// Boolean indicating if the playback can go after the end of the loop, for example when the playing bar's pilule is scrolled after. Setting this option to true will disable the ability to scroll beyond the end of the loop.
        let lockLoopZone: Bool
        
        /// Boolean indicating whether the user can change the loop or not.
        let isEditable: Bool
        
        /// Total duration of the loop.
        var duration: Double {
            return self.endTime - self.startTime
        }
    }
    
    struct SongPartsConfiguration {
        /// If editingMode is on (at least one -1 in the startTimes), you should sort by the part in ascending order and set the "unknown" startTime to -1, otherwise it will be sorted by startTime. Editing mode won't care about values that are not -1 and are preceded by -1 value(s).
        var songParts: [Part] = []
        
        init(songParts: [Part]) {
            self.songParts = songParts
        }
        
        struct Part: Equatable {
            /// Time when this part starts, in seconds.
            ///
            /// - Note: The endtime is the starTime of the part after this one, it there's no part after, the end is the duration of the song.
            var startTime: Double
            
            /// The type of the part.
            var type: PartType
            
            /// Title of the part, will be displayed under the playingbar.
            var label: String = ""
        }
        
        enum PartType: Equatable {
            case themeA, themeB
            case introduction
            case ending
            case bridge
            case pause
            
            case custom(color: CGColor)
        }
    }
    
    private func prepareForDeletion() {
        for (_, sound) in self.sounds {
            sound.deinitialize(from: self)
        }
        self.engine.stop()
        if let stopNotificationObserver = self.stopNotificationObserver {
            self.stopNotificationObserver = nil
            NotificationCenter.default.removeObserver(stopNotificationObserver)
        }
        self.stopHeadphoneTrackingObservation()
        self.headphoneAvailabilityObserver?.invalidate()
    }
        
    deinit {
        self.prepareForDeletion()
    }
}

extension PlaybackManager: CMHeadphoneMotionManagerDelegate {
    func startHeadphoneTrackingObservation() {
        self.headphonesManager.startDeviceMotionUpdates(to: .main, withHandler: { newValue, _ in
            self.headphonesPosition = newValue?.attitude.rotationMatrix
        })
    }
    
    func stopHeadphoneTrackingObservation() {
        if self.headphonesManager.isDeviceMotionActive {
            self.headphonesManager.stopDeviceMotionUpdates()
        }
        self.headphoneTrackingObserver?.invalidate()
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        self.headphonesPosition = nil
    }
    
}
