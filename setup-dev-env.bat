@echo off
title CapitalMonero Dev Env Setup
echo Verifying development environment for DESKTOP-P43AJUM...
echo.

SET DART_VM_OPTIONS=--old_gen_heap_size=512
SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
SET JAVA_TOOL_OPTIONS=-Xmx768m -XX:+UseSerialGC

REM ----- Flutter -----------------------------------------------------
where flutter >NUL 2>&1
if errorlevel 1 (
    echo [FAIL] flutter is not on PATH. Install from https://docs.flutter.dev/get-started/install/windows
    goto :end
) else (
    echo [ OK ] flutter found:
    flutter --version
)

echo.

REM ----- JDK ---------------------------------------------------------
if "%JAVA_HOME%"=="" (
    echo [FAIL] JAVA_HOME is not set. Install JDK 17 and set JAVA_HOME.
    goto :end
) else (
    echo [ OK ] JAVA_HOME=%JAVA_HOME%
    "%JAVA_HOME%\bin\java" -version
)

echo.

REM ----- Android SDK ------------------------------------------------
if "%ANDROID_HOME%"=="" (
    echo [WARN] ANDROID_HOME is not set. Flutter will try to autodetect it.
) else (
    echo [ OK ] ANDROID_HOME=%ANDROID_HOME%
)

echo.

REM ----- ADB ---------------------------------------------------------
where adb >NUL 2>&1
if errorlevel 1 (
    echo [WARN] adb not on PATH. Add %%ANDROID_HOME%%\platform-tools to PATH.
) else (
    echo [ OK ] adb devices:
    adb devices
)

echo.

REM ----- Free RAM ----------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic OS get FreePhysicalMemory /value ^| find "="') do set FREE_KB=%%a
set /a FREE_MB=%FREE_KB%/1024
echo Free physical memory: %FREE_MB% MB
if %FREE_MB% LSS 3000 (
    echo [WARN] Less than 3 GB free. Close other apps before building.
)

echo.
echo Running flutter doctor --verbose
flutter doctor --verbose

:end
echo.
pause
