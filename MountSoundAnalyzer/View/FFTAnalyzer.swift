//
//  FFTAnalyzer.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/19.
//

import Accelerate

struct FFTAnalyzer
{
    private let n: Int
    
    private var window: [Float]
    /// FFT セットアップ
    private var setup: vDSP.FFT<DSPSplitComplex>
    
    private var mono:  [Float]
    private var inputReal:  [Float]
    private var inputImag:  [Float]
    private var outputReal:  [Float]
    private var outputImag:  [Float]

    init(size: Int = 1024)
    {
        n = size
        window = vDSP.window(ofType: Float.self,
                             usingSequence: .hanningDenormalized,
                             count: n,
                             isHalfWindow: false)

        setup = vDSP.FFT(log2n: vDSP_Length(log2(Double(n))),
                         radix: .radix2,
                         ofType: DSPSplitComplex.self)!

        mono       = .init(repeating: 0, count: n)
        inputReal  = .init(repeating: 0, count: n/2)
        inputImag  = .init(repeating: 0, count: n/2)
        outputReal  = .init(repeating: 0, count: n/2)
        outputImag  = .init(repeating: 0, count: n/2)
    }

    /// L/R バッファ → パワースペクトル[dB]（長さ n/2）
    mutating func analyze(left:  UnsafePointer<Float>,
                          right: UnsafePointer<Float>,
                          frames: UInt32) -> [Float]
    {
        let m = min(Int(frames), n)

        vDSP_vadd(left,
                  1,
                  right,
                  1,
                  &mono,
                  1,
                  vDSP_Length(m))
        var scale: Float = 1.0 / sqrt(2)
        vDSP_vsmul(mono,
                   1,
                   &scale,
                   &mono,
                   1,
                   vDSP_Length(m))

        if
            m < n
        {
            mono.replaceSubrange(m..<n,
                                 with: repeatElement(Float.zero, count: n - m))
        }
        
        vDSP.multiply(mono,
                      window,
                      result: &mono)
        
        inputReal.withUnsafeMutableBufferPointer
        {
            inputRealPtr in
            inputImag.withUnsafeMutableBufferPointer
            {
                inputImagPtr in
                outputReal.withUnsafeMutableBufferPointer
                {
                    outputRealPtr in
                    outputImag.withUnsafeMutableBufferPointer
                    {
                        outputImagPtr in
                        var inputSplit = DSPSplitComplex(realp: inputRealPtr.baseAddress!,
                                                         imagp: inputImagPtr.baseAddress!)
                        var outputSplit = DSPSplitComplex(realp: outputRealPtr.baseAddress!,
                                                          imagp: outputImagPtr.baseAddress!)
                        
                        mono.withUnsafeBytes
                        {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)), toSplitComplexVector: &inputSplit)
                        }
                        setup.forward(input: inputSplit,
                                      output: &outputSplit)
                    }
                }
            }
        }
        
        var power = [Float](repeating: 0, count: n/2)
        outputReal.withUnsafeBufferPointer
        {
            outputRealPtr in
            outputImag.withUnsafeBufferPointer
            {
                outputImagPtr in
                var split = DSPSplitComplex(realp: UnsafeMutablePointer(mutating: outputRealPtr.baseAddress!),
                                            imagp: UnsafeMutablePointer(mutating: outputImagPtr.baseAddress!))
                
                vDSP_zvmags(&split,
                            1,
                            &power,
                            1,
                            vDSP_Length(n/2))
            }
        }
        
        // windowingに対する補正
        let coherentGain: Float = 0.5
        let coherentGainInv = 1.0 / coherentGain
        vDSP_vsmul(power,
                   1,
                   [coherentGainInv * coherentGainInv],
                   &power,
                   1,
                   vDSP_Length(n/2))
        
        // FFT長に対する正規化
        let scaleFFT: Float = 4.0 / Float(n * n)
        vDSP_vsmul(power,
                   1,
                   [scaleFFT],
                   &power,
                   1,
                   vDSP_Length(n/2))
        
        // P_ref = 1.0とする(dbFS)
        var spectrumDB = [Float](repeating: 0, count: n/2)
        var one: Float = 1.0
        vDSP_vdbcon(power,
                    1,
                    &one,
                    &spectrumDB,
                    1,
                    vDSP_Length(n/2), 1)  // 10*log10()

        return spectrumDB
    }
}
