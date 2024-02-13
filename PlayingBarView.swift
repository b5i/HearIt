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
    
    @State private var showZoomedInUI: Bool = false {
        willSet {
            if newValue {
                /*
                if (Double(bars.count) / 2).rounded(.down) + 1 > (self.soundObserver.soundDuration * self.sliderValue) {
                    print("\((self.soundObserver.soundDuration * self.sliderValue) / Double(bars.count))")
                    self.zoomedInSliderValue = (self.soundObserver.soundDuration * self.sliderValue) / Double(bars.count)
                } else if (Double(bars.count) / 2).rounded(.down) + 1 > abs(self.soundObserver.soundDuration * (1 - self.sliderValue)) {
                    self.zoomedInSliderValue = 1 - ((self.soundObserver.soundDuration * (1 - self.sliderValue)) / (Double(bars.count) + 2))
                } else {
                    self.zoomedInSliderValue = 0.5
                }
                self.startedWithZoomedInSliderValue = self.zoomedInSliderValue
                 */

                self.timeWhenStartedSliding = self.soundObserver.currentTime
            } else {
                self.timeWhenStartedSliding = 0.0
            }
            print("newTimeStarted: \(self.timeWhenStartedSliding)")
        }
    }
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
                                self.startedWithZoomedInSliderValue = self.sliderValue
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
    @State private var isSliding: Bool = false {
        willSet {
            withAnimation {
                animatedIsSliding = newValue
            }
        }
    }
    @State private var animatedIsSliding: Bool = false
    @State private var timeWhenStartedSliding: Double = 0.0
    @State private var zoomedInSliderValue: Double = 0.5 // middle of the screen
    @State private var startedWithZoomedInSliderValue: Double = 0.5
    
    @Namespace private var animation
    
    @State private var bars: [Double] = []

    var body: some View {
        VStack {
            currentTimeLabel
                .animation(.spring, value: self.playbackManager.currentLoop == nil)
                .offset(y: self.playbackManager.currentLoop == nil ? 0 : -10)
            HStack {
                playPauseButton
                GeometryReader { geometry in
                    let UNUSED_SPACE: Double = Double(geometry.size.width - 2*sidePadding).truncatingRemainder(dividingBy: barSpacing) / 2
                    let bars: [Double] = (0...Int((geometry.size.width - 2*sidePadding) / barSpacing)).map({Double($0) * barSpacing + sidePadding + abs(sidePadding - UNUSED_SPACE) })
                    //if bars.count + 2 > Int(soundObserver.soundDuration.rounded(.down)) { // as 1 bar = 1 second, we need to set the generation rules manually and ignore the barSpacing
                        
                        //if soundObserver.soundDuration.rounded(.down) > 1.0 {
                            //bars = (1..<Int(((geometry.size.width - 2*sidePadding) / soundObserver.soundDuration.rounded(.down)).rounded(.down))).map({Double($0) *  (geometry.size.width - 2*sidePadding) / soundObserver.soundDuration.rounded(.down)})
                        //} else {
                        //    bars = []
                        //}
                        //print("should never happen")
                         
                    //}
                    VStack(spacing: 0) {
                        LoopView(geometry: geometry, soundObserver: soundObserver, playbackManager: playbackManager)
                            .offset(y: self.showZoomedInUI ? -10 - abs(self.zoomedInHeight - self.zoomedOutHeight) / 2 : -10)
                            .animation(.spring, value: self.playbackManager.currentLoop == nil)
                            .opacity(self.playbackManager.currentLoop == nil ? 0 : 1)
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
                                    .position(x: geometry.size.width / 2, y: 0)
                                if #available(iOS 17.0, *) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.orange)
                                        .sensoryFeedback(.impact(intensity: 0.8), trigger: shouldDoHaptic)
                                        .frame(width: capsuleSize.width, height: capsuleSize.height)
                                        .position(x: 0, y: 0)
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
                                        .position(x: 0, y: 0)
                                        .offset(.init(width: self.showZoomedInUI ? self.zoomedInSliderValue * self.size.width : sliderValue * self.size.width, height: 0))
                                        .onReceive(timer, perform: { _ in
                                            if !self.isSliding, !self.showZoomedInUI, self.soundObserver.isPlaying {
                                                sliderValue = min(soundObserver.currentTime / soundObserver.soundDuration, 1)
                                                //sliderValue = min(sliderValue + 1, self.size.width)
                                            }
                                        })
                                    
                                }
                            }
                            .onAppear {
                                self.size = geometry.size
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged({ newValue in
                                    handleBeginningSwipe(gesture: newValue, bars: bars)
                                })
                                .onEnded({ newValue in
                                    handleEndSwipe(gesture: newValue, bars: bars)
                                })
                        )
                    }
                    .onAppear {
                        self.bars = bars
                    }
                }
            }
        }
        .padding(10)
        .frame(height: 100)
    }
    
    var currentTimeLabel: some View {
        VStack(alignment: .leading) {
            let potentialNewTime = self.isSliding ? min(max(0, self.sound.timeObserver.soundDuration * self.sliderValue + Double(self.bars.count) * (self.zoomedInSliderValue - self.startedWithZoomedInSliderValue)), self.sound.timeObserver.soundDuration) : 0
            
            HStack(spacing: 0) {
                VStack {
                    if animatedIsSliding {
                        Text("\(potentialNewTime.timestampFormatted())")
                            .foregroundStyle(.yellow)
                            .animation(.spring, value: self.animatedIsSliding)
                            .matchedGeometryEffect(id: "yellowTextPlayingBar", in: self.animation)
                    } else {
                        Text("\(potentialNewTime.timestampFormatted())")
                            .foregroundStyle(.clear)
                    }
                    if animatedIsSliding {
                        Text("\(self.soundObserver.currentTime.timestampFormatted())")
                            .foregroundStyle(.white)
                            .opacity(0.5)
                    } else {
                        Text("\(self.soundObserver.currentTime.timestampFormatted())")
                            .foregroundStyle(.white)
                            .animation(.spring, value: self.animatedIsSliding)
                            .matchedGeometryEffect(id: "yellowTextPlayingBar", in: self.animation)
                    }
                }
                VStack {
                    Spacer()
                    Text(" / \(self.soundObserver.soundDuration.timestampFormatted())")
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 43)
        }
        .horizontallyCentered()
    }
    
    var playPauseButton: some View {
        Button {
            if self.sound.timeObserver.isPlaying {
                playbackManager.pause()
            } else {
                playbackManager.resume()
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
    }
    
    func handleBeginningSwipe(gesture: DragGesture.Value, bars: [Double]) {
        if !self.isSliding {
            self.isSliding = true
        }
        if self.showZoomedInUI {
            handleSwipe(gesture: gesture, bars: bars)
        } else if velocityThreshold >= abs(gesture.velocity.width) {
            self.sliderValue = min(max(gesture.location.x, 0) / self.size.width, 1)
            if self.timeSinceVelocityCheck == nil {
                self.timeSinceVelocityCheck = Double(mach_absolute_time()) / 10_000_000
            }
        } else {
            self.sliderValue = min(max(gesture.location.x, 0) / self.size.width, 1)
            self.timeSinceVelocityCheck = nil
        }
    }
    
    func handleEndSwipe(gesture: DragGesture.Value, bars: [Double]) {
        if self.showZoomedInUI {
            handleSwipe(gesture: gesture, bars: bars)
        }
        
        self.isSliding = false
                
        var seekToTime = min(max(0, self.sound.timeObserver.soundDuration * self.sliderValue + Double(self.bars.count) * (self.zoomedInSliderValue - self.startedWithZoomedInSliderValue)), self.sound.timeObserver.soundDuration)
                                        
        if let loop = self.playbackManager.currentLoop, loop.lockLoopZone == true {
            seekToTime = min(seekToTime, loop.endTime)
        }
        
        playbackManager.seekTo(time: seekToTime)
        
        withAnimation {
            self.showZoomedInUI = false
            self.timeSinceVelocityCheck = nil
        }
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
    
    struct LoopView: View {
        let geometry: GeometryProxy
        
        /// Height of the top yellow line.
        var topLineHeight: Double = 7.5
        
        /// Width of the side yellow bars.
        var sideBarsWidth: Double = 7.5
                
        @ObservedObject var soundObserver: Sound.SoundPlaybackObserver
        @ObservedObject var playbackManager: PlaybackManager
        var body: some View {
            let yellow = Color(uiColor: .systemYellow).opacity(0.8)
            
            let loopRectangleSize = CGSize(width: ((self.playbackManager.currentLoop?.endTime ?? 0) - (self.playbackManager.currentLoop?.startTime ?? 0)) / (self.soundObserver.soundDuration + 0.1) * geometry.size.width, height: 20)
            
            let blackRectangleSize = CGSize(width: max(loopRectangleSize.width - 2 * sideBarsWidth, 0), height: max(loopRectangleSize.height - topLineHeight, 0))
            
            HStack(spacing: 0) {
                UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 5, bottomTrailingRadius: 5, topTrailingRadius: 0, style: .continuous)
                    .fill(yellow)
                    .animation(nil, value: loopRectangleSize)
                    .frame(width: sideBarsWidth, height: loopRectangleSize.height)
                    .overlay(alignment: .center, content: { // have a greater hitbox
                        Rectangle()
                            .fill(.clear)
                            .frame(width: sideBarsWidth * 2)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged({ newValue in
                                        handleLeadingLoopChange(gesture: newValue)
                                    })
                                    .onEnded({ newValue in
                                        handleLeadingLoopChange(gesture: newValue)
                                    })
                                )
                    })
                VStack {
                    Rectangle()
                        .fill(yellow)
                        .frame(width: blackRectangleSize.width, height: topLineHeight, alignment: .top)
                    Spacer()
                    
                }
                .frame(height: loopRectangleSize.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged({ newValue in
                                handleTopLoopChange(gesture: newValue)
                        })
                        .onEnded({ newValue in
                            handleTopLoopChange(gesture: newValue)
                        })
                )
                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 5, bottomTrailingRadius: 5, topTrailingRadius: 5, style: .continuous)
                    .fill(yellow)
                    .frame(width: sideBarsWidth, height: loopRectangleSize.height, alignment: .trailing)
                    .overlay(alignment: .center, content: { // have a greater hitbox
                        Rectangle()
                            .fill(.clear)
                            .frame(width: sideBarsWidth * 2)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged({ newValue in
                                        handleTrailingLoopChange(gesture: newValue)
                                    })
                                    .onEnded({ newValue in
                                        handleTrailingLoopChange(gesture: newValue)
                                    })
                                )
                    })
            }
            .frame(width: loopRectangleSize.width)
            .position(x: geometry.size.width * (playbackManager.currentLoop?.startTime ?? 0) / soundObserver.soundDuration + (loopRectangleSize.width / 2))
        }
        
        
        func handleLeadingLoopChange(gesture: DragGesture.Value) {
            guard let currentLoop = self.playbackManager.currentLoop , currentLoop.isEditable else { return }
            
            let newLoop = PlaybackManager.LoopEvent(
                startTime: max(min(self.soundObserver.soundDuration * gesture.translation.width / geometry.size.width + currentLoop.startTime, currentLoop.endTime - 1), 0),
                endTime: currentLoop.endTime,
                shouldRestart: false,
                lockLoopZone: currentLoop.lockLoopZone,
                isEditable: true
            )
            
            self.playbackManager.replaceLoop(by: newLoop)
            
        }
        
        func handleTrailingLoopChange(gesture: DragGesture.Value) {
            guard let currentLoop = self.playbackManager.currentLoop , currentLoop.isEditable else { return }
            
            let newLoop = PlaybackManager.LoopEvent(
                startTime: currentLoop.startTime,
                endTime: min(max(self.soundObserver.soundDuration * gesture.translation.width / geometry.size.width + currentLoop.endTime, currentLoop.startTime + 1), soundObserver.soundDuration),
                shouldRestart: false,
                lockLoopZone: currentLoop.lockLoopZone,
                isEditable: true
            )
            
            self.playbackManager.replaceLoop(by: newLoop)
            
        }
        
        func handleTopLoopChange(gesture: DragGesture.Value) {
            guard let currentLoop = self.playbackManager.currentLoop , currentLoop.isEditable else { return }
            
            var translationValue: Double = gesture.translation.width / geometry.size.width * soundObserver.soundDuration
            
            if gesture.translation.width >= 0 {
                translationValue = min(soundObserver.soundDuration - currentLoop.endTime, translationValue)
            } else {

                
                translationValue = max(translationValue, -currentLoop.startTime)
            }
                        
            let newLoop = PlaybackManager.LoopEvent(
                startTime: currentLoop.startTime + translationValue,
                endTime: currentLoop.endTime + translationValue,
                shouldRestart: false,
                lockLoopZone: currentLoop.lockLoopZone,
                isEditable: true
            )
            
            self.playbackManager.replaceLoop(by: newLoop)
        }
    }
}

extension Double {
    func timestampFormatted() -> String {
        var currentCount = self
        
        let hourPart = (currentCount / 3600).rounded(.down)
        
        currentCount = currentCount.truncatingRemainder(dividingBy: 3600)
        
        let minutesPart = (currentCount / 60).rounded(.down)
        
        currentCount = currentCount.truncatingRemainder(dividingBy: 60)
        
        let seconds = currentCount.rounded(.down)
        
        return "\(hourPart == 0 ? "" : String(Int(hourPart)) + ":")\(Int(minutesPart)):\(seconds < 10 ? "0" + String(Int(seconds)) : String(Int(seconds)))"
    }
}

#Preview {
    ActualSceneView()
}
