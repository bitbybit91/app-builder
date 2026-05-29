# CapitalMonero PowerShell builder - low-memory mode for DESKTOP-P43AJUM.
# Designed for AMD E1-2100 / 4 GB RAM Windows 10 hosts.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\local-build.ps1

$ErrorActionPreference = 'Stop'

$Env:DART_VM_OPTIONS  = '--old_gen_heap_size=512'
$Env:GRADLE_OPTS      = '-Xmx512m -Dfile.encoding=UTF-8'
$Env:JAVA_TOOL_OPTIONS = '-Xmx768m -XX:+UseSerialGC'
$Env:PUB_CACHE        = Join-Path $Env:USERPROFILE '.pub-cache'

function Write-Section($text) {
    Write-Host ''
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host $text -ForegroundColor Cyan
    Write-Host '============================================' -ForegroundColor Cyan
}

function Show-Memory() {
    $mem = Get-CimInstance Win32_OperatingSystem
    $freeGb = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
    $totalGb = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
    Write-Host ("Free RAM: {0} GB / {1} GB" -f $freeGb, $totalGb) -ForegroundColor Yellow
}

function Stop-OrphanProcesses() {
    Get-Process -ErrorAction SilentlyContinue dart.exe, dart, java.exe, java, gradle, kotlinc |
        Where-Object { $_.MainWindowHandle -eq 0 } |
        ForEach-Object {
            Write-Host ("Killing orphan {0} (PID {1})" -f $_.ProcessName, $_.Id) -ForegroundColor DarkYellow
            try { Stop-Process -Id $_.Id -Force -ErrorAction Stop } catch {}
        }
}

function Invoke-Step([string]$Label, [scriptblock]$Action) {
    Write-Section $Label
    Show-Memory
    Stop-OrphanProcesses
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $sw.Stop()
        Write-Host ("✓ {0} completed in {1:N1}s" -f $Label, $sw.Elapsed.TotalSeconds) -ForegroundColor Green
    } catch {
        $sw.Stop()
        Write-Host ("✗ {0} failed after {1:N1}s: {2}" -f $Label, $sw.Elapsed.TotalSeconds, $_) -ForegroundColor Red
        throw
    } finally {
        Stop-OrphanProcesses
    }
}

function Show-Menu() {
    Write-Host ''
    Write-Host 'CapitalMonero builder' -ForegroundColor Magenta
    Write-Host '  1) flutter pub get'
    Write-Host '  2) build_runner (low resources)'
    Write-Host '  3) gen-l10n'
    Write-Host '  4) flutter test'
    Write-Host '  5) flutter analyze'
    Write-Host '  6) Android APK (debug)'
    Write-Host '  7) Android APK (release)'
    Write-Host '  8) Android AAB (release)'
    Write-Host '  9) Android APK (fdroid)'
    Write-Host ' 10) Run on USB device (debug)'
    Write-Host ' 11) Full clean rebuild'
    Write-Host ' 12) Exit'
}

while ($true) {
    Show-Menu
    $choice = Read-Host 'Choice'
    switch ($choice) {
        '1'  { Invoke-Step 'pub get'      { flutter pub get } }
        '2'  { Invoke-Step 'build_runner' { dart run build_runner build --delete-conflicting-outputs --low-resources-mode } }
        '3'  { Invoke-Step 'gen-l10n'     { flutter gen-l10n } }
        '4'  { Invoke-Step 'tests'        { flutter test --no-pub --reporter compact } }
        '5'  { Invoke-Step 'analyze'      { flutter analyze --no-pub } }
        '6'  { Invoke-Step 'APK debug'    { flutter build apk --debug --no-pub --flavor production } }
        '7'  { Invoke-Step 'APK release'  { flutter build apk --release --no-pub --flavor production } }
        '8'  { Invoke-Step 'AAB release'  { flutter build appbundle --release --no-pub --flavor production } }
        '9'  { Invoke-Step 'APK fdroid'   { flutter build apk --release --no-pub --flavor fdroid } }
        '10' { Invoke-Step 'run device'   { flutter run --debug --no-pub --flavor production } }
        '11' {
            Invoke-Step 'clean'        { flutter clean }
            Invoke-Step 'pub get'      { flutter pub get }
            Invoke-Step 'build_runner' { dart run build_runner build --delete-conflicting-outputs --low-resources-mode }
            Invoke-Step 'gen-l10n'     { flutter gen-l10n }
            Invoke-Step 'APK debug'    { flutter build apk --debug --no-pub --flavor production }
        }
        '12' { break }
        Default { Write-Host 'Unknown choice' -ForegroundColor Red }
    }
}
