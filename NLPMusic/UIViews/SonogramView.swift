//
//  SonogramView.swift
//  vkmusic
//
//  Created by Ярослав Стрельников on 28.02.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

// MARK : - OSX & iOS compatibilty
#if os(OSX)
import AppKit

public typealias WaveImage = NSImage
public typealias WaveColor = NSColor
public var mainScreenScale:CGFloat = 1

#elseif os(iOS)

import UIKit

public typealias WaveImage = UIImage
public typealias WaveColor = UIColor
public var mainScreenScale = UIScreen.main.scale

extension WaveColor {
    
    // Cocoa Touch to Cocoa adaptation
    func highlight(withLevel: CGFloat) -> WaveColor? {
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let brightnessAdjustment: CGFloat = withLevel
        let adjustmentModifier: CGFloat = brightness < brightnessAdjustment ? 1 : -1
        let newBrightness = brightness + brightnessAdjustment * adjustmentModifier
        return WaveColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}


#endif


// MARK : - Enums

/**
 Position of the drawn waveform:
 - **top**: Draws the waveform at the top of the image, such that only the bottom 50% are visible.
 - **top**: Draws the waveform in the middle the image, such that the entire waveform is visible.
 - **bottom**: Draws the waveform at the bottom of the image, such that only the top 50% are visible.
 */
public enum WaveformPosition: Int {
    case top    = -1
    case middle =  0
    case bottom =  1
}

/**
 Style of the waveform which is used during drawing:
 - **filled**: Use solid color for the waveform.
 - **gradient**: Use gradient based on color for the waveform.
 - **striped**: Use striped filling based on color for the waveform.
 */
public enum WaveformStyle {
    case filled
    case gradient
    case striped(period:Int)
}



// MARK : - WaveformConfiguration
/// Allows customization of the waveform output image.
public struct WaveformConfiguration {
    /// Desired output size of the waveform image, works together with scale.
    let size: CGSize
    
    /// Color of the waveform, defaults to black.
    let color: WaveColor
    
    /// Background color of the waveform, defaults to clear.
    let backgroundColor: WaveColor
    
    /// Waveform drawing style, defaults to .gradient.
    let style: WaveformStyle
    
    /// Waveform drawing position, defaults to .middle.
    let position: WaveformPosition
    
    /// Scale to be applied to the image, defaults to main screen's scale.
    let scale: CGFloat
    
    // Should we draw a border. If borderWidth == the border is ignored
    let borderWidth:CGFloat
    
    // Border color
    let borderColor:WaveColor
    
    /// Optional padding or vertical shrinking factor for the waveform.
    let paddingFactor: CGFloat?
    
    // Draw a central line (used to represent the current time position)
    public var drawCentraLine: Bool = false
    public var centralLineWidth: CGFloat = 2 // The width of the central line
    public var centralLineColor: WaveColor = WaveColor.red // Its color
    public init(size: CGSize,
                color: WaveColor = WaveColor.red,
                backgroundColor: WaveColor = WaveColor.clear,
                style: WaveformStyle = .gradient,
                position: WaveformPosition = .middle,
                scale: CGFloat = mainScreenScale,
                borderWidth:CGFloat = 0,
                borderColor:WaveColor = WaveColor.white,
                paddingFactor: CGFloat? = nil
    ) {
        self.color = color
        self.backgroundColor = backgroundColor
        self.style = style
        self.position = position
        self.size = size
        self.scale = scale
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.paddingFactor = paddingFactor
    }
}

// MARK : - WaveFormDrawer

open class WaveFormDrawer {
    
    public static func image(with sampling:(samples: [Float], sampleMax: Float) , and configuration: WaveformConfiguration) -> WaveImage? {
#if os(OSX)
        if let context = NSGraphicsContext.current{
            // Let's use an Image
            let image = NSImage(size: configuration.size)
            image.lockFocus()
            context.shouldAntialias = true
            self._drawBackground(on: context.cgContext, with: configuration)
            self._drawGraph(from: sampling, on: context.cgContext, with: configuration)
            if configuration.borderWidth > 0 {
                self._drawBorder(on: context.cgContext, with: configuration)
            }
            self._drawTheCentralLine(on: context.cgContext, with: configuration)
            return image
        }else{
            // Let's draw Off screen
            NSGraphicsContext.saveGraphicsState()
            if let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                          pixelsWide: Int(configuration.size.width),
                                          pixelsHigh: Int(configuration.size.height),
                                          bitsPerSample: 8,
                                          samplesPerPixel: 4,
                                          hasAlpha: true,
                                          isPlanar: false,
                                          colorSpaceName: NSColorSpaceName.calibratedRGB,
                                          bytesPerRow: 4  * Int(configuration.size.width),
                                          bitsPerPixel: 32){
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
                let context = NSGraphicsContext.current!
                context.shouldAntialias = true
                self._drawBackground(on: context.cgContext, with: configuration)
                context.saveGraphicsState()
                self._drawGraph(from: sampling, on: context.cgContext, with: configuration)
                context.restoreGraphicsState()
                if configuration.borderWidth > 0 {
                    self._drawBorder(on: context.cgContext, with: configuration)
                }
                self._drawTheCentralLine(on: context.cgContext, with: configuration)
                let image = NSImage(size: configuration.size)
                image.addRepresentation(rep)
                NSGraphicsContext.restoreGraphicsState()
                return image
                
            }
            return nil
        }
#elseif os(iOS)
        UIGraphicsBeginImageContextWithOptions(configuration.size, false, configuration.scale)
        if let context = UIGraphicsGetCurrentContext(){
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            self._drawBackground(on: context, with: configuration)
            context.saveGState()
            self._drawGraph(from: sampling, on: context, with: configuration)
            context.restoreGState()
            if configuration.borderWidth > 0 {
                self._drawBorder(on: context, with: configuration)
            }
            self._drawTheCentralLine(on: context, with: configuration)
            let graphImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return graphImage
        }
        return nil
#endif
    }
    
    private static func _drawBackground(on context: CGContext, with configuration: WaveformConfiguration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
    }
    
    private static func _drawBorder(on context: CGContext, with configuration: WaveformConfiguration) {
        let path = CGMutablePath()
        let radius:CGFloat = 0
        let rect = CGRect(origin: CGPoint.zero, size: configuration.size)
        context.setStrokeColor(configuration.borderColor.cgColor)
        context.setLineWidth(configuration.borderWidth)
        path.move(to:CGPoint(x:  rect.minX, y:  rect.maxY))
        path.addArc(tangent1End: CGPoint(x:  rect.minX, y:  rect.minY), tangent2End: CGPoint(x:  rect.midX, y:  rect.minY), radius: radius)
        path.addArc(tangent1End: CGPoint(x:  rect.maxX, y:  rect.minY), tangent2End: CGPoint(x:  rect.maxX, y:  rect.midY), radius: radius)
        path.addArc(tangent1End: CGPoint(x:  rect.maxX, y:  rect.maxY), tangent2End: CGPoint(x:  rect.midX, y:  rect.maxY), radius: radius)
        path.addArc(tangent1End: CGPoint(x:  rect.minX, y:  rect.maxY), tangent2End: CGPoint(x:  rect.minX, y:  rect.midY), radius: radius)
        context.addPath(path)
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    
    private static func _drawTheCentralLine(on context: CGContext, with configuration: WaveformConfiguration){
        guard configuration.drawCentraLine else { return }
        let path = CGMutablePath()
        let startingPoint = CGPoint(x: (CGFloat(context.width) / 2) - configuration.centralLineWidth, y: 0)
        let endPoint =  CGPoint(x: startingPoint.x , y: CGFloat(context.height))
        context.setStrokeColor(configuration.centralLineColor.cgColor)
        context.setLineWidth(configuration.centralLineWidth)
        path.move(to: startingPoint)
        path.addLine(to: endPoint)
        context.addPath(path)
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    private static func _drawGraph(from sampling:(samples: [Float], sampleMax: Float),
                                   on context: CGContext,
                                   with configuration: WaveformConfiguration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let graphCenter = graphRect.size.height / 2.0
        let positionAdjustedGraphCenter = graphCenter + CGFloat(configuration.position.rawValue) * graphCenter
        let verticalPaddingDivisor = configuration.paddingFactor ?? CGFloat(configuration.position == .middle ? 2.5 : 1.5)
        let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
        let minimumGraphAmplitude: CGFloat = 2 // we want to see at least a 1pt line for silence
        let path = CGMutablePath()
        var maxAmplitude: CGFloat = CGFloat(sampling.sampleMax / SamplesExtractor.noiseFloor ) // we know 1 is our max in normalized data, but we keep it 'generic'
        context.setLineWidth(1.0 / configuration.scale)
        for (x, sample) in sampling.samples.enumerated() {
            let xPos = CGFloat(x) / configuration.scale
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
            maxAmplitude = max(drawingAmplitude, maxAmplitude)
            switch configuration.style {
            case .striped(let period):
                if (Int(xPos) % period == 0) {
                    path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
                    path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
                }
            default:
                path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
                path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
            }
        }
        context.addPath(path)
        
        switch configuration.style {
        case .filled, .striped:
            context.setStrokeColor(configuration.color.cgColor)
            context.strokePath()
        case .gradient:
            context.replacePathWithStrokedPath()
            context.clip()
            let highlightedColor = configuration.color.highlight(withLevel: 0.5) ?? WaveColor.lightGray
            let colors = NSArray(array: [
                configuration.color.cgColor,
                highlightedColor.cgColor
            ]) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: positionAdjustedGraphCenter - maxAmplitude),
                                       end: CGPoint(x: 0, y: positionAdjustedGraphCenter + maxAmplitude),
                                       options: .drawsAfterEndLocation)
        }
    }
}

public enum SamplesExtractorError: Error {
    case assetNotFound
    case audioTrackNotFound
    case audioTrackMediaTypeMissMatch(mediatype: AVMediaType)
    case readingError(message: String)
    case extractionHasFailed
}


public struct SamplesExtractor {
    
    
    public fileprivate(set) static var outputSettings: [String : Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsNonInterleaved: false
    ]
    
    public static var noiseFloor: Float = -50.0 // everything below -X dB will be clipped
    
    /// Samples a sound track
    /// There is no guarantee you will obtain exactly the  desired number of samples
    /// You can compensate in your drawing logic
    ///
    ///
    /// - Parameters:
    ///   - audioTrack: the audio track
    ///   - timeRange: the sampling timerange
    ///   - desiredNumberOfSamples: the desired number of samples
    ///   - onSuccess: the success handler with the samples and the sampleMax
    ///   - onFailure: the failure handler with a contextual error
    ///   - identifiedBy: an optional identifier to be used to support multiple consumers.
    public static func samples( audioTrack: AVAssetTrack,
                                timeRange: CMTimeRange?,
                                desiredNumberOfSamples: Int = 100,
                                onSuccess: @escaping (_ samples: [Float], _ sampleMax: Float,_ identifier: String?)->(),
                                onFailure: @escaping (_ error:Error,_ identifier: String?)->(),
                                identifiedBy: String? = nil){
        do{
            guard let asset = audioTrack.asset else {
                throw SamplesExtractorError.assetNotFound
            }
            let assetReader = try AVAssetReader(asset: asset)
            if let timeRange = timeRange{
                assetReader.timeRange = timeRange
            }
            
            guard audioTrack.mediaType == .audio else {
                throw SamplesExtractorError.audioTrackMediaTypeMissMatch(mediatype: audioTrack.mediaType)
            }
            
            let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: SamplesExtractor.outputSettings)
            assetReader.add(trackOutput)
            
            SamplesExtractor._extract( samplesFrom: assetReader,
                                       asset: assetReader.asset,
                                       track: audioTrack,
                                       downsampledTo: desiredNumberOfSamples,
                                       onSuccess: {samples, sampleMax in
                switch assetReader.status {
                case .completed:
                    onSuccess(self._normalize(samples), sampleMax, identifiedBy)
                default:
                    onFailure(SamplesExtractorError.readingError(message:" reading waveform audio data has failed \(assetReader.status)"), identifiedBy)
                }
            }, onFailure: { error in
                onFailure(error, identifiedBy)
            })
            
        }catch{
            onFailure(error,identifiedBy)
        }
    }
    
    
    fileprivate static func _extract( samplesFrom reader: AVAssetReader,
                                      asset: AVAsset,
                                      track:AVAssetTrack,
                                      downsampledTo desiredNumberOfSamples: Int,
                                      onSuccess: @escaping (_ samples: [Float], _ sampleMax: Float)->(),
                                      onFailure: @escaping (_ error:Error)->()){
        
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded:
                guard
                    let formatDescriptions = track.formatDescriptions as? [CMAudioFormatDescription],
                    let audioFormatDesc = formatDescriptions.first,
                    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
                else { break }
                
                
                var sampleMax:Float = -Float.infinity
                
#if os(OSX)
                let positiveInfinity = kCMTimePositiveInfinity
#else
                let positiveInfinity = CMTime.positiveInfinity
#endif
                
                // By default the reader's timerange is set to CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)
                // So if duration == kCMTimePositiveInfinity we should use the asset duration
                let duration:Double = (reader.timeRange.duration == positiveInfinity) ? Double(asset.duration.value) : Double(reader.timeRange.duration.value)
                let timscale:Double = (reader.timeRange.duration == positiveInfinity) ? Double(asset.duration.timescale) :Double(reader.timeRange.start.timescale)
                
                let numOfTotalSamples = (asbd.pointee.mSampleRate) * duration / timscale
                
                var channelCount = 1
                
                let formatDesc = track.formatDescriptions
                for item in formatDesc {
                    guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item as! CMAudioFormatDescription) else { continue }
                    channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
                }
                
                let samplesPerPixel = Int(max(1,  Double(channelCount) * numOfTotalSamples / Double(desiredNumberOfSamples)))
                let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count:samplesPerPixel)
                
                var outputSamples = [Float]()
                var sampleBuffer = Data()
                
                // 16-bit samples
                reader.startReading()
                
                while reader.status == .reading {
                    guard let readSampleBuffer = reader.outputs[0].copyNextSampleBuffer(),
                          let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                              break
                          }
                    
                    // Append audio sample buffer into our current sample buffer
                    var readBufferLength = 0
#if os(OSX)
                    var readBufferPointer: UnsafeMutablePointer<Int8>?
                    CMBlockBufferGetDataPointer(readBuffer, 0, &readBufferLength, nil, &readBufferPointer)
                    sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
                    CMSampleBufferInvalidate(readSampleBuffer)
#else
                    var readBufferPointer: UnsafeMutablePointer<Int8>?
                    CMBlockBufferGetDataPointer(readBuffer, atOffset: 0, lengthAtOffsetOut: &readBufferLength, totalLengthOut: nil, dataPointerOut: &readBufferPointer)
                    sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
                    CMSampleBufferInvalidate(readSampleBuffer)
#endif
                    let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
                    let downSampledLength = (totalSamples / samplesPerPixel)
                    let samplesToProcess = downSampledLength * samplesPerPixel
                    
                    guard samplesToProcess > 0 else { continue }
                    
                    self._processSamples(fromData: &sampleBuffer,
                                         sampleMax: &sampleMax,
                                         outputSamples: &outputSamples,
                                         samplesToProcess: samplesToProcess,
                                         downSampledLength: downSampledLength,
                                         samplesPerPixel: samplesPerPixel,
                                         filter: filter)
                }
                
                
                // Process the remaining samples at the end which didn't fit into samplesPerPixel
                let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
                if samplesToProcess > 0 {
                    let downSampledLength = 1
                    let samplesPerPixel = samplesToProcess
                    
                    let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
                    
                    self._processSamples(fromData: &sampleBuffer,
                                         sampleMax: &sampleMax,
                                         outputSamples: &outputSamples,
                                         samplesToProcess: samplesToProcess,
                                         downSampledLength: downSampledLength,
                                         samplesPerPixel: samplesPerPixel,
                                         filter: filter)
                }
                DispatchQueue.main.async {
                    onSuccess(outputSamples, sampleMax)
                }
                return
                
            case .failed, .cancelled, .loading, .unknown:
                DispatchQueue.main.async {
                    onFailure(SamplesExtractorError.readingError(message: "could not load asset: \(error?.localizedDescription ?? "Unknown error" )"))
                }
            @unknown default:
                DispatchQueue.main.async {
                    onFailure(SamplesExtractorError.readingError(message: "could not load asset unsupported error: \(error?.localizedDescription ?? "" )"))
                }
            }
        }
        
    }
    
    private static func _processSamples( fromData sampleBuffer: inout Data,
                                         sampleMax: inout Float,
                                         outputSamples: inout [Float],
                                         samplesToProcess: Int,
                                         downSampledLength: Int,
                                         samplesPerPixel: Int,
                                         filter: [Float]){
        sampleBuffer.withUnsafeBytes { (samples: UnsafePointer<Int16>) in
            
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            
            //Convert 16bit int samples to floats
            vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
            
            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            //Convert to dB
            var zero: Float = 32768.0
            vDSP_vdbcon(processingBuffer, 1, &zero, &processingBuffer, 1, sampleCount, 1)
            
            //Clip to [noiseFloor, 0]
            var ceil: Float = 0.0
            var noiseFloorFloat = SamplesExtractor.noiseFloor
            vDSP_vclip(processingBuffer, 1, &noiseFloorFloat, &ceil, &processingBuffer, 1, sampleCount)
            
            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            for element in downSampledData{
                if element > sampleMax { sampleMax = element }
            }
            // Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            outputSamples += downSampledData
        }
    }
    
    fileprivate static func _normalize(_ samples: [Float]) -> [Float] {
        let noiseFloor = SamplesExtractor.noiseFloor
        return samples.map { $0 / noiseFloor }
    }
    
}
