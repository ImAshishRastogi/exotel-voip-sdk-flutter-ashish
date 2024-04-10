
import 'dart:developer';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../Service/PushNotificationService.dart';
import 'ExotelSDKCallback.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class ExotelSDKClient {
  // static const platform = MethodChannel('your_channel_name');

  static final ExotelSDKClient _instance = ExotelSDKClient._internal();

  MethodChannel? channel;

  ExotelSDKCallback? mCallBack;
  static ExotelSDKClient getInstance() {
    return _instance;
  }

  ExotelSDKClient._internal();

  void registerMethodHandler() {
    if(Platform.isAndroid) channel = MethodChannel('android/exotel_sdk');
    if(Platform.isIOS) channel = MethodChannel('ios/exotel_sdk');
    // handle messages from android to flutter
    channel!.setMethodCallHandler(flutterCallHandler);
  }
  // Example: A method to invoke a native API
  // static Future<void> invokeNativeApi() async {
  //   try {
  //     await platform.invokeMethod('your_native_method_name');
  //   } on PlatformException catch (e) {
  //     print('Error invoking native API: ${e.message}');
  //   }
  // }
  Future<String> logIn(String userId,String password,String accountSid,String hostname) async{
    log("login button function start");
    try {
      String? fcmToken = "";
      await PushNotificationService.getInstance().getToken().then((value) {
        fcmToken = value;
      });
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      String res = await channel?.invokeMethod('login', {'appHostname': hostname ,'username': userId , 'account_sid': accountSid , 'password':password,'fcm_token':fcmToken});
      return res;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String> call(String userId, String dialTo) async{
    log("call button function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('call', {'username': userId ,  'dialTo':dialTo});
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }

  }

  Future<String> logout() async{
    log("login button function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('logout');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }

  }

  Future<String> mute() async{
    log("mute function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('mute');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> unmute() async{
    log("unmute function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('unmute');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> enableSpeaker() async{
    log("enableSpeaker function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('enableSpeaker');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> disableSpeaker() async{
    log("disableSpeaker function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('disableSpeaker');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> enableBluetooth() async{
    log("enableBluetooth function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('enableBluetooth');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> disableBluetooth() async{
    log("disableBluetooth function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('disableBluetooth');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> hangup() async{
    log("hangup function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('hangup');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> answer() async{
    log("answer function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('answer');
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> sendDtmf(String digit) async{
    log("sendDtmf function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('sendDtmf',{'digit': digit});
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  Future<String> lastCallFeedback(int? rating, String? issue) async{
    log("lastCallFeedback function start");
    log(" rating : $rating issue: $issue");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      return await channel?.invokeMethod('lastCallFeedback',{'rating': rating, 'issue':issue });
      //loading UI
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }


  Future<bool> checkLoginStatus() async{
    log("login button function start");
    try {
      String response = await channel?.invokeMethod('isloggedin');
      return response.toLowerCase() == 'true';
    } catch (e) {
      print("Failed to Invoke: '${e.toString()}'.");
      return false;
    }
  }


  Future<bool> loginstatus() async {
    bool isLoggedIn = await checkLoginStatus();
    print('Is logged in: $isLoggedIn');
    return false;
  }

  Future<String> checkVersionDetails() async{
    log("checkVersionDetails function start");
    try {
      String response = await channel?.invokeMethod('version');
      return response;
    } catch (e) {
      print("Failed to Invoke: '${e.toString()}'.");
      rethrow;
    }
  }

  Future<String> uploadLogs(DateTime startDate, DateTime endDate, String description) async{
    log("uploadLogs function start");

    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
      String startDateString = startDate.toIso8601String();
      String endDateString = endDate.toIso8601String();
      log("startDateString: $startDateString, endDateString: $endDateString");
      return await channel?.invokeMethod('uploadLogs', {
        'startDateString': startDateString,
        'endDateString': endDateString,
        'description': description,
      });    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> contacts() async{
    log("fetch contacts function start");
    String response = "";
    try {
      // [sdk-initialization-flow] send message from flutter to android for exotel client SDK initialization
       await channel?.invokeMethod('contacts');
    } catch (e) {
      response = "Failed to Invoke: '${e.toString()}'.";
      rethrow;
    }
  }

  // Future<int> checkCallDuration() async{
  //   log("checkCallDuration function start");
  //   try {
  //     int response = await channel?.invokeMethod('getCallDuration');
  //     return response;
  //   } catch (e) {
  //     print("Failed to Invoke: '${e.toString()}'.");
  //     rethrow;
  //   }
  // }
  //
  // Future<int> CallDuration() async {
  //   int duration = await checkCallDuration();
  //   print('CallDuration is: $duration');
  //   return duration;
  // }

  static Future<void> requestPermissions() async {
    // You can request multiple permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.microphone,
      Permission.notification,
      Permission.nearbyWifiDevices,
      Permission.accessMediaLocation,
      Permission.location,  Permission.bluetoothScan,
      Permission.bluetoothConnect,
      // Add other permissions you want to request
    ].request();
    // Check permission status and handle accordingly
  }

  Future<String> flutterCallHandler(MethodCall call) async {
    String loginStatus = "not ready";
    String callingStatus = "blank";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (call.method) {
      case "loggedInStatus":
        loginStatus =  call.arguments.toString();
        mCallBack?.setStatus(loginStatus);
        log("loginStatus = $loginStatus");
        if(loginStatus == "Ready"){
          mCallBack?.onLoggedInSucess();
          await prefs.setBool('isLoggedIn', true);
        } else {
          mCallBack?.onLoggedInFailure(loginStatus);
        }
        break;
      case "callStatus":
        callingStatus =  call.arguments.toString();
        log("callingStatus = $callingStatus");
        if(callingStatus == "Ringing"){
          mCallBack?.onCallRinging();
        } else if(callingStatus == "Connected"){
          mCallBack?.onCallConnected();
        }
        else if(callingStatus == "Ended"){
          mCallBack?.onCallEnded();
        }
        break;
      case "incoming"://to-do: need to refactor, need code optimization
        log("in case incoming in exotelsdkclient.dart");
        String callId = call.arguments['callId'];
        String destination = call.arguments['destination'];
        print('in FlutterCallHandler(), callId is $callId, destination is $destination ');
        mCallBack?.onCallIncoming(callId, destination);
        break;
      case "version":
        String? Version =  call.arguments.toString();
        print('in FlutterCallHandler(), version is $Version');
        mCallBack?.setVersion(Version);
        break;
      case "contacts":
        String? jsonData =  call.arguments.toString();
        print('in FlutterCallHandler(), jsonData is : $jsonData');
        mCallBack?.setjsonData(jsonData);
        await prefs.setString('jsonData', jsonData);
        break;
      default:
        break;
    }
    return "";
  }

  void relayFirebaseMessagingData(Map<String, dynamic> data) {
    channel?.invokeMethod('relayNotificationData',{'data':data});
  }

  void setExotelSDKCallback(ExotelSDKCallback callback) {
    mCallBack = callback;
  }


// Example: A method to listen for events from native code
// static void listenToNativeEvents() {
//   platform.setMethodCallHandler((call) {
//     if (call.method == 'your_native_event_name') {
//       // Handle the event data received from native code
//       final eventData = call.arguments as Map<String, dynamic>;
//       final message = eventData['message'] as String;
//       print('Received native event: $message');
//     }
//     return null;
//   });
// }

// Example: A method to send data to native code
// static Future<void> sendDataToNative(String data) async {
//   try {
//     await platform.invokeMethod('sendData', {'data': data});
//   } on PlatformException catch (e) {
//     print('Error sending data to native code: ${e.message}');
//   }
// }

// Add more methods for other communication needs (e.g., platform-specific APIs)
}
