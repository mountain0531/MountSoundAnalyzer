//
//  TestView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/14.
//

import SwiftUI
import Accelerate
import AVFoundation

struct TestView: View {
    @State private var capture: AudioCapture?
    @State private var level : Float = -120

    var body: some View {
        VStack(spacing: 20) {
            Text(String(format: "%.1f dBFS", level))
                .font(.title2)
                .monospacedDigit()

            HStack {
                Button("Start") {
                    ensureMicPermission { ok in
                        guard
                            ok
                        else
                        {
                            return
                        }
                        DispatchQueue.main.async
                        {
                            startCapture()
                        }
                    }
                }

                Button("Stop") {
                    try? capture?.stop()
                    capture = nil
                }
            }
        }
        .padding()
    }
    
    private func startCapture()
    {
        do
        {
            let cap = try AudioCapture(deviceName: "BlackHole 64ch")
            cap.sampleHandler = { samples, frames, ch in
                DispatchQueue.main.async {
                    level = rms(samples, frames * ch)
                }
            }
            try cap.start()
            capture = cap
        }
        catch
        {
            print(error)
        }
    }
    
    private func rms(_ ptr: UnsafePointer<Float>, _ n: UInt32) -> Float {
        let buf = UnsafeBufferPointer(start: ptr, count: Int(n))
        let rms = vDSP.rootMeanSquare(buf)
        return 20 * log10(max(rms, 1.0e-9))
        
    }
}

func ensureMicPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
        completion(true)                        // すでに許可
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    default:                                   // .denied / .restricted
        completion(false)
    }
}
