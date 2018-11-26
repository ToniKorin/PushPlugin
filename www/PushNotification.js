var PushNotification = function() {
};


// Call this to register for push notifications. Content of [options] depends on whether we are working with APNS (iOS) or GCM (Android)
PushNotification.prototype.register = function(successCallback, errorCallback, options) {
    if (errorCallback == null) { errorCallback = function() {}}

    if (typeof errorCallback != "function")  {
        console.log("PushNotification.register failure: failure parameter not a function");
        return
    }

    if (typeof successCallback != "function") {
        console.log("PushNotification.register failure: success callback parameter must be a function");
        return
    }

    cordova.exec(successCallback, errorCallback, "PushPlugin", "register", [options]);
};

// Call this to unregister for push notifications
PushNotification.prototype.unregister = function(successCallback, errorCallback, options) {
    if (errorCallback == null) { errorCallback = function() {}}

    if (typeof errorCallback != "function")  {
        console.log("PushNotification.unregister failure: failure parameter not a function");
        return
    }

    if (typeof successCallback != "function") {
        console.log("PushNotification.unregister failure: success callback parameter must be a function");
        return
    }

     cordova.exec(successCallback, errorCallback, "PushPlugin", "unregister", [options]);
};

    // Call this if you want to show toast notification on WP8
    PushNotification.prototype.showToastNotification = function (successCallback, errorCallback, options) {
        if (errorCallback == null) { errorCallback = function () { } }

        if (typeof errorCallback != "function") {
            console.log("PushNotification.register failure: failure parameter not a function");
            return
        }

        cordova.exec(successCallback, errorCallback, "PushPlugin", "showToastNotification", [options]);
    }
// Call this to set the application icon badge
PushNotification.prototype.setApplicationIconBadgeNumber = function(successCallback, errorCallback, badge) {
    if (errorCallback == null) { errorCallback = function() {}}

    if (typeof errorCallback != "function")  {
        console.log("PushNotification.setApplicationIconBadgeNumber failure: failure parameter not a function");
        return
    }

    if (typeof successCallback != "function") {
        console.log("PushNotification.setApplicationIconBadgeNumber failure: success callback parameter must be a function");
        return
    }

    cordova.exec(successCallback, errorCallback, "PushPlugin", "setApplicationIconBadgeNumber", [{badge: badge}]);
};

// Create and show a local Android notification
PushNotification.prototype.localNotification = function(messageInfo) {
    cordova.exec(null, null, "PushPlugin", "localNotification", [messageInfo]);
};

// Call this to set/reset/unset auto increment of Android message number
PushNotification.prototype.setAutoMessageCount = function(count) {
    cordova.exec(null, null, "PushPlugin", "setAutoMessageCount", [count]);
};

// Call this to clear notification from Android notification center
PushNotification.prototype.cancelNotification = function(id) {
    cordova.exec(null, null, "PushPlugin", "cancelNotification", [id]);
};

// https://github.com/phonegap-build/PushPlugin/issues/288#issuecomment-72121589
// Call this after IOS background task is done (max 30 sec)
PushNotification.prototype.backgroundDone = function(successCallback, errorCallback) {
    if (errorCallback == null) { errorCallback = function() {}}

    if (typeof successCallback != "function") {
        console.log("PushNotification.backgroundDone failure: success callback parameter must be a function");
        return
    }

     cordova.exec(successCallback, errorCallback, "PushPlugin", "didCompleteBackgroundProcess", []);
};

//-------------------------------------------------------------------
// Essential diagnostic services, which affects the plugin
//

// Open app settings view
PushNotification.prototype.switchToSettings = function(successCallback,errorCallback,mode) {
    cordova.exec(successCallback, errorCallback, "PushPlugin", "switchToSettings", [mode]);
};

// Background refresh status  (iOS only)
PushNotification.prototype.getBackgroundRefreshStatus = function(successCallback) {
    cordova.exec(successCallback, null, "PushPlugin", "getBackgroundRefreshStatus", []);
};
// Is background refresh enabled (iOS only)
PushNotification.prototype.isBackgroundRefreshEnabled = function(successCallback) {
    PushNotification.getBackgroundRefreshStatus(function(status){
        successCallback(status === "GRANTED");
    });
};

// Low power mode status (iOS only)
PushNotification.prototype.getLowPowerModeStatus = function(successCallback) {
    cordova.exec(successCallback, null, "PushPlugin", "getLowPowerModeStatus", []);
};
// Is normal power mode (iOS only)
PushNotification.prototype.isNormalPowerMode = function(successCallback) {
    PushNotification.getLowPowerModeStatus(function(status){
        successCallback(status === "DISABLED");
    });
};

// Location service status
PushNotification.prototype.getLocationServiceStatus = function(successCallback) {
    cordova.exec(successCallback, null, "PushPlugin", "getLocationServiceStatus", []);
};
// Is location service enabled (iOS only)
PushNotification.prototype.isLocationServiceEnabled = function(successCallback) {
    PushNotification.getLocationServiceStatus(function(status){
        successCallback(status === "GRANTED");
    });
};


// ------------------------------------------------------------------

if(!window.plugins) {
    window.plugins = {};
}
if (!window.plugins.pushNotification) {
    window.plugins.pushNotification = new PushNotification();
}

if (typeof module != 'undefined' && module.exports) {
  module.exports = PushNotification;
}