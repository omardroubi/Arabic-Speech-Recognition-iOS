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

class VoiceRecognitionViewController: UIViewController, SFSpeechRecognizerDelegate {

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private let speechRecognizer: SFSpeechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ar-SA"))!

    override func viewDidLoad() {

    }
    

        func startRecording() {
            
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.record)
                try audioSession.setMode(AVAudioSession.Mode.measurement)
    //            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
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
                    
                    self.textView.text = result?.bestTranscription.formattedString
                    isFinal = (result?.isFinal)!
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
        

        func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
            if available {
                speechButton.isEnabled = true
            } else {
                speechButton.isEnabled = false
            }
        }
        
    
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var speechButton: UIButton!
    @IBAction func speechPressed(_ sender: Any) {
        // SpeechKit
        speechButton.isEnabled = false  //2
        
        speechRecognizer.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
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
        }
    }
    
}
