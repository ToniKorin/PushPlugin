## ChangeLog
#### Version 2.4.2 (2.8.2023)
- Android 12 (version 31) compatibility

#### Version 2.3.13 (15.10.2022)
- Removed Android power save mode status lowPowerStandbyEnabled for now

#### Version 2.3.12 (12.10.2022)
- Android power save mode statuses (ignoreBatteryOptimization and lowPowerStandbyEnabled)

#### Version 2.3.11 (23.7.2020)
- Location and power save mode status check update for Android API level 28 and 29

#### Version 2.3.10 (15.7.2020)
- iOS Push token fixed for 13 SDK

#### Version 2.3.9 (21.7.2019)
- Added diagnostic for Android Battery Saver

#### Version 2.3.4 (5.12.2018)
- More fixes for diagnostic services

#### Version 2.3.1 (2.12.2018)
- Fixes for diagnostic services

#### Version 2.3.0 (26.11.2018)
- Added essential diagnostic services

#### Version 2.2.3 (21.9.2018)
- Improved token refresh handling

#### Version 2.2.2 (10.7.2018)
- Fixed IllegalStateException in PushInstanceIDListenerService for Android 8 and later 

#### Version 2.2.1 (3.5.2018)
- Replaced GCM by basic support for Firebase messaging 

#### Version 2.1.12 (23.4.2018)
- Added basic support for android 8 and its message channels 

#### Version 2.1.11 (4.2.2018)
- Number field visibility fix for android 7 and later

#### Version 2.1.8 (27.1.2018)
- Number field visibility fix for android 7 and later

#### Version 2.1.7 (26.1.2018)
- Time visibility fix for android 7 and later

#### Version 2.1.6 (27.6.2017)
- Number field visibility fix for android 7 and later

#### Version 2.1.5 (11.12.2016)
- Xcode8 and ios10 compatibility fix for Missing Push Notification Entitlement problem, requires CLI-6.4.0

#### Version 2.1.4 (24.5.2016)
- Android local notification support
- iOS fix for Cordova 6.x compatibility 

#### Version 2.0.0 (6.10.2015)
- Moved plugin to npm

#### Version 1.1.3 (6.10.2015)
- Added tapNotificationToStartApp parameter for Android to optionally start the paused app, when user is tapping the notification

#### Version 1.1.2 (24.7.2015)
- Added setAutoMessageCount for Android to optionally increase the message count automatically

#### Version 1.1.1 (8.7.2015)
- Removed GET_ACCOUNTS permission (not required on devices running Android 4.0.4 or higher)

#### Version 1.1.0 (7.7.2015)
- Android background task support

#### Version 1.0.1 (25.6.2015)
- Tuning of iOS foreground status

#### Version 1.0.0 (14.5.2015)
- Initial version inspired by https://github.com/jbeuckm/PushPlugin and
  https://github.com/phonegap-build/PushPlugin/issues/288#issuecomment-72121589