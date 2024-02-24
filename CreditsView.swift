//
//  CreditsView.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import SwiftUI

struct CreditsViewModifier: ViewModifier {
    static let credits: [CreditContents] = [
        CreditContents(url: URL(string: "https://github.com/tracyhenry-visionOS/GenerativeDoodleArt_VisionOS")!, object: "Musician's 3D model: Wenbo Tao & Tassilo von Gerlach", author: "Wenbo Tao & Tassilo von Gerlach, modified by myself for the needs of the project", license: """
                                                     MIT License
                                                     
                                                     Copyright (c) 2023 Wenbo Tao & Tassilo von Gerlach
                                                     
                                                     Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                                                     
                                                     The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                                                     
                                                     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                                                     """
                      ),
        CreditContents(url: URL(string: "https://en.wikipedia.org/wiki/Public_domain_music")!, object: "Bolero and Mozart arrangements: Rapahël Bollengier", author: "Raphaël Bollengier", license: """
                                                     Raphaël created the arrangements from public domain music only, he granted the permission to \(appName) to use them. The sounds from the app have been created with Logic Pro X by myself from those arrangements.
                                                     """
                      )
    ]
    
    @Binding var isActive: Bool
    
    @State private var creditContentsShown: Bool = false {
        willSet {
            if !newValue {
                let currentCreditContents = self.creditContents
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    if self.creditContents == currentCreditContents {
                        self.creditContents = nil
                    }
                })
            }
        }
    }
    @State private var creditContents: CreditContents?
    func body(content: Content) -> some View {
        ZStack {
            Rectangle()
                .fill(.black)
                .ignoresSafeArea()
            content
                .blur(radius: isActive ? 50 : 0)
                .overlay(alignment: .center, content: {
                    GeometryReader { geometry in
                        if isActive {
                            ZStack {
                                Rectangle()
                                    .fill(.black.opacity(0.4))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .onTapGesture {
                                        withAnimation {
                                            isActive = false
                                        }
                                    }
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(.white, lineWidth: 3)
                                    .background(RoundedRectangle(cornerRadius: 30).fill(.black.opacity(0.5)))
                                    .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.3)
                                TabView(selection: $creditContentsShown, content: {
                                    VStack {
                                        Text("Credits")
                                            .font(.title)
                                            .foregroundStyle(.white)
                                            .bold()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .padding(.top)
                                            .padding(.leading)
                                            .padding(.leading)
                                        Text("All the app has been created by myself except some of the sounds and 3D models as listed under this notice. Click on the credit text to see more details.")
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                            .padding(.leading)
                                            .padding(.leading)
                                        ForEach(Array(Self.credits.enumerated()), id: \.offset) { _, credit in
                                            HStack {
                                                Image(systemName: "arrow.right")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundStyle(.white)
                                                    .frame(width: 15, height: 15)
                                                Text(credit.object)
                                                    .foregroundStyle(.white)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                                    .onTapGesture {
                                                        self.creditContents = credit
                                                        withAnimation {
                                                            self.creditContentsShown = true
                                                        }
                                                    }
                                            }
                                        }
                                        .padding(.leading)
                                        .padding(.leading)
                                    }
                                    .tag(false)
                                    if let credit = creditContents {
                                        CreditView(credit: credit)
                                            .tag(true)
                                            .id(creditContents?.license ?? UUID().uuidString)
                                    }
                                })
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(width: geometry.size.width * 0.75, height: geometry.size.width * 0.3)
                                .overlay(alignment: .topTrailing, content: {
                                    Group {
                                        Image(systemName: "multiply")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(.white)
                                            .padding(.top)
                                            .padding(.top, 5)
                                            .padding(.trailing)
                                            .padding(.trailing)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isActive = false
                                        }
                                    }
                                })
                                .padding()
                                .padding()
                            }
                        }
                    }
                })
        }
    }
    
    struct CreditView: View {
        let credit: CreditContents
        var body: some View {
            VStack {
                Link(destination: credit.url, label: {
                    HStack {
                        Text("Open in WebView")
                            .foregroundStyle(.white)
                        Image(systemName: "arrow.up.right")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 15, height: 15)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 40, alignment: .leading)
                })
                Text("Author(s): \(credit.author)")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView {
                    Text("License: \n \(credit.license)")
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
        }
    }
    
    struct CreditContents: Equatable {
        let url: URL
        let object: String
        let author: String
        let license: String
    }
}

extension View {
    func creditsOverlay(isActive: Binding<Bool>) -> some View {
        self.modifier(CreditsViewModifier(isActive: isActive))
    }
}
