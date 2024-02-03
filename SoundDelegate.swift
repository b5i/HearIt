//
//  SoundDelegate.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 03.02.2024.
//

import Foundation

protocol SoundDelegate {
    func soundDidChangeMuteStatus(isMuted: Bool)
    
    func soundDidChangeSoloStatus(isSoloed: Bool)
    
    func soundDidChangePlaybackStatus(isPlaying: Bool)
        
    func soundDidSeekTo(time: Double)
    
    func soundDidChangeRate(newRate rate: Double)
    
    func soundDidChangeGain(newGain: Double)
}

extension SoundDelegate { // default methods
    func soundDidChangeMuteStatus(isMuted: Bool) {}
    
    func soundDidChangeSoloStatus(isSoloed: Bool) {}
    
    func soundDidChangePlaybackStatus(isPlaying: Bool) {}
    
    func soundDidChangeRate(newRate rate: Double) {}
    
    func soundDidSeekTo(time: Double) {}
    
    func soundDidChangeGain(newGain: Double) {}
}
