//
//  MenuView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/13.
//

import SwiftUI

struct MenuView: View {
    private var menuNameArray = ["Menu1", "Menu2", "Menu3"]
    
    var body: some View {
        ForEach (menuNameArray, id: \.self) { menuName in
            Button {
                
            } label: {
                Image(systemName: "person.fill")
                Text(menuName)
            }
        }
        Divider()
        Button("Settings...") {
            
        }
        .keyboardShortcut(",")
        Button("About MountSoundAnalyzer") {
            showAbout()
        }
        Button("Quit MountSoundAnalyzer") {
            quitApp()
        }
        .keyboardShortcut("Q")
    }
    
    private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel()
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
