//
//  FrameExtractor.swift
//  Arabic Speech Recognition
//
//  Created by Omar Droubi on 4/29/20.
//  Copyright © 2020 Omar Droubi. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class LipReadingVC: UIViewController {

    public var predictionSentence = ""

    var frameExtractor: FrameExtractor!

    @IBOutlet weak var transcriptionLabel: UILabel!
    @IBOutlet weak var transcriptionLabel2: UILabel!
    
    let faceDetector = FaceLandmarksDetector()
    let captureSession = AVCaptureSession()
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDevice()
        self.imageView.transform = CGAffineTransform(scaleX: -1, y: 1);
    
    }

    private let audioEngine = AVAudioEngine()
        
    public func getVolume(from buffer: AVAudioPCMBuffer, bufferSize: Int) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else {
            return 0
        }

        let channelDataArray = Array(UnsafeBufferPointer(start:channelData, count: bufferSize))

        var outEnvelope = [Float]()
        var envelopeState:Float = 0
        let envConstantAtk:Float = 0.16
        let envConstantDec:Float = 0.003

        for sample in channelDataArray {
            let rectified = abs(sample)

            if envelopeState < rectified {
                envelopeState += envConstantAtk * (rectified - envelopeState)
            } else {
                envelopeState += envConstantDec * (rectified - envelopeState)
            }
            outEnvelope.append(envelopeState)
        }

        // 0.007 is the low pass filter to prevent
        // getting the noise entering from the microphone
        if let maxVolume = outEnvelope.max(),
            maxVolume > Float(0.015) {
            return maxVolume
        } else {
            return 0.0
        }
    }
    
    private func getDevice() -> AVCaptureDevice? {
        let discoverSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: .video, position: .front)
        return discoverSession.devices.first
    }

    private func configureDevice() {
        if let device = getDevice() {
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                device.unlockForConfiguration()
            } catch { print("failed to lock config") }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                captureSession.addInput(input)
            } catch { print("failed to create AVCaptureDeviceInput") }

            captureSession.startRunning()

            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .utility))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension LipReadingVC: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        // Scale image to process it faster
        let maxSize = CGSize(width: 1024, height: 1024)

        if let image = UIImage(sampleBuffer: sampleBuffer)?.imageWithAspectFit(size: maxSize) {
            faceDetector.highlightFaces(for: image) { (resultImage) in
                DispatchQueue.main.async {
                    self.imageView?.image = resultImage
                    
                    
                    // image has been defined earlier
                    
                     var pixelbuffer: CVPixelBuffer? = nil
                
                    CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_OneComponent8, nil, &pixelbuffer)
                    CVPixelBufferLockBaseAddress(pixelbuffer!, CVPixelBufferLockFlags(rawValue:0))
                
                     let colorspace = CGColorSpaceCreateDeviceGray()
                     let bitmapContext = CGContext(data: CVPixelBufferGetBaseAddress(pixelbuffer!), width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelbuffer!), space: colorspace, bitmapInfo: 0)!
                
                    bitmapContext.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                
                    
                    // Transcription Neural Net
                    // start recording
                    
                    let lipnetModel = LipNet()
           
                    if let prediction = try? lipnetModel.prediction(image: pixelbuffer!) {
                        self.transcriptionLabel.text = prediction.classLabel + "  %" + (Int(prediction.classLabelProbs[prediction.classLabel]! * 100 - 20)).description
                    }

                }
            }
        }
    }
}

