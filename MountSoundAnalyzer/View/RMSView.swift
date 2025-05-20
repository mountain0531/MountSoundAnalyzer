//
//  RMSView.swift
//  MountSoundAnalyzer
//
//  Created by mountain on 2025/05/15.
//

import SwiftUI

private let FLOOR: Float = -60
private let CEIL : Float =   0
private let BAR_W: CGFloat = 18
private let TICK_W: CGFloat = 6
private let NUM_W : CGFloat = 26

struct LevelBar: View
{
    let rms: Float
    
    var body: some View
    {
        GeometryReader
        {
            geo in
            let frac = CGFloat((max(FLOOR, min(CEIL, rms)) - FLOOR) / (CEIL - FLOOR))
            ZStack(alignment: .bottom)
            {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.85))
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: rms))
                    .frame(height: geo.size.height * frac)
            }
        }
            .animation(.linear(duration: 0.05), value: rms)
    }
    
    private func barColor(for v: Float)
    -> Color
    {
        switch v
        {
            case -3...CEIL:
                return .red
            case -6...(-3):
                return .orange
            case -12...(-6):
                return .yellow
            default:
                return .mint
        }
    }
}

struct TickScale: View
{
    var body: some View
    {
        GeometryReader
        {
            geo in
            Canvas
            {
                ctx, size in
                let tTotal = Float(Int(CEIL) - Int(FLOOR))
                for v in stride(from: Int(CEIL),
                                through: Int(FLOOR),
                                by: -1)
                {
                    let frac = CGFloat((Float(Int(CEIL) - v)) / tTotal)
                    let y = frac * size.height
                    let major = v % 5 == 0
                    var p = Path()
                    p.move(to: .init(x: 0, y: y))
                    p.addLine(to: .init(x: major ? TICK_W : TICK_W * 0.6, y: y))
                    ctx.stroke(p,
                               with: .color(Color.gray.opacity(major ? 0.95 : 0.6)),
                               lineWidth: 1)
                }
            }
        }
            .frame(width: TICK_W)
            .allowsHitTesting(false)
    }
}

struct NumberScale: View
{
    enum Side
    {
        case leading,
             trailing
    }
    let side: Side
    var body: some View
    {
        GeometryReader
        {
            geo in
            Canvas
            {
                ctx, size in
                let total = Float(Int(CEIL) - Int(FLOOR))
                for v in stride(from: Int(CEIL),
                                through: Int(FLOOR),
                                by: -5)
                {
                    let frac = CGFloat((Float(Int(CEIL) - v)) / total)
                    var y = frac * size.height
                    if
                        v == Int(CEIL)
                    {
                        y += 4
                    }
                    if
                        v == Int(FLOOR)
                    {
                        y -= 4
                    }
                    let txt = Text("\(v)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white)
                    ctx.draw(txt,
                             at: .init(x: side == .leading ? size.width : 0,
                                  y: y),
                             anchor: side == .leading ? .trailing : .leading)
                }
            }
        }
            .frame(width: NUM_W)
    }
}

struct ChannelMeter: View
{
    enum ChannelSide
    {
        case left,
             right
    }
    let rms: Float
    let label: String
    let side: ChannelSide

    var body: some View
    {
        HStack(spacing: 0)
        {
            if side == .left
            {
                NumberScale(side: .leading)
            }
            if side == .right
            {
                LevelBar(rms: rms).frame(width: BAR_W)
            }
            TickScale()
            if side == .left
            {
                LevelBar(rms: rms).frame(width: BAR_W)
            }
            if side == .right
            {
                NumberScale(side: .trailing)
            }
        }
            .overlay(Text(label)
                        .font(.caption)
                        .foregroundColor(.white)
                        .offset(y: 16),
                     alignment: .bottom)
    }
}

struct RMSView: View
{
    @Binding var rmsL: Float
    @Binding var rmsR: Float

    var body: some View
    {
        VStack(spacing: 6)
        {
            HStack
            {
                Text(String(format: "%5.1f dB", rmsL))
                Spacer()
                Text(String(format: "%5.1f dB", rmsR))
            }
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.white)

            // メータ本体
            HStack(spacing: 8)
            {
                ChannelMeter(rms: rmsL, label: "L", side: .left)
                ChannelMeter(rms: rmsR, label: "R", side: .right)
            }
                .frame(maxHeight: .infinity)
        }
            .padding(20)
            .background(Color.black.opacity(0.6))
            .cornerRadius(4)
    }
}
