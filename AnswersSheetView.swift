//
//  AnswersSheetView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 17.02.2024.
//

import SwiftUI

struct AnswersSheetView: View {
    @ObservedObject private var AM = AnswersModel.shared
    var body: some View {
        Group {
            if let answersView = AM.answersView {
                AnyView(answersView.view)
            } else {
                Color.clear.frame(width: 0, height: 0)
                    .onAppear {
                        AM.hideButton()
                    }
            }
        }
    }
}

class AnswersModel: ObservableObject {
    static let shared = AnswersModel()
    
    @Published private(set) var shouldShowButton: Bool = false
    
    @Published var showSheet: Bool = false
    
    @Published private(set) var answersView: (any LevelAnswers)? = nil
    
    func showButton(answersView: any LevelAnswers) {
        self.answersView = answersView
        self.showSheet = false
        withAnimation {
            self.shouldShowButton = true
        }
    }
    
    func hideButton() {
        self.answersView = nil
        withAnimation {
            self.showSheet = false
            self.shouldShowButton = false
        }
    }
}

protocol LevelAnswers {
    associatedtype AnswersView: View
    
    var view: AnswersView { get }
}

#Preview {
    AnswersSheetView()
}

struct AnswersOverlayViewModifier: ViewModifier {
    @State private var showAnswersSpoilWarning: Bool = true
    
    @ObservedObject private var AM = AnswersModel.shared
    func body(content: Content) -> some View {
        content
            .blur(radius: AM.showSheet ? 50 : 0)
            .overlay(alignment: .center, content: {
                GeometryReader { geometry in
                    if AM.showSheet {
                        ZStack {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onTapGesture {
                                    withAnimation {
                                        AM.showSheet = false
                                    }
                                }
                            RoundedRectangle(cornerRadius: 30)
                                .strokeBorder(.white, lineWidth: 3)
                                .background(RoundedRectangle(cornerRadius: 30).fill(.black.opacity(0.5)))
                                .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.2)
                            
                                .overlay(alignment: .topTrailing, content: {
                                    Image(systemName: "multiply")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(.white)
                                        .onTapGesture {
                                            withAnimation {
                                                AM.showSheet = false
                                            }
                                        }
                                        .padding(.top)
                                        .padding(.top)
                                        .padding(.trailing)
                                        .padding(.trailing)
                                })
                            GeometryReader { localGeometry in
                                ZStack {
                                    VStack {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: showAnswersSpoilWarning ? 40 : 0)
                                            Text("Answers warning")
                                                .font(.title)
                                                .foregroundStyle(.white)
                                        }
                                        Text("Are you sure that you want to see the answers?")
                                            .foregroundStyle(.white)
                                        HStack {
                                            Button {
                                                withAnimation {
                                                    AM.showSheet = false
                                                }
                                            } label: {
                                                Text("No")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            Button {
                                                withAnimation(.smooth) {
                                                    showAnswersSpoilWarning = false
                                                }
                                            } label: {
                                                Text("Yes")
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                    .frame(width: localGeometry.size.width)
                                    .offset(x: showAnswersSpoilWarning ? 0 : -localGeometry.size.width * 2)
                                    AnswersSheetView()
                                        .frame(width: localGeometry.size.width)
                                        .offset(x: showAnswersSpoilWarning ? localGeometry.size.width * 2 : 0)
                                        .onDisappear {
                                            self.showAnswersSpoilWarning = true // TODO: maybe we should only reset it once the level is finished?
                                        }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                            .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.2)
                            .clipped()
                        }
                    }
                }
            })
    }
}

extension View {
    func answersOverlay() -> some View {
        self.modifier(AnswersOverlayViewModifier())
    }
}
