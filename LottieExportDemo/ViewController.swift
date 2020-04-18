//
//  ViewController.swift
//  LottieExportDemo
//
//  Created by Damik Minnegalimov on 10.09.2019.
//  Copyright © 2019 Damik Minnegalimov. All rights reserved.
//

import AVKit
import Lottie
import UIKit

class ViewController: UIViewController {
    var animationView: AnimationView?
    var animation: Animation?

    var exportButton: UIButton?
    var oldExportButton: UIButton?

    let size = CGSize(width: 1000, height: 1250)

    private var videoWriter: AVAssetWriter?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        Animation.loadedFrom(url: URL(string: "https://assets9.lottiefiles.com/datafiles/MUp3wlMDGtoK5FK/data.json")!,
                             closure: { animation in self.animationLoaded(newAnimation: animation) },
                             animationCache: nil)
    }

    func animationLoaded(newAnimation: Animation?) {
        animationView = AnimationView(animation: newAnimation)
        animationView?.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        animationView?.center = view.center

        view.addSubview(animationView!)

        animation = newAnimation
        addButtons()
    }

    @objc func startExport() {
        animationView?.loopMode = .playOnce
        animationView?.stop()
        animationView?.play { finished in
            print(finished)
            self.exportUsingExportSession()
        }
    }

    func exportUsingExportSession() {
        guard let animation = animation else {
            print("Set up Animation first")
            return
        }
        
        let bundleURL = Bundle.main.resourceURL!
        let baseVideo = AVAsset(url: URL(string: "poppets.mov", relativeTo: bundleURL)!)

        /// Create composition
        let compositionRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let timerange: CMTimeRange = CMTimeRange(start: .zero, duration: baseVideo.duration)

        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()

        let instructions = AVMutableVideoCompositionInstruction()
        instructions.backgroundColor = UIColor.clear.cgColor
        instructions.timeRange = timerange

        /// Create main parent layer for AVVideoCompositionCoreAnimationTool
        let parentLayer = CALayer()
        parentLayer.isGeometryFlipped = true
        parentLayer.frame = compositionRect

        let videoCALayer = CALayer()
        videoCALayer.frame = compositionRect
        parentLayer.addSublayer(videoCALayer)

        /// Create needed assets and tracks (AVFoundation classes)
        guard let videoTrack = baseVideo.tracks(withMediaType: .video).first else {
            NSLog("Error: there is no video track in video")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        try! compositionVideoTrack?.insertTimeRange(timerange, of: videoTrack, at: .zero)

        /// Set up effects for current layer (video)
        let layerIntruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack!)
        layerIntruction.setOpacity(1, at: .zero)

        /// Add effects to global instructions
        instructions.layerInstructions.append(layerIntruction)
        
        /// Add Lottie
//        let animationLayer = animationView.testAnimation(beginTime: AVCoreAnimationBeginTimeAtZero)
        let animationView = AnimationView()
        animationView.animation = animation
//        animationView.respectAnimationFrameRate = true
        let animationLayer = animationView.getFreeAnimationLayer(
            beginTime: AVCoreAnimationBeginTimeAtZero,
            preferredDuration: CMTimeGetSeconds(baseVideo.duration)
        )
        
//        let animationLayer = self.addLottieLayer(animation: animation, with: compositionRect)
        animationLayer.frame = compositionRect
//        animationLayer.layoutSublayers()
        
        parentLayer.addSublayer(animationLayer)
        
        /// Set up composition size and framerate
        videoComposition.instructions = [instructions]
//        let duration = ((Float64(animation.endFrame) - Float64(animation.startFrame) / Float64(animation.framerate))
//        videoComposition.frameDuration = CMTimeMake(value: 12, timescale: 60)
        videoComposition.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        videoComposition.renderSize = size
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoCALayer, in: parentLayer
        )
        
        let outputURL = prepareVideoOutputFile("processed.mov")
        
        self.export(
            composition: composition,
            videoComposition: videoComposition,
            duration: baseVideo.duration,
            outputUrl: outputURL
        ) { outputURL in
            playVideo(url: outputURL)
            print(animationView)
        }
    }
    
    
//    func addLottieLayer(animation: Animation,
//                        with frame: CGRect) -> CALayer {
//        let animationView = AnimationView()
//        animationView.animation = animation
//
//         let animationLayer = AnimationContainer(animation: animation,
//                                                 imageProvider: animationView.imageProvider,
//                                                 textProvider: animationView.textProvider)
//
//         animationLayer.frame = frame;
//
//         animationLayer.renderScale = UIScreen.main.scale
//         animationLayer.reloadImages()
//         animationLayer.setNeedsDisplay()
//         animationLayer.setNeedsLayout()
//
//         let animationContext = AnimationContext(playFrom: CGFloat(animation.startFrame),
//                                        playTo: CGFloat(animation.endFrame),
//                                        closure: nil)
//
//         let framerate = animation.framerate
//
//         let playFrom = animationContext.playFrom.clamp(animation.startFrame, animation.endFrame)
//         let playTo = animationContext.playTo.clamp(animation.startFrame, animation.endFrame)
//
//         let duration = ((max(playFrom, playTo) - min(playFrom, playTo)) / CGFloat(framerate))
//
//         let layerAnimation = CABasicAnimation(keyPath: "currentFrame")
//         layerAnimation.fromValue = playFrom
//         layerAnimation.toValue = playTo
//         layerAnimation.duration = TimeInterval(duration)
//         layerAnimation.fillMode = CAMediaTimingFillMode.both
//         layerAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
//         layerAnimation.repeatCount = 2
//
//         let activeAnimationName = "testAnimation" + String(1)
//
//
//         layerAnimation.delegate = animationContext.closure
//         animationContext.closure.animationLayer = animationLayer
//         animationContext.closure.animationKey = activeAnimationName
//         animationLayer.add(layerAnimation, forKey: activeAnimationName)
//
//
//         return animationLayer
//    }

//        animationView.play(
//            fromProgress: 0,
//            toProgress: 1,
//            loopMode: .repeat(2),
//            completion: { (finished) in
//            }
//        )
        
//        let outputURLTemp = prepareVideoOutputFile("processed-temp.mov")
//
//        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
//            exportSession.videoComposition = videoComposition
//            exportSession.outputURL = outputURLTemp
//            exportSession.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
//            exportSession.outputFileType = .mov
//
//            let startTime = Date()
//            exportSession.exportAsynchronously {
//                let timeDilation = CMTimeGetSeconds(baseVideo.duration) / startTime.timeIntervalSinceNow
//
//                print("- \(startTime.timeIntervalSinceNow * -1) seconds elapsed for AVAssetExportSession")
//                print("- time dilation: \(timeDilation) ")
//                DispatchQueue.main.sync {
//                    /// Add Lottie
//                    let animationView = AnimationView()
//                    animationView.animation = animation
//                    animationView.animationSpeed = 1
//                    animationView.respectAnimationFrameRate = true
//                    animationView.backgroundBehavior = .pauseAndRestore
//
//                    let animationLayer = animationView.layer
//                    animationLayer.frame = compositionRect
//                    animationLayer.layoutSublayers()
//
//                    parentLayer.addSublayer(animationLayer)
//
//
//                    self.export(
//                        composition: composition,
//                        videoComposition: videoComposition,
//                        outputUrl: outputURL
//                    ) { outputURL in
//                        playVideo(url: outputURL)
//                    }
//
//                    animationView.play(
//                        fromProgress: 0,
//                        toProgress: 1,
//                        loopMode: .repeat(2),
//                        completion: { (finished) in
//                        }
//                    )
//                }
//            }
//        }


    func export(composition: AVMutableComposition,
                videoComposition: AVMutableVideoComposition,
                duration: CMTime,
                outputUrl: URL,
                completion: ((URL) -> Void)?) {
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.videoComposition = videoComposition
            exportSession.outputURL = outputUrl
            exportSession.timeRange = CMTimeRangeMake(start: .zero, duration: duration)
            exportSession.outputFileType = .mov

            toggleExportButton(needEnable: false)

            let startTime = Date()
            exportSession.exportAsynchronously {
                print("- \(startTime.timeIntervalSinceNow * -1) seconds elapsed for AVAssetExportSession")

                self.toggleExportButton(needEnable: true)

                if exportSession.status.rawValue == 4 {
                    print("Export failed -> Reason: \(exportSession.error!.localizedDescription))")
                    print(exportSession.error!)
                    return
                }

                completion?(outputUrl)
            }
        }
    }

    @objc func oldExport() throws {
        animationView?.loopMode = .playOnce
        animationView?.stop()
        animationView?.play { _ in
            try? self.exportUsingAVWriter()
        }
    }

    func exportUsingAVWriter() throws {
        toggleOldExportButton(needEnable: false)

        let fps = Int64(animation?.framerate ?? 30)
        var framesMax = CGFloat(fps)

        if let animation = animation {
            framesMax = CGFloat(animation.duration * Double(fps))
        }

        /*
         * Set up VideoWriter
         */
        do {
            let outputURL = prepareVideoOutputFile("processed.mov")
            try videoWriter = AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        } catch {
            throw (error)
        }

        guard let videoWriter = videoWriter else {
            return
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
        ]

        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)

        let sourceBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Float(size.width),
            kCVPixelBufferHeightKey as String: Float(size.height),
        ]

        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourceBufferAttributes)

        assert(videoWriter.canAdd(videoWriterInput))
        videoWriter.add(videoWriterInput)

        if videoWriter.startWriting() {
            let startTime = Date()
            videoWriter.startSession(atSourceTime: CMTime.zero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)

            let writeQueue = DispatchQueue(label: "writeQueue", qos: .userInteractive)

            videoWriterInput.requestMediaDataWhenReady(on: writeQueue, using: {
                let frameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
                var frameCount: Int64 = 0

                /*
                 * Start render loop
                 */
                while Int(frameCount) < Int(framesMax) {
                    if videoWriterInput.isReadyForMoreMediaData {
                        DispatchQueue.main.sync {
                            let lastFrameTime = CMTimeMake(value: frameCount, timescale: Int32(fps))
                            let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)

                            // Set up Lottie
                            self.animationView?.currentProgress = CGFloat(frameCount) / framesMax

                            UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)

                            if let animationView = self.animationView {
                                animationView.drawHierarchy(in: animationView.frame,
                                                            afterScreenUpdates: false)
                            }

                            let image = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()

                            do {
                                try append(pixelBufferAdaptor: pixelBufferAdaptor,
                                           with: image!,
                                           at: presentationTime,
                                           success: {
                                               frameCount += 1
                                })
                            } catch {} // Do not throw here
                        }
                    }
                }

                videoWriterInput.markAsFinished()

                videoWriter.finishWriting {
                    print("--- \(startTime.timeIntervalSinceNow * -1) seconds elapsed for AVAssetWriterInput")

                    self.toggleOldExportButton(needEnable: true)

                    self.animationView?.loopMode = .loop
                    playVideo(url: videoWriter.outputURL)
                }
            })
        }
    }
}

extension ViewController {
    func toggleExportButton(needEnable: Bool) {
        DispatchQueue.main.async {
            self.exportButton?.setTitle(needEnable ? "Start AVAssetExportSession" : "Processing...", for: .normal)
            self.exportButton?.isEnabled = needEnable
        }
    }

    func toggleOldExportButton(needEnable: Bool) {
        DispatchQueue.main.async {
            self.oldExportButton?.setTitle(needEnable ? "Start AVAssetWriter" : "Processing...", for: .normal)
            self.oldExportButton?.isEnabled = needEnable
        }
    }

    func addButtons() {
        let buttonSize = CGSize(width: 250, height: 40)

        /// Start AVAssetExportSession button
        exportButton = UIButton(frame: CGRect(origin: .zero, size: buttonSize))

        exportButton?.setTitle("Start AVAssetExportSession", for: .normal)
        exportButton?.addTarget(self, action: #selector(startExport), for: .touchUpInside)

        exportButton?.center = view.center
        exportButton?.frame.origin.y = exportButton!.frame.origin.y + 190
        view.addSubview(exportButton!)

        /// Start AVAssetWriter button
        oldExportButton = UIButton(frame: CGRect(origin: .zero, size: buttonSize))

        oldExportButton?.setTitle("Start AVAssetWriter", for: .normal)
        oldExportButton?.addTarget(self, action: #selector(oldExport), for: .touchUpInside)

        oldExportButton?.center = view.center
        oldExportButton?.frame.origin.y = oldExportButton!.frame.origin.y + 240
        view.addSubview(oldExportButton!)
    }
}
