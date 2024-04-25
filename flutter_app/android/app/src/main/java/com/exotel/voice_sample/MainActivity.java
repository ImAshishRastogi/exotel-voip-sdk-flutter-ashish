package com.exotel.voice_sample;



import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import id.flutter.flutter_background_service.BackgroundService;
import id.flutter.flutter_background_service.WatchdogReceiver;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

// This is the First Class which invoked by flutter
public class MainActivity extends FlutterActivity {
    //    private static String TAG = "MainActivity";
//    private ExotelSDKChannel exotelSDKChannel;
    private static final String CHANNEL = "android/exotel_sdk";
    private MethodChannel channel;
    private static final String TAG = "MainActivity";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        VoiceAppLogger.info(TAG,"Entry : onCreate");
    }

    @Override
    protected void onStart() {
        super.onStart();
        VoiceAppLogger.info(TAG,"Entry : onStart");
        Intent intent = new Intent(this, ExotelTranslatorService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.putExtra("foreground",true);
            startForegroundService(intent);
        } else {
            startService(intent);
        }
        bindService(intent,connection, BIND_AUTO_CREATE);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        VoiceAppLogger.info(TAG,"Entry : configureFlutterEngine");
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
    }

    private ServiceConnection connection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName className,
                                       IBinder service) {
            ExotelTranslatorService.LocalBinder binder = (ExotelTranslatorService.LocalBinder) service;
            VoiceAppLogger.debug(TAG, "In onServiceConnected() ");
            ExotelTranslatorService exotelTranslatorService  = binder.getService();

            exotelTranslatorService.registerPlatformChannel(channel);

        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            VoiceAppLogger.debug(TAG, "In onServiceDisconnected() ");

        }
    };
}