@echo off
title CapitalMonero Build - Low Memory Mode
echo ============================================
echo CapitalMonero Builder (4GB RAM Safe Mode)
echo Machine: DESKTOP-P43AJUM (AMD E1-2100)
echo ============================================
echo.

REM Memory constraints for 4 GB RAM system.
SET DART_VM_OPTIONS=--old_gen_heap_size=512
SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
SET JAVA_TOOL_OPTIONS=-Xmx768m -XX:+UseSerialGC
SET PUB_CACHE=%USERPROFILE%\.pub-cache

echo Free memory check:
wmic OS get FreePhysicalMemory /value
echo.

echo Select action:
echo  1) Get packages (flutter pub get)
echo  2) Run code generation (build_runner, low-resources)
echo  3) Generate localizations
echo  4) Run tests
echo  5) Analyze code
echo  6) Build Android APK (debug)
echo  7) Build Android APK (release)
echo  8) Build Android AAB (release, Play Store)
echo  9) Build Android APK (F-Droid, no Firebase)
echo 10) Deploy to USB device (debug)
echo 11) Full clean rebuild
set /p choice=Enter choice (1-11):

if "%choice%"=="1"  flutter pub get
if "%choice%"=="2"  dart run build_runner build --delete-conflicting-outputs --low-resources-mode
if "%choice%"=="3"  flutter gen-l10n
if "%choice%"=="4"  flutter test --no-pub --reporter compact
if "%choice%"=="5"  flutter analyze --no-pub
if "%choice%"=="6"  flutter build apk --debug --no-pub --flavor production
if "%choice%"=="7"  flutter build apk --release --no-pub --flavor production
if "%choice%"=="8"  flutter build appbundle --release --no-pub --flavor production
if "%choice%"=="9"  flutter build apk --release --no-pub --flavor fdroid
if "%choice%"=="10" (
    flutter run --debug --no-pub --flavor production
)
if "%choice%"=="11" (
    flutter clean
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs --low-resources-mode
    flutter gen-l10n
    flutter build apk --debug --no-pub --flavor production
)
pause
