package com.plugin.gcm;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.google.android.gcm.GCMBaseIntentService;

@SuppressLint("NewApi")
public class GCMIntentService extends GCMBaseIntentService {

	private static final String TAG = "GCMIntentService";
	private static final LocalNotification localNotification = new LocalNotification();
	public GCMIntentService() {
		super("GCMIntentService");
	}

	@Override
	public void onRegistered(Context context, String regId) {

		Log.v(TAG, "onRegistered: " + regId);

		JSONObject json;

		try
		{
			json = new JSONObject().put("event", "registered");
			json.put("regid", regId);

			Log.v(TAG, "onRegistered: " + json.toString());

			// Send this JSON data to the JavaScript application above EVENT should be set to the msg type
			// In this case this is the registration ID
			PushPlugin.sendJavascript( json );

		}
		catch( JSONException e)
		{
			// No message to the user is sent, JSON failed
			Log.e(TAG, "onRegistered: JSON exception");
		}
	}

	@Override
	public void onUnregistered(Context context, String regId) {
		Log.d(TAG, "onUnregistered - regId: " + regId);
	}

	@Override
	protected void onMessage(Context context, Intent intent) {
		Log.d(TAG, "onMessage - context: " + context);

		// Extract the payload from the message
		Bundle extras = intent.getExtras();
		if (extras != null)
		{
			// if we are in the foreground, just surface the payload, else post it to the statusbar
			if (PushPlugin.isInForeground()) {
				extras.putBoolean("foreground", true);
				PushPlugin.sendExtras(extras);
			}
			else {
				extras.putBoolean("foreground", false);
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
					startBackgroundService(context, intent, serviceClassName);
				}
			}
		}
	}

	@Override
	public void onError(Context context, String errorId) {
		Log.e(TAG, "onError - errorId: " + errorId);
	}

	private void startBackgroundService(Context context, Intent intent, String serviceClassName)
	{
		Log.d(TAG, "startBackgroundService");
		Intent serviceIntent = new Intent();
		serviceIntent.putExtras(intent);
		serviceIntent.setClassName(context.getApplicationContext(), serviceClassName);
		startService(serviceIntent);
	}

}
