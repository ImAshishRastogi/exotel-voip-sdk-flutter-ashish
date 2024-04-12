//
//  ProviderDelegate.swift
//  ExotelVoiceSample
//
//  Created by ashishrastogi on 24/10/23.
//

import Foundation
import UIKit
import AVFoundation
import CallKit

final class ProviderDelegate: NSObject,CXProviderDelegate {
    let TAG = "CallKitProviderDelegate"
    
    internal init( provider: CXProvider) {
        self.provider = provider
    }
    private let provider: CXProvider

    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")

        do {
            try VoiceAppService.shared.hangup()
        } catch let error {
            VoiceAppLogger.debug(TAG: TAG, message: "Error: \(error.localizedDescription)")
        }

        // Remove all calls from the app's list of calls.
//        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        
        CallKitUtils.setActiveUUID(uuid: action.callUUID)
        
        action.fulfill()
        
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXAnswerCallAction")

        VoiceAppService.shared.answer()
        // Signal to the system that the action was successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXEndCallAction")

        do {
            try VoiceAppService.shared.hangup()
        } catch let error {
            VoiceAppLogger.debug(TAG: TAG, message: "Error: \(error.localizedDescription)")
        }
        // Signal to the system that the action was successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXSetHeldCallAction")

        // Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        VoiceAppLogger.info(TAG: TAG, message: "CXSetMutedCallAction")
        if action.isMuted {
            VoiceAppService.shared.mute()
        } else {
            VoiceAppService.shared.unmute()
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        VoiceAppLogger.info(TAG: TAG, message: "timedOutPerforming")
//        print("Timed out", #function)

        // React to the action timeout if necessary, such as showing an error UI.
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        VoiceAppLogger.info(TAG: TAG, message: "didActivate")

        /*
         Start call audio media, now that the audio session is activated,
         after having its priority elevated.
         */
//        startAudio()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        VoiceAppLogger.info(TAG: TAG, message: "didDeactivate")

        /*
         Restart any non-call related audio now that the app's audio session is deactivated,
         after having its priority restored to normal.
         */
    }
}
