//
//  AudioCapture.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/13.
//
import CoreAudio
import AudioToolbox

final class AudioCapture
{
    // MARK: Enumuration
    enum CaptureError: Error
    {
        case noComponent,
             noUnit,
             deviceNotFound,
             osStatus(OSStatus)
    }
    // MARK: TypeAlias
    typealias SampleHandler =
    (_ samples: UnsafePointer<Float>,
     _ frames: UInt32,
     _ channels: UInt32) -> Void
    
    // MARK: Public
    var sampleHandler: SampleHandler?
    
    private(set) var deviceID: AudioDeviceID
    
    // MARK: Private
    private var audioUnit: AudioUnit?
    
    private static let renderCallback: AURenderCallback =
    {
        inRef, ioFlags, ts, bus, nFrames, _ in

        let cap = Unmanaged<AudioCapture>.fromOpaque(inRef).takeUnretainedValue()
        
        var bufList = AudioBufferList.allocate(maximumBuffers: 2)
        defer { free(bufList.unsafeMutablePointer) }

        guard
            let au = cap.audioUnit
        else
        {
            return noErr
        }
        
        let err = AudioUnitRender(au,
                                  ioFlags,
                                  ts,
                                  1,
                                  nFrames,
                                  bufList.unsafeMutablePointer)
        guard
            err == noErr
        else
        {
            return err
        }

        if
            let handler = cap.sampleHandler
        {
            let buf = bufList[0]  // ch 0
            handler(buf.mData!.assumingMemoryBound(to: Float.self),
                    nFrames,
                    UInt32(bufList.count))
        }
        return noErr
    }
    
    // MARK: Initialize / Deinitialize
    init(deviceName: String,
         handler: SampleHandler? = nil)
    throws
    {
        self.sampleHandler = handler
        self.deviceID = try Self.lookUpDeviceID(name: deviceName)
        self.audioUnit = try Self.makeAudioUnit(deviceID: deviceID, ref: self)
    }
    
    deinit
    {
        if
            let au = audioUnit
        {
            AudioComponentInstanceDispose(au)
        }
    }
    
    // MARK: Function
    func start()
    throws
    {
        guard
            let au = audioUnit
        else
        {
            throw CaptureError.noUnit
        }
        try AudioOutputUnitStart(au).check()
    }
    
    func stop()
    throws
    {
        guard
            let au = audioUnit
        else
        {
            throw CaptureError.noUnit
        }
        try AudioOutputUnitStop(au).check()
    }
    
    func changeDevice(name: String)
    throws
    {
        let newID = try Self.lookUpDeviceID(name: name)
        guard
            let au = audioUnit
        else
        {
            throw CaptureError.noUnit
        }

        try stop()
        
        try AudioUnitUninitialize(au).check()
        
        var dev = newID
        try AudioUnitSetProperty(au,
                                 kAudioOutputUnitProperty_CurrentDevice,
                                 kAudioUnitScope_Global,
                                 0,
                                 &dev,
                                 UInt32(MemoryLayout.size(ofValue: dev))).check()
        
        try AudioUnitInitialize(au).check()
        
        try start()
        
        deviceID = newID
    }
    
    private static func makeAudioUnit(
        deviceID: AudioDeviceID,
        ref: AudioCapture
    )
    throws -> AudioUnit
    {
        var description = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                    componentSubType: kAudioUnitSubType_HALOutput,
                                                    componentManufacturer: kAudioUnitManufacturer_Apple,
                                                    componentFlags: 0,
                                                    componentFlagsMask: 0)
        guard
            let component = AudioComponentFindNext(nil, &description)
        else
        {
            throw CaptureError.noComponent
        }
        
        var auOpt: AudioUnit?
        try AudioComponentInstanceNew(component, &auOpt).check()
        guard
            let au = auOpt
        else
        {
            throw CaptureError.noComponent
        }
        
        var flag: UInt32 = 1
        try AudioUnitSetProperty(au,
                                 kAudioOutputUnitProperty_EnableIO,
                                 kAudioUnitScope_Input,
                                 1,
                                 &flag,
                                 UInt32(MemoryLayout.size(ofValue: flag))).check()
        
        flag = 0
        try AudioUnitSetProperty(au,
                                 kAudioOutputUnitProperty_EnableIO,
                                 kAudioUnitScope_Output,
                                 0,
                                 &flag,
                                 UInt32(MemoryLayout.size(ofValue: flag))).check()
        var dev = deviceID
        try AudioUnitSetProperty(au,
                                 kAudioOutputUnitProperty_CurrentDevice,
                                 kAudioUnitScope_Global,
                                 0,
                                 &dev,
                                 UInt32(MemoryLayout.size(ofValue: dev))).check()
        
        var cb = AURenderCallbackStruct(inputProc: renderCallback,
                                        inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(ref).toOpaque()))
        try AudioUnitSetProperty(au,
                                 kAudioOutputUnitProperty_SetInputCallback,
                                 kAudioUnitScope_Global,
                                 0,
                                 &cb,
                                 UInt32(MemoryLayout.size(ofValue: cb))).check()
        
        var streamDesc = AudioStreamBasicDescription(mSampleRate: 48_000,
                                                     mFormatID: kAudioFormatLinearPCM,
                                                     mFormatFlags: kLinearPCMFormatFlagIsFloat |
                                                                   kAudioFormatFlagIsPacked |
                                                                   kAudioFormatFlagIsNonInterleaved,
                                                     mBytesPerPacket: 4,
                                                     mFramesPerPacket: 1,
                                                     mBytesPerFrame: 4,
                                                     mChannelsPerFrame: 2,      // 必要な ch 数
                                                     mBitsPerChannel: 32,
                                                     mReserved: 0)

        try AudioUnitSetProperty(au,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Output,      // ← AUHAL では *Output* scope が「入力側」
                                 1,                           //   bus = 1 (input element)
                                 &streamDesc,
                                 UInt32(MemoryLayout.size(ofValue: streamDesc))).check()
        
        try AudioUnitInitialize(au).check()
        return au
    }
    
    private static func lookUpDeviceID(name: String)
    throws -> AudioDeviceID
    {
        var size: UInt32 = 0
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)

        try AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                            &addr,
                                            0,
                                            nil,
                                            &size).check()

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids   = [AudioDeviceID](repeating: 0, count: count)

        try AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                       &addr,
                                       0,
                                       nil,
                                       &size,
                                       &ids).check()

        for id in ids
        {
            var nSize: UInt32 = 0
            var nAddr = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                                   mScope: kAudioObjectPropertyScopeGlobal,
                                                   mElement: kAudioObjectPropertyElementMain)
            try AudioObjectGetPropertyDataSize(id, &nAddr, 0, nil, &nSize).check()
            var cfName = "" as CFString
            try AudioObjectGetPropertyData(id, &nAddr, 0, nil, &nSize, &cfName).check()
            if
                (cfName as String) == name
            {
                return id
            }
        }
        throw CaptureError.deviceNotFound
    }
}

private extension OSStatus
{
    @inline(__always)
    func check()
    throws
    {
        if
            self != noErr
        {
            throw AudioCapture.CaptureError.osStatus(self)
        }
    }
}
