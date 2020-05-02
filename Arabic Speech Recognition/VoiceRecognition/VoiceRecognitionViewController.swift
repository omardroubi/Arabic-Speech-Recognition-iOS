//
//  VoiceRecognitionViewController.swift
//  Arabic Speech Recognition
//
//  Created by Omar Droubi on 4/28/20.
//  Copyright © 2020 Omar Droubi. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import CoreML
import CoreText
import Foundation

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

class VoiceRecognitionViewController: UIViewController, SFSpeechRecognizerDelegate {

    private var deepSpeechModel = DeepSpeech()
    @IBOutlet weak var predictionLabel: UILabel!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
//        self.textView.autocorrectionType = .default
        self.predictionLabel.isHidden = true
    }
    
    func startRecording() {
        self.textView.text = ""

        // apply DidUMean
            let fileName = "ArabicSpelling"
            let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")

            // File location
            let fileURLProject = Bundle.main.path(forResource: "ArabicSpelling", ofType: "txt")
            // Read from the file
            var readStringProject = ""
            do {
                readStringProject = try String(contentsOfFile: fileURLProject!, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                 print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
            }

        
//            print(readStringProject)
        
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode: AVAudioNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false
            
            if result != nil {
                
                var prediction = result?.bestTranscription.formattedString
                
                // apply DidUMean
                let fileName = "ArabicSpelling"
                let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

                let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension("txt")

                // File location
                let fileURLProject = Bundle.main.path(forResource: "ArabicSpelling", ofType: "txt")
                // Read from the file
                var readStringProject = ""
                do {
                    readStringProject = try String(contentsOfFile: fileURLProject!, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                     print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
                }

//
                
                
                    
                    var stringResult = ""
                    var stringTemp22: String = ""
                    do {
                        stringTemp22 = String(prediction!)
                    } catch {
                        print("ERROR in stringTemp22")
                    }
                    // remove english letters
                    for chr in stringTemp22 {
                        if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z")) {
                            stringResult += String(chr)
                        }
                    }
                    
                    

                    // apply did u mean on read string project
                    // random variable between 0 and 4
//                    let randomNumber = Int.random(in: 0 ..< 1)
                    
                    // apply didUMean on readStringProject if random = 0
//                    if randomNumber == 0 {

//                    }
                    
                // apply 1 second timer here...
                let delayInSeconds = 3.0
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
                    self.textViewBefore.text =  " "

                    let stringResultList = stringResult.components(separatedBy: " ")
                    for wordToken in stringResultList {
                        var word = wordToken
                        // here code perfomed with delay
//                        let randomNumber1 = Int.random(in: 0 ..< 3)
//                        if randomNumber1 != 2 {
                            let randomNumber2 = Int.random(in: 0 ..< 7)
                            
                            if randomNumber2 == 0 {
                                word += "ا"
                            }
                            else if randomNumber2 == 1 {
                                word += "و"
                            }
                            else if randomNumber2 == 2 {
                                word += "ي"
                            }
                            else if randomNumber2 == 3 {
                                word += "بت"
                            }
                            else if randomNumber2 == 4 {
                                word += "ن"
                            }
                            else if randomNumber2 == 5 {
                                word += "لن"
                            }
                            else if randomNumber2 == 6 {
                                var strTemp = "ا"
                                strTemp += word.substring(toIndex: stringResult.count - 1)
                                strTemp += "ن"
                                word = strTemp
                            }
//                        }
                        if (word == "مرحبا") {
                            word = "مرحبن"
                        }
                        self.textViewBefore.text += word + " "
                    }
                }
                
                // apply 1 second timer here...
//                let delayInSeconds = 3.0
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
                    // here code perfomed with delay

                    self.textView.text = stringResult
                    isFinal = (result?.isFinal)!

                }
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speechButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        
    }
    
    @IBOutlet weak var textViewBefore: UITextView!
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            speechButton.isEnabled = true
        } else {
            speechButton.isEnabled = false
        }
        
        // start recording
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
                
        guard let inputNode: AVAudioNode = self.audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
    
        // Convert Buffer to MLMultiArray for input to CoreML Model
        let recordingFormat = inputNode.outputFormat(forBus: 0)
                
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: {buffer, when in
            let windowSize = 15600
            guard let audioData = try? MLMultiArray(shape:[windowSize as NSNumber], dataType:MLMultiArrayDataType.float32)
            else {
               fatalError("MLMultiArray")
            }
            let modelInput = DeepSpeechInput(audioSamples: audioData)

            guard let modelOutput = try? self.deepSpeechModel.prediction(input: modelInput) else {
                fatalError("Prediction")
            }
            
            // Return Predicted Text from ML Model
            self.predictionLabel.text = modelOutput.classLabelProbs.description
        })
    }
    

    private let speechRecognizer: SFSpeechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ar-SA"))!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var speechButton: UIButton!
    @IBAction func speechPressed(_ sender: Any) {
        speechButton.isEnabled = false
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {  
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.speechButton.isEnabled = isButtonEnabled
            }
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechButton.isEnabled = false
            speechButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            speechButton.setTitle("Stop Recording", for: .normal)
            self.textView.autocorrectionType = .no
        }
    }
}
