//
//  MountSoundAnalyzerApp.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/13.
//

import SwiftUI

@main
struct MountSoundAnalyzerApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuView()
        } label: {
            Image(systemName: "hifispeaker.fill")
        }
        Window("MountSoundAnalyzer", id: "main") {
            MainView()
        }
        .defaultSize(width: 480, height: 320)
        .defaultPosition(.topTrailing)
    }
}
