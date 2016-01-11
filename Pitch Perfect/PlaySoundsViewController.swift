//
//  PlaySoundsViewController.swift
//  Pitch Perfect Demo
//
//  Created by Michael Miller on 1/1/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController, AVAudioPlayerDelegate {
    
    //MARK: OUTLETS
    
    @IBOutlet weak var stopButton: UIButton!
    
    //MARK: VARIABLES
    
    var audioPlayer: AVAudioPlayer!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var receivedAudio: RecordedAudio?
    var audioFile: AVAudioFile!
    var nodesStarted = 0
    
    //MARK: CONSTANTS
    
    struct Constants {
        static let lowPitch: Float = -1000
        static let highPitch: Float = 1500
        static let slowRate: Float = 0.5
        static let fastRate: Float = 1.75
    }
    
    //MARK: CUSTOM METHODS
    
    //method that stops playback, called from the stop button
    @IBAction func stopPlayback(sender: UIButton) {
        stopPlayer()
    }
    
    //methods that plays back the audio file with a low pitch, high pitch, slow speed, fast speed, reverb, and distortion
    @IBAction func makeDarthVader(sender: UIButton) {
        playAudioWithVariablePitch(Constants.lowPitch)
    }
    
    @IBAction func makeChipmunk(sender: UIButton) {
        playAudioWithVariablePitch(Constants.highPitch)
    }
    
    @IBAction func makeSlow(sender: UIButton) {
        audioPlayer.rate = Constants.slowRate
        stopPlayer()
        startPlayer()
    }
    
    @IBAction func makeFast(sender: UIButton) {
        audioPlayer.rate = Constants.fastRate
        stopPlayer()
        startPlayer()
    }
    
    @IBAction func makeEcho(sender: UIButton) {
        playAudioDistortion(.MultiEcho1)
    }
    
    @IBAction func makeSpace(sender: UIButton) {
        playAudioDistortion(.SpeechCosmicInterference)
    }
    
    //method that prepares for playback of the audio file with a pitch effect (high or low, depending on what value is passed into the pitch parameter)
    func playAudioWithVariablePitch(pitch: Float) {
        stopPlayer()
        
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)

        let pitchEffect = AVAudioUnitTimePitch()
        pitchEffect.pitch = pitch
        audioEngine.attachNode(pitchEffect)
        
        playEffect(player: audioPlayerNode, effect: pitchEffect)
    }
    
    //method that prepares for playback of the audio file with a distortion effect (depending on which button was pressed: echo or alien)
    func playAudioDistortion(effect: AVAudioUnitDistortionPreset) {
        stopPlayer()
        
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        let distortionEffect = AVAudioUnitDistortion()
        distortionEffect.loadFactoryPreset(effect)
        distortionEffect.wetDryMix = 75
        audioEngine.attachNode(distortionEffect)
        
        playEffect(player: audioPlayerNode, effect: distortionEffect)
    }
    
    //method that sets up the audio engine and begins playback of the audio file (called when pitch, reverb, or distortion effect is selected)
    func playEffect(player player: AVAudioPlayerNode, effect: AVAudioUnit) {
        
        do {
            try audioFile = AVAudioFile(forReading: receivedAudio!.filePathURL)
        } catch let error as NSError {
            print(error.debugDescription)
        }
        
        guard audioFile != nil else { return }
        
        audioEngine.connect(player, to: effect, format: nil)
        audioEngine.connect(effect, to: audioEngine.outputNode, format: nil)
            
        //below:  although using player.scheduleFile to play the file was the most direct approach, there seems to be a documented bug which causes the completion handler of the "scheduleFile" method to get called BEFORE the file is actually done playing (http://stackoverflow.com/questions/29427253/completionhandler-of-avaudioplayernode-schedulefile-is-called-too-early ). since i wanted to use a completion handler to disable the stop button when the file gets done playing, it was necessary that the timing was correct on the completion handler, and so i used the "scheduleBuffer" method instead, which DOES call the completion handler at the appropriate time!
        
        let buffer = AVAudioPCMBuffer(PCMFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
        
        do {
            try audioFile.readIntoBuffer(buffer)
        } catch let error as NSError {
            callError(error)
        }
    
        //within the completion handler, it was necessary to keep track of how many nodes had been activated because if one audioplayernode (activated by one of the four distortions) was started before another had stopped, the completion handler for the first ran AFTER the second started, thus disabling the stop button too early; the code below prevents the button from disabling too early by keeping track of how many started nodes there are running (the max is 2); the code also prevents the stop button from disabling too soon if a button corresponding to the audioplayer (fast/slow) was pressed before an audioplayernode sound effect had finished
        player.scheduleBuffer(buffer) {
            [unowned self] () -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if !self.audioPlayer.playing {
                        if self.nodesStarted == 1 {
                            self.stopButton.enabled = false
                        }
                    }
                    --self.nodesStarted
                }
            }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            player.play()
            ++nodesStarted
            stopButton.enabled = true
        } catch let error as NSError {
            callError(error)
        }
    }
    
    //methods that start and stop the audio player
    func startPlayer() {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        audioPlayer.play()
        stopButton.enabled = true
    }
    
    func stopPlayer() {
        audioPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
        stopButton.enabled = false
    }
    
    //method for calling errors that could be produced while audio recording
    func callError(error: NSError) {
        let ac = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    //MARK: DELEGATE METHODS

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        stopButton.enabled = false
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        title = "Add Sound Filter"
        stopButton.enabled = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopPlayer()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioEngine = AVAudioEngine()
        if receivedAudio != nil {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error.debugDescription)
            }
            do {
                try audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio!.filePathURL)
                audioPlayer.enableRate = true
                audioPlayer.delegate = self
            } catch let error as NSError {
                print(error.debugDescription)
            }
        }
    }
}
