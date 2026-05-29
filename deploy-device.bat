@echo off
title CapitalMonero - Deploy to USB device
SET DART_VM_OPTIONS=--old_gen_heap_size=512
SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
SET JAVA_TOOL_OPTIONS=-Xmx768m -XX:+UseSerialGC

echo Checking for connected devices...
adb devices
echo.

echo Building debug APK (low-memory mode)...
flutter build apk --debug --no-pub --flavor production
if errorlevel 1 (
    echo Build failed.
    pause
    exit /b 1
)

set APK=build\app\outputs\flutter-apk\app-production-debug.apk
if not exist %APK% (
    set APK=build\app\outputs\flutter-apk\app-debug.apk
)

echo Installing %APK%
adb install -r -d "%APK%"
if errorlevel 1 (
    echo Install failed.
    pause
    exit /b 1
)

echo Launching CapitalMonero on device...
adb shell monkey -p com.capitalmonero.app.debug -c android.intent.category.LAUNCHER 1

echo.
echo Tailing logcat (Ctrl+C to stop)...
adb logcat -v color "flutter:V CapitalMonero:V *:S"
pause
