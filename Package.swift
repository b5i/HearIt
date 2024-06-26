// swift-tools-version: 5.8

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Hear it!",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Hear it!",
            targets: ["AppModule"],
            bundleIdentifier: "Antoine-Bollengier.HearIt",
            teamIdentifier: "QDH78FDX85",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .camera(purposeString: "To display the alternative AR experience of the app!"),
                .motion(purposeString: "To use your AirPods' position from the screen and offer an even more spatial audio experience.")
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .copy("Resources/TutorialSounds"),
                .copy("Resources/ThemesSounds"),
                .copy("Resources/BoleroSounds"),
                .copy("Resources/musicPlayingParticleTexture.png"),
                .copy("Resources/mutedParticleTexture.png"),
                .copy("Resources/art.scnassets")
            ]
        )
    ]
)
