package com.plugin.fcm;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.FirebaseInstanceIdService;

public class PushInstanceIDListenerService extends FirebaseInstanceIdService {
    public static final String TAG = "Push_InsIdService";

    @Override
    public void onTokenRefresh() {
        // Get updated InstanceID token.
        String refreshedToken = FirebaseInstanceId.getInstance().getToken();
        Log.d(TAG, "Refreshed token: " + refreshedToken);
        if (refreshedToken!=null) {
            if (PushPlugin.isInForeground()) {
                PushPlugin.updateInstanceId(refreshedToken);
            } else {
                String tokenUpdateService = "com.tonikorin.cordova.plugin.LocationProvider.LocationService";
                try {
                    SharedPreferences sp = this.getSharedPreferences(PushPlugin.PREFS_NAME, Context.MODE_PRIVATE);
                    tokenUpdateService = sp.getString(PushPlugin.TOKEN_UPDATE_SERVICE_CLASS, tokenUpdateService);
                } catch (Exception e){
                    Log.e(TAG, "Failed to read SharedPreferences: " + e.getMessage());
                }
                Intent serviceIntent = new Intent();
                serviceIntent.putExtra("regid", refreshedToken);
                serviceIntent.setClassName(this, tokenUpdateService);
                startService(serviceIntent);
            }
        }
    }
}
