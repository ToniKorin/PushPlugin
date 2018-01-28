package com.plugin.gcm;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

/**
 * Created by korin on 15.5.2016.
 */
public class LocalNotification {

    private static final String TAG = "LocalNotification";
    public static final String MESSAGE_COUNT = "messageCount";
    public static final String AUTO_ID = "autoId";

    public void createAndStartNotification(Context context, Bundle extras)
    {
        NotificationManager mNotificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        String appName = getAppName(context);

        Intent notificationIntent = new Intent(context, PushHandlerActivity.class);
        notificationIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        notificationIntent.putExtra("pushBundle", extras);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        int defaults = Notification.DEFAULT_ALL;

        if (extras.getString("defaults") != null) {
            try {
                defaults = Integer.parseInt(extras.getString("defaults"));
            } catch (NumberFormatException e) { Log.e(TAG, "Error parsing defaults: " + e.getMessage());}
        }
        String title = extras.getString("title", "");
        NotificationCompat.Builder mBuilder =
                new NotificationCompat.Builder(context)
                        .setDefaults(defaults)
                        .setSmallIcon(context.getApplicationInfo().icon)
                        .setWhen(System.currentTimeMillis())
                        .setContentTitle(title)
                        .setTicker(title)
                        .setContentIntent(contentIntent)
                        .setAutoCancel(true);

        if (android.os.Build.VERSION.SDK_INT >= 17) { // Android 7 and later, time stamps is not visible...
            mBuilder.setShowWhen(true);
        }

        String message = extras.getString("message");
        if (message != null) {
            mBuilder.setContentText(message);
        } else {
            mBuilder.setContentText("");
        }

        String subText = extras.getString("subText");
        if (subText != null) {
            mBuilder.setSubText(subText);
        }

        String bigText = extras.getString("bigText");
        if (bigText != null) { // this overrides contextText and subText
            mBuilder.setStyle(new NotificationCompat.BigTextStyle().bigText(bigText));
        }

        if (extras.getString("progress") != null){
            mBuilder.setProgress(0,0,true);
        }

        String msgcnt = extras.getString("msgcnt");
        if (msgcnt != null) {
            mBuilder.setNumber(Integer.parseInt(msgcnt));
            if (android.os.Build.VERSION.SDK_INT > 23) { // Android 7 and later, number field is not visible...
                mBuilder.setContentTitle(title + " (" + msgcnt + ")");
            }
        } else {
            setOptAutoMessageCount(context, mBuilder, title);
        }

        int notId = 0;
        try {
            notId = Integer.parseInt(extras.getString("notId"));
        }
        catch(NumberFormatException e) {
            Log.e(TAG, "Number format exception - Error parsing Notification ID: " + e.getMessage());
        }
        catch(Exception e) {
            Log.e(TAG, "Error parsing Notification ID" + e.getMessage());
        }
        if(notId==-1){
            notId = getOptAutoId(context);
        }
        Log.v(TAG, "createAndStartNotification, ID:" + notId);

        mNotificationManager.notify(appName, notId, mBuilder.build());
    }

    public void cancelNotification(Context context, int id){
        Log.v(TAG, "cancelNotification, ID:" + id);
        NotificationManager mNotificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if(id < 0){
            mNotificationManager.cancelAll();
        }
        else {
            mNotificationManager.cancel(getAppName(context),id);
        }
    }

    public void setAutoMessageCount(Context context, int count){
        SharedPreferences sp = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sp.edit();
        if ( count >= 0 ){
            editor.putInt(MESSAGE_COUNT, count);
        } else {
            editor.remove(MESSAGE_COUNT);
        }
        editor.commit();
    }

    private void setOptAutoMessageCount(Context context, NotificationCompat.Builder mBuilder, String title) {
        SharedPreferences sp = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        int count = sp.getInt(MESSAGE_COUNT, -1);
        if (count >= 0){
            count += 1;
            mBuilder.setNumber(count);
            SharedPreferences.Editor editor = sp.edit();
            editor.putInt(MESSAGE_COUNT, count);
            editor.commit();
            if (android.os.Build.VERSION.SDK_INT > 23) { // Android 7 and later, number field is not visible...
                mBuilder.setContentTitle(title + " (" + count + ")");
            }
        }
    }

    private static String getAppName(Context context)
    {
        CharSequence appName =
                context
                        .getPackageManager()
                        .getApplicationLabel(context.getApplicationInfo());
        return (String)appName;
    }

    private int getOptAutoId(Context context) {
        SharedPreferences sp = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        int id = sp.getInt(AUTO_ID, -1);
        if (id<100){ // start autoId from 101
            id = 100;
        }
        if (id >= 0){
            id += 1;
            SharedPreferences.Editor editor = sp.edit();
            editor.putInt(AUTO_ID, id);
            editor.commit();
        }
        return id;
    }

}
