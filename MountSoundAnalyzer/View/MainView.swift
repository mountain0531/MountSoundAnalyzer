//
//  MainView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/15.
//

import SwiftUI
import Accelerate
import AVFoundation

/// アナライザMainView
struct MainView: View
{
    @StateObject private var devModel = AudioDeviceModel()
    
    @State private var capture: AudioCapture?
    
    @State private var rmsL : Float = -120
    @State private var rmsR : Float = -120
    
    @State private var spectrum: [Float] = .init(repeating: -120, count: 512)

    var body: some View
    {
        VStack(spacing: 20)
        {
            HStack(spacing: 8)
            {
                Picker("Target Device", selection: $devModel.selectedName)
                {
                    ForEach(devModel.devices, id: \.name)
                    {
                        item in
                        Text(item.name).tag(item.name)
                    }
                }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Start")
                {
                    ensureMicPermission
                    {
                        ok in
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
                Button("Stop")
                {
                    try? capture?.stop()
                    capture = nil
                }
            }
                .frame(maxHeight: .infinity, alignment: .leading)
            RMSView(rmsL: $rmsL, rmsR: $rmsR)
            SpectrumView(spectrum: $spectrum)
                .frame(height: 200)
        }
            .padding()
            .onChange(of: devModel.selectedName)
            {
                newName in
                guard
                    let cap = capture,
                    let newID = devModel.devices.first(where: { $0.name == newName })?.id
                else
                {
                    return
                }
                try? cap.changeDevice(newID: newID)
            }
    }
    
    private func startCapture()
    {
        guard
            let id = devModel.devices
                .first(where: { $0.name == devModel.selectedName })?.id
        else
        {
            return
        }
        do
        {
            let cap = try AudioCapture(deviceID: id)
            var fft = FFTAnalyzer(size: 1024)
            cap.sampleHandler =
            {
                lPtr, rPtr, frames in
                let l = rms(lPtr, frames: frames)
                let r = rms(rPtr, frames: frames)
                let spec = fft.analyze(left: lPtr,
                                       right: rPtr,
                                       frames: frames)
                DispatchQueue.main.async
                {
                    rmsL = l
                    rmsR = r
                    spectrum = spec
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
    
    private func rms(_ ptr: UnsafePointer<Float>,
                     frames: UInt32) -> Float
    {
        var meanSq: Float = 0
        vDSP_measqv(ptr, 1, &meanSq, vDSP_Length(frames))
        return 20 * log10(max(sqrt(meanSq), 1.0e-9))
    }
}

func ensureMicPermission(completion: @escaping (Bool) -> Void)
{
    switch AVCaptureDevice.authorizationStatus(for: .audio)
    {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio)
        {
            granted in
            DispatchQueue.main.async { completion(granted) }
        }
        default:
            completion(false)
    }
}
