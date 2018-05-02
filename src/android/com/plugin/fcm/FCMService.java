package com.plugin.fcm;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import java.util.Map;

@SuppressLint("NewApi")
public class FCMService extends FirebaseMessagingService  {

	private static final String TAG = "FCMService";
	private static final LocalNotification localNotification = new LocalNotification();

	@Override
	public void onMessageReceived(RemoteMessage message) {

		Log.d(TAG, "onMessageReceived - from: " + message.getFrom());
        // Extract the payload from the message
        Bundle extras = new Bundle();
        for (Map.Entry<String, String> entry : message.getData().entrySet()) {
            extras.putString(entry.getKey(), entry.getValue());
        }
        if (message.getNotification() != null) {
            if (!message.getNotification().getTitle().isEmpty())
                extras.putString("title", message.getNotification().getTitle());
            if (!message.getNotification().getBody().isEmpty())
                extras.putString("message", message.getNotification().getBody());
        }

        // if we are in the foreground, just surface the payload, else post it to the statusbar
        if (PushPlugin.isInForeground()) {
            extras.putBoolean("foreground", true);
            PushPlugin.sendExtras(extras);
        }
        else {
            extras.putBoolean("foreground", false);
            Context context = getApplicationContext();
            // Create local notification if there is a message
            if (extras.getString("message") != null && extras.getString("message").length() != 0) {
                localNotification.createAndStartNotification(context, extras);
            }
            // E.g. the Cordova Background Plug-in has to be in use to process the payload
            if(PushPlugin.receiveNotificationInBackground() && PushPlugin.isActive()) {
                PushPlugin.sendExtras(extras);
            }
            // Optionally start the user defined Android background service
            String serviceClassName = extras.getString("service");
            if(serviceClassName != null && /* And app killed (or optionally also if suspended) */
                    (!PushPlugin.isActive() || PushPlugin.startServiceAlwaysInBackground() )) {
                startBackgroundService(context, extras, serviceClassName);
            }
        }
	}

	private void startBackgroundService(Context context, Bundle extras, String serviceClassName)
	{
		Log.d(TAG, "startBackgroundService");
		Intent serviceIntent = new Intent();
		serviceIntent.putExtras(extras);
		serviceIntent.setClassName(context.getApplicationContext(), serviceClassName);
		startService(serviceIntent);
	}

}
