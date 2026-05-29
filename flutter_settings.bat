@echo off
REM Memory-tuned environment for low-spec hosts (4 GB RAM AMD E1-2100).
REM Source via:  call flutter_settings.bat
SET DART_VM_OPTIONS=--old_gen_heap_size=512
SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
SET JAVA_TOOL_OPTIONS=-Xmx768m -XX:+UseSerialGC
SET PUB_CACHE=%USERPROFILE%\.pub-cache
echo Flutter low-memory environment loaded.
