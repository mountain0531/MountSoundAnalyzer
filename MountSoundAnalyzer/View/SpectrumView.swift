//
//  SpectramView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/15.
//

import SwiftUI

struct SpectrumView: View {
    @Binding var spectrum: [Float]

    var dbFloor: Float = -120
    var dbCeil:  Float =   0
    var fs: Double = 48_000

    private let marginL:  CGFloat = 40
    private let marginR:  CGFloat = 10
    private let marginT:  CGFloat = 10
    private let marginB:  CGFloat = 30
    private let axisColor = Color.gray.opacity(0.35)

    var body: some View
    {
        GeometryReader
        {
            geo in
            Canvas
            {
                ctx, size in
                guard
                    spectrum.count > 1
                else
                {
                    return
                }
                
                let plotW = size.width  - marginL - marginR
                let plotH = size.height - marginB - marginT
                let plotOrigin = CGPoint(x: marginL, y: marginT)

                let dbSpan = dbCeil - dbFloor
                for db in stride(from: dbCeil,
                                 through: dbFloor,
                                 by: -20)
                {
                    let normY = CGFloat((db - dbFloor) / dbSpan)
                    let yPlot = plotH * (1 - normY) + plotOrigin.y

                    var hLine = Path()
                    hLine.move(to: CGPoint(x: plotOrigin.x,
                                           y: yPlot))
                    hLine.addLine(to: CGPoint(x: plotOrigin.x + plotW,
                                              y: yPlot))
                    ctx.stroke(hLine,
                               with: .color(axisColor),
                               lineWidth: 0.6)

                    let lbl = Text("\(Int(db))")
                        .font(.caption2)
                        .foregroundColor(.white)
                    ctx.draw(lbl,
                             at: CGPoint(x: marginL - 4, y: yPlot),
                             anchor: .trailing)
                }

                let freqTicks: [Double] = [50,
                                           100,
                                           200,
                                           500,
                                           1_000,
                                           2_000,
                                           5_000,
                                           10_000,
                                           20_000]

                for f in freqTicks
                {
                    let xPlot = xPos(forFreq: f, width: plotW) + plotOrigin.x

                    var vLine = Path()
                    vLine.move(to: CGPoint(x: xPlot,
                                           y: plotOrigin.y))
                    vLine.addLine(to: CGPoint(x: xPlot,
                                              y: plotOrigin.y + plotH))
                    ctx.stroke(vLine,
                               with: .color(axisColor),
                               lineWidth: 0.5)

                    let txt = f >= 1_000 ? "\(Int(f/1_000))k" : "\(Int(f))"
                    let lbl = Text(txt)
                        .font(.caption2)
                        .foregroundColor(.white)
                    ctx.draw(lbl,
                             at: CGPoint(x: xPlot, y: plotOrigin.y + plotH + 6),
                             anchor: .top)
                }

                var path = Path()
                for (i, db) in spectrum.enumerated()
                {
                    let freq = Double(i) / Double(spectrum.count - 1) * fs / 2
                    let x = xPos(forFreq: freq, width: plotW) + plotOrigin.x
                    let normY = max(min((db - dbFloor) / dbSpan, 1), 0)
                    let y = plotH * (1 - CGFloat(normY)) + plotOrigin.y

                    (i == 0)
                        ? path.move(to: CGPoint(x: x, y: y))
                        : path.addLine(to: CGPoint(x: x, y: y))
                }
                ctx.stroke(path, with: .color(.green), lineWidth: 1.2)
            }
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    //== 対数軸 (10 Hz–Nyquist) での X 位置計算 ============
    private func xPos(forFreq f: Double,
                      width: CGFloat)
    -> CGFloat
    {
        let fMin = 10.0
        let fMax = fs / 2
        let pos  = log10(max(f, fMin) / fMin) / log10(fMax / fMin)
        return width * CGFloat(pos)
    }
}
