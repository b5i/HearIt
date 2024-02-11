//
//  ContentView.swift
//  PlaybackBar
//
//  Created by Antoine Bollengier on 22.01.2024.
//

import SwiftUI

struct PlayingBarView: View {
    let playbackManager: PlaybackManager
    let sound: Sound
    @ObservedObject var soundObserver: Sound.SoundPlaybackObserver
    
    //var endOfSlideAction: (_ sliderValue: Double) -> () // action that will be called when the user stops scrolling
    //var endOfZoomAction: (_ sliderValue: Double, _ zoomedInSliderValue: Double) -> () // action that will be called when the zoomed in UI disappear
    
    var capsuleSize: CGSize = .init(width: 10, height: 30) // the size of the cursor
    var magnetForce: Double = 1 // points that the user has to swipe in order to get out of the magnet
    var barWidth: Double = 1.5 // bar size on each side of it
    var barSpacing: Double = 50 // the spacing between the bars, should never be 0
    var sidePadding: Double = 25 // the padding on the sides of the playingBar
    var zoomedInHeight: Double = 50 // the height of the playing bar when it is zoomed in
    var zoomedOutHeight: Double = 20 // the height of the playing bar when it is zoomed out
    var velocityThreshold: Double = 15 // the maximum velocity to show the zoomed in UI
    var timeThreshold: Double = 0.9 // the time the user has to stay under the velocityThreshold to show the zoomed in UI
    
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    
    @State private var sliderValue: Double = 0
    
    /*@Binding var externalSliderValue: Double {
        didSet {
            sliderValue = externalSliderValue
        }
    }*/
    //@Binding var isPlaying: Bool
    
    @State private var showZoomedInUI: Bool = false
    @State private var size: CGSize = .zero
    @State private var shouldDoHaptic: Bool = false
    @State private var isMagnetedTo: CGFloat?
    @State private var timeSinceVelocityCheck: Double? {
        didSet {
            if let newValue = self.timeSinceVelocityCheck {
                Task {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(self.timeThreshold) * 1_000_000_000)
                        if self.timeSinceVelocityCheck == newValue {
                            DispatchQueue.main.async {
                                self.zoomedInSliderValue = self.sliderValue
                                print("open big view")
                                withAnimation {
                                    self.showZoomedInUI = true
                                }
                                self.timeSinceVelocityCheck = nil
                            }
                        }
                    } catch {
                        print("Could not sleep: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    @State private var isSliding: Bool = false
    @State private var zoomedInSliderValue: Double = 0.5 // middle of the screen

    var body: some View {
        HStack {
            Button {
                if self.sound.timeObserver.isPlaying {
                    playbackManager.pause()
                    //sound.pause()
                } else {
                    playbackManager.resume()
                    //sound.play()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(.white)
                        .opacity(0.3)
                        .frame(width: 55, height: zoomedInHeight)
                    Image(systemName: self.soundObserver.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundStyle(.white)
                        .padding(10)
                }
            }
            .frame(width: 55, height: zoomedInHeight)
            .padding(.horizontal)
            GeometryReader { geometry in
                let UNUSED_SPACE: Double = Double(geometry.size.width - 2*sidePadding).truncatingRemainder(dividingBy: barSpacing) / 2
                let bars: [Double] = (0...Int((geometry.size.width - 2*sidePadding) / barSpacing)).map({Double($0) * barSpacing + sidePadding + abs(sidePadding - UNUSED_SPACE) })
                Group {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(showZoomedInUI ? Color(uiColor: .darkGray) : .gray)
                            .frame(height: showZoomedInUI ? zoomedInHeight : zoomedOutHeight)
                            .overlay(alignment: .center, content: {
                                ZStack {
                                    ZStack {
                                        ForEach(Array(bars.enumerated()), id: \.offset) { bar in
                                            let bar = bar.element
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(self.isMagnetedTo == bar ? .orange : .gray)
                                                .frame(width: barWidth * 2, alignment: .center)
                                                .position(x: 0, y: showZoomedInUI ? capsuleSize.height / 2 : zoomedOutHeight / 2)
                                                .offset(x: bar)
                                        }
                                    }
                                    .frame(height: showZoomedInUI ? capsuleSize.height : 0, alignment: .center)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(showZoomedInUI ? Color(uiColor: .darkGray) : .gray)
                                        .frame(width: showZoomedInUI ? 0 : sliderValue * self.size.width, height: showZoomedInUI ? zoomedInHeight : zoomedOutHeight)
                                        .position(x: showZoomedInUI ? 10 : sliderValue * self.size.width / 2, y: showZoomedInUI ? 25 : 10)
                                        .opacity(showZoomedInUI ? 0 : 5)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(showZoomedInUI ? Color(uiColor: .darkGray) : .gray)
                                        .frame(width: showZoomedInUI ? 0 : max(geometry.size.width - sliderValue * geometry.size.width - capsuleSize.width, 0), height: showZoomedInUI ? zoomedInHeight : zoomedOutHeight)
                                        .position(x: showZoomedInUI ? geometry.size.width - 10 : (sliderValue * geometry.size.width + capsuleSize.width + geometry.size.width) / 2, y: showZoomedInUI ? 25 : 10)
                                        .opacity(showZoomedInUI ? 0 : 5)
                                }
                            })
                        if #available(iOS 17.0, *) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.orange)
                                .sensoryFeedback(.impact(intensity: 0.8), trigger: shouldDoHaptic)
                                .frame(width: capsuleSize.width, height: capsuleSize.height)
                                .position(x: 0, y: geometry.size.height / 2)
                                .offset(.init(width: self.showZoomedInUI ? self.zoomedInSliderValue * self.size.width : sliderValue * self.size.width, height: 0))
                                .onReceive(timer, perform: { _ in
                                    if !self.isSliding, !self.showZoomedInUI, self.soundObserver.isPlaying {
                                        sliderValue = min(soundObserver.currentTime / soundObserver.soundDuration, 1)
                                        //sliderValue = min(sliderValue + 1, self.size.width)
                                    }
                                })
                        } else { // no haptic feedback \:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.orange)
                                .frame(width: capsuleSize.width, height: capsuleSize.height)
                                .position(x: 0, y: geometry.size.height / 2)
                                .offset(.init(width: self.showZoomedInUI ? self.zoomedInSliderValue * self.size.width : sliderValue * self.size.width, height: 0))
                                .onReceive(timer, perform: { _ in
                                    if !self.isSliding, !self.showZoomedInUI, self.soundObserver.isPlaying {
                                        sliderValue = min(soundObserver.currentTime / soundObserver.soundDuration, 1)
                                        //sliderValue = min(sliderValue + 1, self.size.width)
                                    }
                                })
                             
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        self.size = geometry.size
                        print(self.size)
                        print(bars)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged({ newValue in
                            self.isSliding = true
                            //print(newValue.location.x)
                            //print(bars)
                            //print(newValue.velocity.width)
                            if self.showZoomedInUI {
                                handleSwipe(gesture: newValue, bars: bars)
                            } else if velocityThreshold >= abs(newValue.velocity.width) {
                                self.sliderValue = min(max(newValue.location.x, 0) / self.size.width, 1)
                                if self.timeSinceVelocityCheck == nil {
                                    self.timeSinceVelocityCheck = Double(mach_absolute_time()) / 10_000_000
                                }
                            } else {
                                self.sliderValue = min(max(newValue.location.x, 0) / self.size.width, 1)
                                self.timeSinceVelocityCheck = nil
                            }
                        })
                        .onEnded({ newValue in
                            if self.showZoomedInUI {
                                handleSwipe(gesture: newValue, bars: bars)
                            }
                            
                            self.isSliding = false

                            //DispatchQueue.global(qos: .background).async {
                            
                            print("sliderValue: \(sliderValue), self.sound.timeObserver.soundDuration: \(self.sound.timeObserver.soundDuration), self.sound.timeObserver.soundDuration * sliderValue = \(self.sound.timeObserver.soundDuration * sliderValue). self.zoomedInSliderValue = \(self.zoomedInSliderValue), 10 * (self.zoomedInSliderValue - 0.5) = \(10 * (self.zoomedInSliderValue - 0.5))")
                            
                            var seekToTime = min(max(0, self.sound.timeObserver.soundDuration * self.sliderValue + 10 * (self.zoomedInSliderValue - 0.5)), self.sound.timeObserver.soundDuration)
                            
                            if let loop = self.playbackManager.currentLoop, loop.lockLoopZone == true {
                                seekToTime = min(seekToTime, loop.endTime)
                            }
                            
                            playbackManager.seekTo(time: seekToTime)
                            
                            //sound.seek(to: max(0, sound.timeObserver.soundDuration * sliderValue + 10 * (zoomedInSliderValue - 0.5)))
                            
                            self.zoomedInSliderValue = 0.5 // "middle" of the zoomedI bar
                            
                            withAnimation {
                                self.showZoomedInUI = false
                                self.timeSinceVelocityCheck = nil
                            }
                        })
                )
            }
        }
        .padding(10)
    }
    
    func handleSwipe(gesture: DragGesture.Value, bars: [Double]) {
        let potentialNewSliderValue = max(0, min(gesture.location.x, self.size.width))
        if let isMagnetedTo = self.isMagnetedTo {
            if potentialNewSliderValue - capsuleSize.width >= isMagnetedTo && potentialNewSliderValue - capsuleSize.width - isMagnetedTo >= magnetForce { // the capsule goes behind the bar
                
                self.isMagnetedTo = nil
                
                self.zoomedInSliderValue = potentialNewSliderValue / self.size.width
            } else if potentialNewSliderValue + capsuleSize.width <= isMagnetedTo && isMagnetedTo - potentialNewSliderValue - capsuleSize.width >= magnetForce { // the capsule goes beyond the bar
                
                self.zoomedInSliderValue = potentialNewSliderValue / self.size.width
                
                self.isMagnetedTo = nil
            }
        } else {
            let potentialLeftBar = bars.last(where: {$0 <= potentialNewSliderValue})
            let potentialRightBar = bars.first(where: {$0 >= potentialNewSliderValue})
            guard gesture.velocity.width <= 50 else {
                self.isMagnetedTo = nil
                self.zoomedInSliderValue = potentialNewSliderValue / self.size.width
                return
            }
            if let potentialLeftBar = potentialLeftBar, abs(potentialNewSliderValue - potentialLeftBar) <= magnetForce {
                if gesture.velocity.width != 0 {
                    withAnimation(.spring(duration: abs(self.zoomedInSliderValue * self.size.width - potentialLeftBar) / gesture.velocity.width)) {
                        self.isMagnetedTo = potentialLeftBar
                        self.zoomedInSliderValue = potentialLeftBar / self.size.width
                    }
                } else {
                    self.isMagnetedTo = potentialLeftBar
                    self.zoomedInSliderValue = potentialLeftBar / self.size.width
                }
                self.shouldDoHaptic.toggle()
            } else if let potentialRightBar = potentialRightBar, abs(potentialNewSliderValue - potentialRightBar) <= magnetForce {
                if gesture.velocity.width != 0 {
                    withAnimation(.spring(duration: abs(self.zoomedInSliderValue * self.size.width - potentialRightBar) / gesture.velocity.width)) {
                        self.isMagnetedTo = potentialRightBar
                        self.zoomedInSliderValue = potentialRightBar / self.size.width
                    }
                } else {
                    self.isMagnetedTo = potentialRightBar
                    self.zoomedInSliderValue = potentialRightBar / self.size.width
                }
                self.shouldDoHaptic.toggle()
            } else {
                self.isMagnetedTo = nil
                self.zoomedInSliderValue = potentialNewSliderValue / self.size.width
            }
        }
    }
}
