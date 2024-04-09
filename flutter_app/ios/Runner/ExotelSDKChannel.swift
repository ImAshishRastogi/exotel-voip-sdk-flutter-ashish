//
//  ExotelSDKChannel.swift
//  Runner
//
//  Created by ashishrastogi on 09/04/24.
//

import Foundation

class ExotelSDKChannel {
    
    var channel:FlutterMethodChannel!
    var CHANNEL_NAME:String = "ios/exotel_sdk"
    var flutterEngine:FlutterEngine!
    
    init(flutterEngine: FlutterEngine!) {
        self.flutterEngine = flutterEngine
    }
    
    func registerMethodChannel(){
        print("registering ios Method Channel")
        channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: flutterEngine.binaryMessenger)
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            print("This is native code")
            switch call.method {
            case "isloggedin":
                result("false")
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
    
}
