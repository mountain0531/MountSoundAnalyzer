//
//  RMSView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/15.
//

import SwiftUI

struct RMSView: View
{
    @Binding var rmsL: Float
    @Binding var rmsR: Float
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Text(String(format: "L: %.1f dBFS | R: %.1f dBFS", rmsL, rmsR))
                .font(.title2)
                .monospacedDigit()
        }
        
    }
}
