/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import UIKit
import AVFoundation
import AudioToolbox

public class RingTonePlayback {
    private var mBusyTonePlayer: AVAudioPlayer!
    private var mReorderTonePlayer: AVAudioPlayer!
    private var mWaitingTonePlayer: AVAudioPlayer!
    private var mRingTonePlayer: AVAudioPlayer!
    private var TAG: String = "RingTonePlayback"
    
    private var mPlayerReady: Bool = false
    private var isVibrating: Bool = false
    
    public init() {
        do {
            //Setup the tone to be played
            mBusyTonePlayer = try setupSoundTrack(soundFileName: "busy_tone", soundFileType: "mp3")
            mReorderTonePlayer = try setupSoundTrack(soundFileName: "reorder_tone", soundFileType: "mp3")
            mWaitingTonePlayer = try setupSoundTrack(soundFileName: "callwaiting_tone", soundFileType: "mp3")
            mRingTonePlayer = try setupSoundTrack(soundFileName: "exotel_ringtone", soundFileType: "mp3")
            
            //Create an audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback)
            
            mPlayerReady = true
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: error.localizedDescription)
            mPlayerReady = false
        }
    }
    
    public func setupSoundTrack(soundFileName: String, soundFileType: String) throws -> AVAudioPlayer {
        do {
            let defaultTonePlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: soundFileName, ofType: soundFileType)!))
            defaultTonePlayer.prepareToPlay()
            return defaultTonePlayer
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: error.localizedDescription)
            mPlayerReady = false
            throw VoiceAppError(module: TAG, localizedDescription: error.localizedDescription)
        }
    }
    
    public func playRingTone() {
        if (mPlayerReady) {
            VoiceAppLogger.debug(TAG: TAG, message: "Playing ring tone")
            mRingTonePlayer.play()
        } else {
            VoiceAppLogger.error(TAG: TAG, message: "Ring sound player not yet loaded")
        }
    }
    
    public func playBusyTone() {
        if (mPlayerReady) {
            VoiceAppLogger.debug(TAG: TAG, message: "Playing busy tone")
            self.mBusyTonePlayer.play()
        }
        else {
            VoiceAppLogger.error(TAG: TAG, message: "Busy sound player not yet loaded")
        }
    }
    
    public func playReorderTone() {
        if (mPlayerReady) {
            VoiceAppLogger.debug(TAG: TAG, message: "Playing reorder tone");
            mReorderTonePlayer.play()
        } else {
            VoiceAppLogger.error(TAG: TAG, message: "Reorder sound player not yet loaded")
        }
    }
    
    public func playWaitingTone() {
        if (mPlayerReady) {
            VoiceAppLogger.debug(TAG: TAG, message: "Playing waiting tone")
            mWaitingTonePlayer.play()
        } else {
            VoiceAppLogger.error(TAG: TAG, message: "Waiting sound player not yet loaded")
        }
    }
    
    public func resetTonePlayback() {
        VoiceAppLogger.debug(TAG: TAG, message: "Releasing sound pool")
        if mPlayerReady {
            if mBusyTonePlayer.isPlaying {
                mBusyTonePlayer.stop()
                mBusyTonePlayer.currentTime = 0
            }
            if mReorderTonePlayer.isPlaying {
                mReorderTonePlayer.stop()
                mReorderTonePlayer.currentTime = 0
            }
            if mWaitingTonePlayer.isPlaying {
                mWaitingTonePlayer.stop()
                mWaitingTonePlayer.currentTime = 0
            }
            if mRingTonePlayer.isPlaying {
                mRingTonePlayer.stop()
                mRingTonePlayer.currentTime = 0
            }
            if isVibrating {
                stopVibration()
            }
        }
    }
    
    public func startVibration() {
        VoiceAppLogger.debug(TAG: TAG, message: "started Vibration...")
        if !mRingTonePlayer.isPlaying && !isVibrating {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            isVibrating = true
            return
        }
        while mRingTonePlayer.isPlaying
        {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        isVibrating = true
    }
    
    public func stopVibration() {
        VoiceAppLogger.debug(TAG: TAG, message: "stoping Vibration.")
        if isVibrating {
            AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
            isVibrating = false
        }
    }
}
