//
//  RecordViewController.swift
//  Pitch Perfect Demo
//
//  Created by Michael Miller on 1/1/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate {

    //MARK: OUTLETS
    
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pressButton: UIButton!
    @IBOutlet weak var buttonStack: UIStackView!
    
    //MARK: CONSTANTS
    
    struct Constants {
        static let SegueToPlay = "showPlayView"
        static let TempFileName = "my_audio.wav"
        static let LabelStartText = "Tap mic to record!"
        static let LabelRecord1 = "Recording"
        static let LabelRecord2 = "Recording."
        static let LabelRecord3 = "Recording.."
        static let LabelRecord4 = "Recording..."
        static let PausedLabel = "PAUSED"
        static let ButtonOffset: CGFloat = 200
        static let DefaultTextColor = UIColor(red: 26/255, green: 56/255, blue: 92/255, alpha: 1.0)
        static let RecordingColor = UIColor(red: 40/255, green: 150/255, blue: 20/255, alpha: 1.0)
        static let PausedColor = UIColor.redColor()
    }
    
    //MARK: VARIABLES
    
    var audioRecorder: AVAudioRecorder?
    let audioSession = AVAudioSession.sharedInstance()
    var isRecording = false
    var timer: NSTimer?
    var counter = 0
    var isPaused = false
    
    //MARK: CUSTOM METHODS
    
    //method that starts the audiorecording and saves it to a file
    @IBAction func recordAudio(sender: UIButton) {
        do {
            try audioSession.setActive(true)
        } catch let error as NSError {
            callError(error)
        }
        
        recordButton.enabled = false
        buttonsAppearWithAnimation()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("displayRecordingText"), userInfo: nil, repeats: true)
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let recordingName = Constants.TempFileName
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        if let path = filePath {
            do {
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                do {
                    try audioRecorder = AVAudioRecorder(URL: path, settings: [:])
                    audioRecorder?.meteringEnabled = true
                    audioRecorder?.prepareToRecord()
                    audioRecorder?.record()
                    audioRecorder?.delegate = self
                } catch let error as NSError {
                    callError(error)
                }
            } catch let error as NSError {
                callError(error)
            }
        }
    }
    
    //method that pauses the audiorecording (and unpauses it if currently paused)
    @IBAction func pauseRecording(sender: UIButton) {
        if !isPaused {
            timer?.invalidate()
            isPaused = true
            audioRecorder?.pause()
            displayPauseText()
        } else {
            isPaused = false
            pauseButton.layer.removeAllAnimations()
            pauseButton.alpha = 1
            timer?.invalidate()
            timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("displayRecordingText"), userInfo: nil, repeats: true)
            audioRecorder?.record()
        }
    }
    
    //method that stops recording and resets the pause button in the event the stop button is pressed while paused
    @IBAction func stopRecording(sender: UIButton) {
        timer?.invalidate()
        recordingLabel.text = ""
        
        if isPaused {
            isPaused = false
            pauseButton.layer.removeAllAnimations()
            pauseButton.alpha = 1
        }
        
        stopRecorder()
    }
    
    func stopRecorder() {
        audioRecorder?.stop()
        do {
            try audioSession.setActive(false)
        } catch let error as NSError {
            callError(error)
        }
    }
    
    //method to have the pause and stop buttons animate in when recording begins; called when the record button is pressed
    func buttonsAppearWithAnimation() {
        stopButton.transform = CGAffineTransformIdentity
        pauseButton.transform = CGAffineTransformIdentity
        stopButton.alpha = 0
        pauseButton.alpha = 0
        stopButton.center.y += Constants.ButtonOffset
        pauseButton.center.y += Constants.ButtonOffset
        UIView.animateWithDuration(0.75, delay: 0, options: [.CurveEaseOut], animations: { [unowned self] () -> Void in
            self.buttonStack.hidden = false
            self.stopButton.center.y -= Constants.ButtonOffset
            self.pauseButton.center.y -= Constants.ButtonOffset
            self.pauseButton.alpha = 1
            self.stopButton.alpha = 1
            }, completion: { (successful) -> Void in
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.stopButton.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                    self.stopButton.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                    self.pauseButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                })
        })
    }
    
    //method to update recording text during recording
    func displayRecordingText() {
        ++counter
        recordingLabel.textColor = Constants.RecordingColor
        switch counter {
        case 1:
            recordingLabel.text = Constants.LabelRecord1
        case 2:
            recordingLabel.text = Constants.LabelRecord2
        case 3:
            recordingLabel.text = Constants.LabelRecord3
        case 4:
            recordingLabel.text = Constants.LabelRecord4
            counter = 0
        default:
            break
        }
    }
    
    //method that casuses the pause button to animate (blink on and off) while the recording is paused
    func displayPauseText() {
        recordingLabel.textColor = Constants.PausedColor
        pauseButton.alpha = 1
        UIView.animateWithDuration(1, delay: 0, options: [.Repeat, .Autoreverse, .AllowUserInteraction], animations: { () -> Void in
            self.pauseButton.alpha = 0.25
            }, completion: nil)
        recordingLabel.text = Constants.PausedLabel
    }
    
    //method for calling errors that could be produced while audio recording
    func callError(error: NSError) {
        let ac = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    //method that initially sets up the recording screen; called during viewWillAppear and if audioRecorderDidFinishRecording is unsuccessful
    func setup() {
        recordButton.enabled = true
        buttonStack.hidden = true
        recordingLabel.textColor = Constants.DefaultTextColor
        recordingLabel.text = Constants.LabelStartText
    }
    
    //MARK: DELEGATE METHODS
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            if let title = recorder.url.lastPathComponent {
                let recordedAudio = RecordedAudio(filePathURL: recorder.url, title: title)
                performSegueWithIdentifier(Constants.SegueToPlay, sender: recordedAudio)
            }
        } else {
            setup()
            let ac = UIAlertController(title: "Error", message: "An error occurred with the recording.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    //MARK: INHERITED METHODS
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.SegueToPlay {
            if let psvc = segue.destinationViewController as? PlaySoundsViewController {
                if let audioToSend = sender as? RecordedAudio {
                    psvc.receivedAudio = audioToSend
                }
            }
        }
    }
    
    //MARK: VIEW CONTROLLER LIFECYCLE
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setup()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
    }
}

