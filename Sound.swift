//
//  Sound.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 07.02.2024.
//

import PHASE
import Combine

class Sound {
    struct SoundEventInfos {
        var soundPath: String
        var soundDuration: Double
        var assetName: String
        var anchorName: String
        
        weak var musician: Musician? = nil
        weak var musiciansManager: MusiciansManager? = nil
        weak var playbackManager: PlaybackManager? = nil
    }
    
    /// The event that is used to control the basic playback of the sound.
    private let event: PHASESoundEvent
    
    /// The source that can be used to manage the sound emitting properties such as the position in space and more.
    private let source: PHASESource
    
    /// The group of the sound, it comports only one instance of sound, `event`. It can be used to do some more complex operations about the playback.
    private let group: PHASEGroup
    
    /// A model that is used to get the current time of the playback.
    let timeObserver: SoundPlaybackObserver
    
    /// Infos about the sound, they describe the way the sound is defined in the engine.
    var infos: SoundEventInfos
    
    /// A handler function that, when set up, will be called multiple times a second.
    ///
    /// - Note: This handler can be defined for example if you want the sound to behave in a special way, e.g if the musician's status should change when the sound is playing.
    var timeHandler: ((Sound) -> ())?
    
    var delegate: SoundDelegate?
                            
    init(event: PHASESoundEvent, infos: SoundEventInfos, source: PHASESource, group: PHASEGroup, timeHandler: ((Sound) -> ())? = nil, delegate: SoundDelegate? = nil) {
        self.event = event
        self.infos = infos
        self.source = source
        self.group = group
        self.timeObserver = SoundPlaybackObserver(soundDuration: infos.soundDuration)
        self.timeHandler = timeHandler
        self.delegate = delegate
    }
    
    // MARK: Sound's properties
    
    func play() {
        self.event.seek(to: self.timeObserver.currentTime) { _ in
            self.event.resume()
            self.timeObserver.resume()
            self.delegate?.soundDidChangePlaybackStatus(isPlaying: true)
        }
        Timer.scheduledTimer(withTimeInterval: 0.7 /* should be more than the animation time (currently 0.5s) */, repeats: true, block: { [weak self] timer in
            guard let self = self, self.timeObserver.isPlaying else { timer.invalidate(); return }
            
            self.timeHandler?(self)
        })
        //self.event.resume()
        //self.timeObserver.resume()
        //self.delegate?.soundDidChangePlaybackStatus(isPlaying: true)
    }
    
    func pause() {
        self.event.pause()
        self.timeObserver.pause()
        self.delegate?.soundDidChangePlaybackStatus(isPlaying: false)
        
        self.timeHandler?(self)
    }
    
    func restart() { self.seek(to: 0.0); self.play() }
    
    func seek(to time: Double) {
        self.event.seek(to: time) { _ in
            self.timeObserver.seek(to: time)
            self.delegate?.soundDidSeekTo(time: time)
            
            self.timeHandler?(self)
        }
    }
    
    func seek(to time: Double) async {
        _ = await withCheckedContinuation({ (continuation: CheckedContinuation<Bool, Never>) in
            self.event.seek(to: time, completion: { _ in
                self.timeObserver.seek(to: time)
                self.delegate?.soundDidSeekTo(time: time)
                
                self.timeHandler?(self)
                continuation.resume(returning: true)
            })
        })
    }
    
    // MARK: Group's properties
    
    /// Modifies the volume of the sound.
    var gain: Double {
        get {
            return self.group.gain
        } set {
            self.group.gain = newValue
            self.delegate?.soundDidChangeGain(newGain: newValue)
        }
    }
    
    /// Adjusts the volume of the sound gradually.
    func fadeGain(gain: Double, duration: Double, curveType: PHASECurveType) { self.group.fadeGain(gain: gain, duration: duration, curveType: curveType); self.delegate?.soundDidChangeGain(newGain: gain) }
    
    /// The sound playback speed.
    var rate: Double {
        get {
            return self.group.rate
        } set {
            self.group.rate = newValue
            self.timeObserver.setRate(newValue)
            self.delegate?.soundDidChangeRate(newRate: rate)
        }
    }
    
    /// Adjusts the playback speed of the sound gradually.
    func fadeRate(rate: Double, duration: Double, curveType: PHASECurveType) { self.group.fadeRate(rate: rate, duration: duration, curveType: curveType); self.delegate?.soundDidChangeRate(newRate: rate) }
    
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

    func mute() { self.group.mute(); self.delegate?.soundDidChangeMuteStatus(isMuted: true) }
    func unmute() { self.group.unmute(); self.delegate?.soundDidChangeMuteStatus(isMuted: false) }
    func solo() { self.group.solo(); self.delegate?.soundDidChangeSoloStatus(isSoloed: true) }
    func unsolo() { self.group.unsolo(); self.delegate?.soundDidChangeSoloStatus(isSoloed: false) }
    
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
    
    class SoundPlaybackObserver: ObservableObject {
        var currentTime: Double {
            get {
                if self.startedAt != -1 {
                    return (self.secondsPlayed + max((Double(Date().timeIntervalSince1970) - self.startedAt), 0) * self.rate).truncatingRemainder(dividingBy: self.soundDuration)
                } else { // paused
                    return self.secondsPlayed.truncatingRemainder(dividingBy: self.soundDuration)
                }
            }
        }
        
        var soundDuration: Double {
            return actualSoundDuration * Double(durationMultiplier)
        }
        
        private let actualSoundDuration: Double
        
        /// Multiplier that will mulitply itself to the actualSoundDuration to give the soundDuration.
        var durationMultiplier: UInt = 1
        
        private(set) var isPlaying: Bool = false {
            didSet {
                print("newValue: \(isPlaying)")
            }
        }

        private var secondsPlayed: Double = 0.0
        
        private var startedAt: Double = -1
        
        private var rate: Double = 1.0
        
        private var updateTimer: AnyCancellable?
        
        init(soundDuration: Double) {
            self.actualSoundDuration = soundDuration
            self.updateTimer = Timer.publish(every: 0.1, on: .main, in: .default)
                                    .autoconnect()
                                    .sink(receiveValue: { _ in
                                        self.update()
                                    })
        }
        
        fileprivate func resume() {
            guard !self.isPlaying else { return }
            
            self.startedAt = Double(Date().timeIntervalSince1970)
            self.isPlaying = true
            self.update()
        }
        
        fileprivate func pause() {
            guard self.isPlaying else { return }
            
            self.secondsPlayed += (Double(Date().timeIntervalSince1970) - self.startedAt) * self.rate
            self.startedAt = -1
            self.isPlaying = false
            self.update()
        }
        
        fileprivate func setRate(_ rate: Double) {
            guard self.rate != rate else { return }
        
            // Add to self.secondsPlayed all the time it has been playing with the rate.
            let currentTime: Double = Double(Date().timeIntervalSince1970)
            self.secondsPlayed += (currentTime - self.startedAt) * self.rate
            self.startedAt = currentTime
            
            self.rate = rate
            self.update()
        }
        
        fileprivate func seek(to time: Double) {
            self.secondsPlayed = time
            
            self.startedAt = self.isPlaying ? Double(Date().timeIntervalSince1970) : -1
            self.update()
        }
        
        private func update() {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}
