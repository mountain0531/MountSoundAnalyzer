//
//  AudioDeviceModel.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/15.
//

import CoreAudio

final class AudioDeviceModel: ObservableObject {
    @Published var devices: [(name: String, id: AudioDeviceID)] = []
    @Published var selectedName: String = ""

    init()
    {
        refresh()
        if
            let first = devices.first
        {
            selectedName = first.name
        }
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                               mScope: kAudioObjectPropertyScopeGlobal,
                                               mElement: kAudioObjectPropertyElementMain)
         AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &addr, nil)
        {
            _, _ in
            DispatchQueue.main.async { self.refresh() }
         }
    }

    func refresh()
    {
        devices = (try? AudioCapture.listLoopbackCapableDevices()) ?? []
        if
            !devices.contains(where: { $0.name == selectedName }),
        let first = devices.first { selectedName = first.name }
    }
}
