/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import ExotelVoice
import UIKit

let incomingCallKey = "kIncomingCall"
let initiateCallKey = "kInitiatedCall"
let ringingCallKey = "kRingingCall"
let establishedCallKey = "kEstablishedCall"
let endedCallKey = "kCallEnded"
let missedCallKey = "kMissedCall"
let initFailedKey = "kInitFailed"
let authFailedKey = "kAuthFailed"
let initSuccessKey = "kInitSuccess"
let uploadLogSuccess = "kUploadLogSuccess"
let uploadLogFailure = "kUploadLogFailure"
let statusUpdate = "kStatusUpdate"
let disruptedCallKey = "kDisruptedCall"
let renewedCallKey = "kRenewedCall"

let missingMicrophonePermissionStr = "Microphone Permission is missing. Please enable microphone permission under \"Settings -> Exotel Voice Sample -> Microphone\" for this app"
let missingNotificationPermissionStr = "Notifications Permission is missing. Please enable notifications permission under \"Settings -> Exotel Voice Sample -> Notifications -> Allow Notifications\" for this app"

public class VoiceAppService {
    static let shared = VoiceAppService()
    private let TAG = "VoiceAppService"
    private var exotelVoiceClient: ExotelVoiceClient?
    private var callController: CallController?
    private var mCall: Call?
    private var mPreviousCall: Call?
    private var ringingStartTime: Double = 0
    private var initializationInProgress:Bool = false
    private var initializationErrorMessage:String = ""
    private var tonePlayback = RingTonePlayback()
    
    // isReadyToReceiveCalls flag will be true when HomeViewController view will appear
    private var isReadyToReceiveCalls:DarwinBoolean = false
    
    let databaseHelper = DatabaseHelper.shared
    
    public func sendPushNotificationData(payload: String, payloadVersion: String, userId: String) -> Void {
        VoiceAppLogger.debug(TAG: TAG, message: "Sending push notification data function")
        
        VoiceAppLogger.debug(TAG: TAG, message: "Push notification data:")
        VoiceAppLogger.debug(TAG: TAG, message: "Subscriber Name: \(userId)")
        VoiceAppLogger.debug(TAG: TAG, message: "Payload Version: \(payloadVersion)")
        VoiceAppLogger.debug(TAG: TAG, message: "Payload: \(payload)")
        
       
        var sessionData:[String:String] = [:]
        if nil != exotelVoiceClient {
            do {
                sessionData["payload"] = payload
                sessionData["payloadVersion"] = payloadVersion
                sessionData["subscriberName"] = userId
                _ = try exotelVoiceClient?.relaySessionData(payload: sessionData)
            } catch {
                VoiceAppLogger.debug(TAG: TAG, message: "Exception")
            }
        }
    }
    
    public func initialize(hostname: String, subscriberName: String, accountSid: String, subscriberToken: String, displayName: String) {
        DispatchQueue.main.async {
            VoiceAppLogger.debug(TAG: self.TAG, message: "Initialize Sample App service")
            self.exotelVoiceClient = ExotelVoiceClientSDK.getExotelVoiceClient()
            self.exotelVoiceClient?.setEventListener(eventListener: self)
            VoiceAppLogger.debug(TAG: self.TAG, message: "SDK initialized is: \(self.exotelVoiceClient?.isInitialized() ?? false)")
            let content = ["DeviceId": UIDevice.current.identifierForVendor?.uuidString,
                           "DeviceType": "ios"]
            self.exotelVoiceClient?.initialize(context: content as [String : Any], hostname: hostname, subscriberName: subscriberName, displayName: displayName, accountSid: accountSid, subscriberToken: subscriberToken)
            self.callController = self.exotelVoiceClient?.getCallController()
            self.callController?.setCallListener(callListener: self)
            
            VoiceAppLogger.debug(TAG: self.TAG, message: "Returning from exotel voice client init")
        }
    }
    
    public func getVersionDetails()  -> String {
        VoiceAppLogger.debug(TAG: TAG, message: "Getting Version details in sample app")
        let message = ExotelVoiceClientSDK.getVersion()
        return message
    }
    
    public func onReceivePushNotification(pnData: PushNotificationData) {
        VoiceAppLogger.debug(TAG: TAG, message: "Enter: OnReceivePushNotification for: \(pnData.subscriberName)")
        
        sendPushNotificationData(payload: pnData.payload, payloadVersion: pnData.payloadVersion, userId: pnData.subscriberName)
        VoiceAppLogger.debug(TAG: TAG, message: "Exit: OnReceivePushNotification")
    }
    
    public func getLatestCallDetails() -> CallDetails? {
        VoiceAppLogger.debug(TAG: TAG, message: "getLatestCallDetails")
        if(nil == callController) {
            VoiceAppLogger.debug(TAG: TAG, message: "No CallController. returning nil")
            return nil
        }
        return callController?.getLatestCallDetails()
    }
    
    public func getCallFromCallId(callId: String) -> Call? {
        VoiceAppLogger.debug(TAG: TAG, message: "Getting Call Object for CallId \(callId)")
        if(nil == callController) {
            VoiceAppLogger.debug(TAG: TAG, message: "No CallController. returning nil for CallId \(callId)")
            return nil
        }
        return callController?.getCallFromCallId(callId: callId)
    }
    
    public func deinitialize() -> Bool {
        VoiceAppLogger.debug(TAG: TAG, message: "Start: De-Initialize Voice App Service")
        
        UserDefaults.standard.reset()
        reset()
        
        if exotelVoiceClient?.isInitialized() ?? false {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to De-Initialize Voice App Service")
            VoiceAppLogger.debug(TAG: TAG, message: "End: De-Initialize Voice App Service")
            return false
        }
        
        VoiceAppLogger.debug(TAG: TAG, message: "End: De-Initialize Voice App Service")
        VoiceAppLogger.debug(TAG: TAG, message: "SDK reset completed")
        return true
    }
    
    public func reset() {
        VoiceAppLogger.debug(TAG: TAG, message: "Reset Sample application Service")
        
        if(nil == exotelVoiceClient || !(exotelVoiceClient?.isInitialized() ?? false)) {
            VoiceAppLogger.debug(TAG: TAG, message: "SDK is not yet initialized")
        }
        do {
            try exotelVoiceClient?.reset()
        } catch let resetError as ExotelVoiceError {
            VoiceAppLogger.debug(TAG: TAG, message: "Exception in reset: \(resetError.getErrorMessage())")
        } catch let error {
            VoiceAppLogger.debug(TAG: TAG, message: "\(error.localizedDescription)")
        }
        
        VoiceAppLogger.debug(TAG: TAG, message: "End: Reset in Sample App Service")
    }
    
    private func dialSDK(destination: String, _ message: String) throws -> Call? {
        var call: Call?
        VoiceAppLogger.debug(TAG: TAG, message: "In Dial API in Sample Service, SDK state: \(exotelVoiceClient?.isInitialized() ?? false)")
        VoiceAppLogger.debug(TAG: TAG, message: "Destination is: \(destination)")
        do {
            try call = callController?.dial(remoteID: destination, message: message)
        } catch let callError as ExotelVoiceError {
            VoiceAppLogger.debug(TAG: TAG, message: "Exception in dialSDK: \(callError.getErrorMessage())")
            
            if callError.getErrorType() != .INVALID_DIAL_INFO {
                let lastDialNo = UserDefaults.standard.string(forKey: UserDefaults.Keys.lastDialedNumber.rawValue) ?? destination
                let date = Date().description
                let result = databaseHelper.insertData(callerId: lastDialNo, callType: .OUTGOING, time: date)
                if result {
                    VoiceAppLogger.debug(TAG: TAG, message: "Inserted to recent calls table in database")
                }
            }
            var errMsg = callError.getErrorMessage()
            if callError.getErrorType() == .MISSING_PERMISSION {
                errMsg = missingMicrophonePermissionStr
            }
            throw VoiceAppError(module: "ExotelVoiceClient", localizedDescription: errMsg)
        } catch let error {
            VoiceAppLogger.debug(TAG: TAG, message: "Genral exception in dialSDK \(error.localizedDescription)")
            
            let lastDialNo = UserDefaults.standard.string(forKey: UserDefaults.Keys.lastDialedNumber.rawValue) ?? destination
            let date = Date().description
            let result = databaseHelper.insertData(callerId: lastDialNo, callType: .OUTGOING, time: date)
            if result {
                VoiceAppLogger.debug(TAG: TAG, message: "Inserted to recent calls table in database")
            }
            
            throw VoiceAppError(module: "Exotel Voice Client", localizedDescription: error.localizedDescription)
        }
        return call
    }
    
    public func setIsReadyToReceiveCalls(flag:DarwinBoolean){
        self.isReadyToReceiveCalls = flag
    }
    public func getIsReadyToReceiveCalls() -> DarwinBoolean{
        return self.isReadyToReceiveCalls
    }
    
    public func dial(destination: String) throws -> Call? {
        return try dialSDK(destination: destination, "")
    }
    
    public func dial(destination: String, message: String) throws -> Call? {
        return try dialSDK(destination: destination, message)
    }
    
    public func hangup() throws {
        if (nil == mCall) {
            let message = "Call Object is NULL"
            VoiceAppLogger.error(TAG: TAG, message: message)
            throw VoiceAppError(module: TAG, localizedDescription: message)
        }
        do {
            try mCall?.hangup()
        } catch {
            VoiceAppLogger.error(TAG: TAG, message: "Exception in call hangup with CallId: \(String(describing: mCall?.getCallDetails().getCallId()))")
        }
    }
    
    public func enableSpeaker() {
        if(nil != mCall) {
            mCall?.enableSpeaker()
        }
    }
    
    public func disableSpeaker() {
        if (nil != mCall) {
            mCall?.disableSpeaker()
        }
    }
    
    public func enableBluetooth() {
        if(nil != mCall) {
            mCall?.enableBluetooth()
        }
    }
    
    public func disableBluetooth() {
        if (nil != mCall) {
            mCall?.disableBluetooth()
        }
    }
    
    public func getCallAudioState() -> CallAudioRoute {
        if (mCall != nil) {
            return mCall?.getAudioRoute() ?? .EARPIECE
        }
        return .EARPIECE
    }
    
    
    
    public func mute() {
        if (nil != mCall) {
            mCall?.mute()
        }
    }
    
    public func unmute() {
        if(nil != mCall) {
            mCall?.unmute()
        }
    }
    
    public func answer() {
        if(nil != mCall) {
            do {
                tonePlayback.resetTonePlayback()
                try mCall?.answer()
            } catch {
                VoiceAppLogger.error(TAG: TAG, message: "Exception in call answer ")
            }
        }
    }
    
    public func getCallDuration() -> Int {
        if (nil == mCall) {
            return -1
        }
        
        let duration:Int = mCall?.getCallDetails().getCallDuration() ?? -1
        return duration
    }
    
    public func getStatistics() -> CallStatistics? {
        return mCall?.getCallStatistics() ?? nil
    }
    
    public func getRingingDuration() -> Int {
        let currentTime:Double = Date().timeIntervalSinceNow
        let diff:Int = Int(currentTime - ringingStartTime)
        return diff
    }
    
    public func uploadLogs(startDate: Date, endDate: Date, description: String) -> Void {
        VoiceAppLogger.getSignedUrlForLogUpload(description: description)
        exotelVoiceClient?.uploadLogs(startDate: startDate, endDate: endDate, description: description)
    }
    
    public func postFeedback(rating: Int, issue: CallIssue) throws {
        do {
            if nil != mPreviousCall {
                try mPreviousCall?.postFeedback(rating: rating, issue: issue)
            } else {
                VoiceAppLogger.error(TAG: TAG, message: "Call handle is NULL, cannot post feedback")
            }
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Post feedback error: \(error.localizedDescription)")
            throw VoiceAppError(module: TAG, localizedDescription: error.localizedDescription)
        }
    }
    
    public func sendDtmf(digit: Character) throws {
        VoiceAppLogger.debug(TAG: TAG, message: "Sending DTMF digit: \(digit)")
        do {
            try mCall?.sendDtmf(digit: digit)
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to send DTMF digit: \(digit). Error: \(error.localizedDescription)")
            throw VoiceAppError(module: TAG, localizedDescription: error.localizedDescription)
        }
    }
    
    public func getCurrentStatus() -> VoiceAppStatus {
        let status = VoiceAppStatus()
        VoiceAppLogger.debug(TAG: TAG, message: "Start: getCurrentStatus")
        
        if (nil == exotelVoiceClient) {
            VoiceAppLogger.debug(TAG: TAG, message: "VOIP Client is not initialized")
            status.setMessage(message: "Not Initialized")
            status.setState(state: .STATUS_NOT_INITIALIZED)
            return status
        }
        
        if(!(exotelVoiceClient?.isInitialized() ?? false)) {
            if(initializationInProgress) {
                VoiceAppLogger.debug(TAG: TAG, message: "Initialization In Progress")
                status.setMessage(message: "Init in Progress - Please wait")
                status.setState(state: .STATUS_INITIALIZATION_IN_PROGRESS)
            } else {
                var message = "Not Initialized: "
                if !initializationErrorMessage.isEmpty {
                    message += initializationErrorMessage
                }
                VoiceAppLogger.error(TAG: TAG, message: message)
                status.setMessage(message: message)
                status.setState(state: .STATUS_INITIALIZATION_FAILURE)
            }
            return status
        }
        
        status.setMessage(message: "Ready")
        status.setState(state: .STATUS_READY)
        VoiceAppLogger.debug(TAG: TAG, message: "End: getCurrentStatus")
        return status
    }
    
    public func displayCallStatistics() {
        if mCall != nil {
            let callState = mCall?.getCallDetails().getCallState()
            if callState == .ESTABLISHED || callState == .MEDIA_ACTIVE {
                let statistics = getStatistics()
                if let callStatistics = statistics {
                    VoiceAppLogger.debug(TAG: TAG, message: "Call Statistics Data::")
                    VoiceAppLogger.debug(TAG: TAG, message: "Average Jitter (ms): \(callStatistics.getAverageJitterMs())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Max Jitter (ms): \(callStatistics.getMaxJitterMs())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Fraction Lost: \(callStatistics.getFractionLost())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Cumulative Lost: \(callStatistics.getCumulativeLost())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Extended Max: \(callStatistics.getExtendedMax())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Jitter Samples: \(callStatistics.getJitterSamples())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Jitter Buffer (ms): \(callStatistics.getJitterBufferMs())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Preferred Jitter Buffer (ms): \(callStatistics.getPreferredJitterBufferMs())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Round Trip Time (ms): \(callStatistics.getRttMs())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Bytes Sent: \(callStatistics.getBytesSent())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Packets Sent: \(callStatistics.getPacketsSent())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Bytes Received: \(callStatistics.getBytesReceived())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Packets Received: \(callStatistics.getPacketsReceived())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Codec Name: \(callStatistics.getCodecName())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Mean Opinion Score: \(callStatistics.getMOS())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Remote Fraction Loss: \(callStatistics.getRemoteFractionLoss())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Last SR Timestamp: \(callStatistics.getLastSRTimestamp())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Audio Bit Rate: \(callStatistics.getAudioBitRate())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Seconds: \(callStatistics.getSeconds())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Duration: \(callStatistics.getDuration())")
                    VoiceAppLogger.debug(TAG: TAG, message: "No Packets Time: \(callStatistics.getNoPacketsTime())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Average Latency: \(callStatistics.getAverageLatency())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Latency Jitter: \(callStatistics.getLatencyJitter())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Current Packet Loss Rate: \(callStatistics.getCurrentPacketLossRate())")
                    VoiceAppLogger.debug(TAG: TAG, message: "Media Waiting Time (ms): \(callStatistics.getMediaWaitingTimeMs())")
                }
            }
        }
    }
}

extension VoiceAppService: ExotelVoiceClientEventListener {
    public func onInitializationSuccess() {
        VoiceAppLogger.debug(TAG: TAG, message: "Initialization Success")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: initSuccessKey), object: nil, userInfo: ["payload": "success"])
    }
    
    public func onInitializationFailure(error: ExotelVoiceError) {
        VoiceAppLogger.debug(TAG: TAG, message: "Initialization Failure")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: initFailedKey), object: nil, userInfo: ["payload": error])
    }
    
    public func onLog(level: LogLevel, tag: String, message: String) {
        if (LogLevel.DEBUG == level) {
            VoiceAppLogger.debug(TAG: tag, message: message)
        } else if (LogLevel.INFO == level) {
            VoiceAppLogger.info(TAG: tag, message: message)
        } else if (LogLevel.WARNING == level) {
            VoiceAppLogger.warning(TAG: tag, message: message)
        } else if (LogLevel.ERROR == level) {
            VoiceAppLogger.error(TAG: tag, message: message)
        }
    }
    
    public func onUploadLogSuccess() {
        VoiceAppLogger.debug(TAG: TAG, message: "On UploadLog success")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: uploadLogSuccess), object: nil, userInfo: ["payload": "success"])
    }
    
    public func onUploadLogFailure(error: ExotelVoiceError) {
        VoiceAppLogger.debug(TAG: TAG, message: "Log upload failed")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: uploadLogFailure), object: error, userInfo: nil)
    }
    
    public func onAuthenticationFailure(error: ExotelVoiceError) {
        VoiceAppLogger.debug(TAG: TAG, message: "Failed to authenticate: Type: \(error.getErrorType()) message: \(error.getErrorMessage())")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: authFailedKey), object: error, userInfo: ["payload": error])
    }
}

extension VoiceAppService: CallListener {
    public func onIncomingCall(call: Call) {
        VoiceAppLogger.debug(TAG: TAG, message: "Incoming Call Received, CallId: \(call.getCallDetails().getCallId()) remoteId: \(call.getCallDetails().getRemoteId()) context: \(call.getContextMessage())")
        tonePlayback.playRingTone()
        mCall = call
        let userInfo: [String: Any] = ["callState": CallState.INCOMING, "callerID": call.getCallDetails().getRemoteId(), "callerName": call.getCallDetails().getRemoteId(), "context": call.getContextMessage()]
        // Dalay added  for background incoming call because Accept Reject Popup needs to come after  HomeViewController view appears
        if(isReadyToReceiveCalls==false){
            let seconds = 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: incomingCallKey), object: call, userInfo: userInfo)
            }
        }else{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: incomingCallKey), object: call, userInfo: userInfo)
        }
    }
    
    public func onCallInitiated(call: Call) {
        VoiceAppLogger.debug(TAG: TAG, message: "On Call Initiated")
        mCall = call
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: initiateCallKey), object: call)
        VoiceAppLogger.debug(TAG: TAG, message: "End: OnCallInitiated")
    }
    
    public func onCallRinging(call: Call) {
        VoiceAppLogger.debug(TAG: TAG, message: "On Call Ringing")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ringingCallKey), object: call)
    }
    
    public func onCallEstablished(call: Call) {
        VoiceAppLogger.debug(TAG: TAG, message: "On Call Established")
        
        tonePlayback.resetTonePlayback()
        displayCallStatistics()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: establishedCallKey), object: call)
    }
    
    public func onCallDisrupted() {
        VoiceAppLogger.debug(TAG: TAG, message: "On Call Disrupted")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: disruptedCallKey), object: nil)
    }
    
    public func onCallRenewed() {
        VoiceAppLogger.debug(TAG: TAG, message: "On Call Renewed")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: renewedCallKey), object: nil)
    }
    
    public func onCallEnded(call: Call) {
        VoiceAppLogger.debug(TAG: TAG, message: "On Call Ended")
        
        mPreviousCall = call
        tonePlayback.resetTonePlayback()
        if CallEndReason.BUSY == call.getCallDetails().getCallEndReason() {
            VoiceAppLogger.debug(TAG: TAG, message: "Playing busy tone")
            tonePlayback.playBusyTone()
        } else {
            VoiceAppLogger.debug(TAG: TAG, message: "Playing reorder tone")
            tonePlayback.playReorderTone()
        }
        
        let callerId = UserDefaults.standard.string(forKey: UserDefaults.Keys.lastDialedNumber.rawValue) ?? call.getCallDetails().getRemoteId()
        var callType: CallType
        let callDirection = call.getCallDetails().getCallDirection()
        if callDirection == CallDirection.OUTGOING {
            callType = .OUTGOING
        } else if callDirection == CallDirection.INCOMING {
            callType = .INCOMING
        } else {
            callType = .MISSED
        }
        let callSartedTime = call.getCallDetails().getCallStartedTime()
        let date = Date(timeIntervalSinceNow: (callSartedTime / 1000.0))
        let result = databaseHelper.insertData(callerId: callerId, callType: callType, time: date.description)
        if result {
            VoiceAppLogger.debug(TAG: TAG, message: "Inserted to recent calls table in database")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: endedCallKey), object: call)
    }
    
    public func onMissedCall(remoteId: String, time: Date) {
        VoiceAppLogger.debug(TAG: TAG, message: "on Missed Call")
        let userInfo:[String:Any] = ["destination": remoteId, "date": time]
        
        let callerId = UserDefaults.standard.string(forKey: UserDefaults.Keys.lastDialedNumber.rawValue) ?? remoteId
        let callType: CallType = CallType.MISSED
        
        tonePlayback.resetTonePlayback()
        VoiceAppLogger.debug(TAG: TAG, message: "Playing waiting tone")
        tonePlayback.playWaitingTone()
        
        let result = databaseHelper.insertData(callerId: callerId, callType: callType, time: time.description)
        if result {
            VoiceAppLogger.debug(TAG: TAG, message: "Inserted to recent calls table in database")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: missedCallKey), object: userInfo)
    }
}
