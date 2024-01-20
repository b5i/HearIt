//
//  PlaybackManager.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 10.01.2024.
//

import PHASE

class PlaybackManager: ObservableObject {
    static let shared = PlaybackManager()
    
    class Sound {
        struct SoundEventInfos {
            var soundPath: String
            var assetName: String
            var anchorName: String
        }
        
        /// The event that is used to control the basic playback of the sound.
        private let event: PHASESoundEvent
        
        /// The source that can be used to manage the sound emitting properties such as the position in space and more.
        private let source: PHASESource
        
        /// The group of the sound, it comports only one instance of sound, `event`. It can be used to do some more complex operations about the playback.
        private let group: PHASEGroup
        
        /// Infos about the sound, they describe the way the sound is defined in the engine.
        var infos: SoundEventInfos
        
        init(event: PHASESoundEvent, infos: SoundEventInfos, source: PHASESource, group: PHASEGroup) {
            self.event = event
            self.infos = infos
            self.source = source
            self.group = group
        }
        
        // MARK: Sound's properties
        
        func play() { self.event.resume() }
        func pause() { self.event.pause() }
        func restart() { self.seek(to: 0.0); self.event.resume() }
        func seek(to time: Double) { self.event.seek(to: time) }
        
        // MARK: Group's properties
        
        /// Modifies the volume of the sound.
        var gain: Double {
            get {
                return self.group.gain
            } set {
                self.group.gain = newValue
            }
        }
        
        /// Adjusts the volume of the sound gradually.
        func fadeGain(gain: Double, duration: Double, curveType: PHASECurveType) { self.group.fadeGain(gain: gain, duration: duration, curveType: curveType) }
        
        /// The sound playback speed.
        var rate: Double {
            get {
                return self.group.rate
            } set {
                self.group.rate = newValue
            }
        }
        
        /// Adjusts the playback speed of the sound gradually.
        func fadeRate(rate: Double, duration: Double, curveType: PHASECurveType) { self.group.fadeRate(rate: rate, duration: duration, curveType: curveType) }
        
        var isMuted: Bool { 
            get {
                self.group.isMuted
            } set {
                if newValue {
                    self.mute()
                } else {
                    self.unmute()
                }
            }
        }
        var isSoloed: Bool { 
            get {
                self.group.isSoloed
            } set {
                if newValue {
                    self.solo()
                } else {
                    self.unsolo()
                }
            }
        }

        func mute() { self.group.mute() }
        func unmute() { self.group.unmute() }
        func solo() { self.group.solo() }
        func unsolo() { self.group.unsolo() }
        
        // MARK: Source's properties
        
        var position: simd_float3 {
            get {
                return simd_float3(self.source.transform.columns.3.x, self.source.transform.columns.3.y, self.source.transform.columns.3.z)
            } set {
                self.source.transform = simd_float4x4(position: newValue)
            }
        }
        
        /// Remove the source and the soundEvent from the engine's tree.
        /// Unregister a sound from the engine's registry,.
        func deinitialize(from manager: PlaybackManager) {
            manager.sounds.removeValue(forKey: self.infos.soundPath)
            self.event.stopAndInvalidate()
            self.source.parent?.removeChild(self.source)
            self.group.unregisterFromEngine()
            manager.engine.assetRegistry.unregisterAsset(identifier: self.infos.assetName)
            manager.engine.assetRegistry.unregisterAsset(identifier: self.infos.anchorName)
        }
    }
    
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
    
    @Published var sounds: [String: Sound] = [:]
    
    init() {
        self.engine = PHASEEngine(updateMode: .automatic)
        self.listener = PHASEListener(engine: self.engine)
        self.listener.transform = matrix_identity_float4x4
        try! self.engine.rootObject.addChild(self.listener) // todo: remove that force unwrap
        
        self.engine.defaultReverbPreset = .largeChamber
        self.startEngine()
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
        
        let samplerNodeDefinition = PHASESamplerNodeDefinition(
            soundAssetIdentifier: audioIdentifier,
            mixerDefinition: spatialMixerDefinition
        )
        
        
        // Create the group
        
        let groupIdentifier = audioIdentifier + "_group"
        
        let soundGroup = PHASEGroup(identifier: groupIdentifier)
        soundGroup.register(engine: self.engine)
        
        samplerNodeDefinition.group = self.engine.groups[groupIdentifier]
        
        
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
            
            let sound = Sound(
                event: event,
                infos: Sound.SoundEventInfos(soundPath: soundPath, assetName: audioIdentifier, anchorName: anchorName),
                source: source,
                group: soundGroup
            )
            
            DispatchQueue.main.async {
                self.sounds.updateValue(sound, forKey: soundPath)
            }

            event.prepare(completion: { reason in
                if reason == .prepared {
                    handler?(.success(sound))
                } else {
                    handler?(.failure("Asset preparation failed: \(reason)"))
                }
            })
            
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
    
    /// Restart and synchronize the sounds corresponding to the provided names, you can set `soundNames` to nil to synchronize all sounds.
    func restartAndSynchronizeSounds(withNames soundNames: [String]? = nil) {
        let actualSoundNames: [String]
        
        if let soundNames = soundNames {
            actualSoundNames = soundNames
        } else {
            actualSoundNames = self.sounds.keys.map({$0})
        }
        for soundName in actualSoundNames {
            self.pause(soundPath: soundName)
            self.seekTo(time: 0.0, soundPath: soundName)
        }
        for soundName in actualSoundNames {
            self.playSound(soundPath: soundName)
        }
    }
    
    /// Pause the playback of a sound.
    func pause(soundPath: String) {
        self.sounds[soundPath]?.pause()
    }
    
    /// Seek to a certain time (in seconds).
    func seekTo(time: Double, soundPath: String) {
        self.sounds[soundPath]?.seek(to: time)
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
        
    deinit {
        for (_, sound) in self.sounds {
            sound.deinitialize(from: self)
        }
        self.engine.stop()
        // engine will automatically be removed
    }
}

extension simd_float4x4 {
    init(position: simd_float3) {
        self = matrix_identity_float4x4
        self.columns.3 = simd_float4(position, 1)
    }
}
