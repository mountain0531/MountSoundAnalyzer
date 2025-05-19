//
//  MenuView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/13.
//

import SwiftUI

/// メニューバーView
struct MenuView: View
{
    @Environment(\.openWindow) private var openWindow
    var body: some View
    {
        Button("Open MountSoundAnalyzer")
        {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
            .keyboardShortcut("O")
        Button("About MountSoundAnalyzer")
        {
            showAbout()
        }
        Button("Quit MountSoundAnalyzer")
        {
            quitApp()
        }
            .keyboardShortcut("Q")
    }
    
    private func showAbout()
    {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel()
    }
    
    private func quitApp()
    {
        NSApplication.shared.terminate(nil)
    }
}

struct MenuView_Previews: PreviewProvider
{
    static var previews: some View
    {
        MenuView()
    }
}
