//
//  MountSoundAnalyzerApp.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/13.
//

import SwiftUI

@main
struct MountSoundAnalyzerApp: App {
//    var body: some Scene {
//        MenuBarExtra {
//            MenuView()
//        } label: {
//            Image(systemName: "message.fill")
//            Text("10件")
//        }
//    }
    var body: some Scene {
        WindowGroup {
            TestView()
        }
            // Core Audio は録音扱いなのでマイク権限を Info.plist に追加:
            // NSMicrophoneUsageDescription = "Sound capture for spectrum analyzer"
    }
}
