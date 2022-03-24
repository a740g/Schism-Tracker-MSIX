@echo off

rem Enable cmd extensions and exit if not present
setlocal enableextensions
if errorlevel 1 (
    echo Error: Command Prompt extensions not available!
    goto end
)

rem Save the current directory
set "BuildRoot=%cd%\"

rem Find the Microsoft SDK path and exit if not present
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0" /v InstallationFolder 2^>nul ^| find /i "REG_SZ"') do set WinSDKDir=%%b
if not defined WinSDKDir (
    echo Error: Microsoft SDK path not found!
    goto end
)

rem Find the Microsoft SDK version and exit if not present
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0" /v ProductVersion 2^>nul ^| find /i "REG_SZ"') do set WinSDKVer=%%b
if not defined WinSDKVer (
    echo Error: Microsoft SDK version missing!
    goto end
)

rem Build the SDK bin path
if exist "%WinSDKDir%bin\" (
    set "WinSDKDirBin=%WinSDKDir%bin\"
) else (
    if exist "%WinSDKDir%\bin\" (
        set "WinSDKDirBin=%WinSDKDir%\bin\"
    ) else (
        echo Error: Microsoft SDK path "%WinSDKDir%" missing!
        goto end
    )
)

rem Build the SDK x64 version bin path
if exist "%WinSDKDirBin%%WinSDKVer%\x64\" (
    set "WinSDKDirBinx64=%WinSDKDirBin%%WinSDKVer%\x64\"
) else (
    if exist "%WinSDKDirBin%%WinSDKVer%.0\x64\" (
        set "WinSDKDirBinx64=%WinSDKDirBin%%WinSDKVer%.0\x64\"
    ) else (
        echo Error: Microsoft SDK path "%WinSDKDirBin%" missing!
        goto end
    )
)

rem Check if we are running from the MSIX build folder root directory
if exist "%BuildRoot%staging\" (
    set "BuildRootStaging=%BuildRoot%staging\"
) else (
    echo Error: This must be run from the build root directory!
    goto end
)

rem Change to the staging directory
cd "%BuildRootStaging%"

rem Do some house cleaning
del "priconfig.xml"
del "resources.pri"

rem Create the PRI config file
"%WinSDKDirBinx64%makepri.exe" createconfig /cf "%BuildRootStaging%priconfig.xml" /dq en-US

rem Create a new PRI file from scratch. This does not like the trailing \
"%WinSDKDirBinx64%makepri.exe" new /pr "%BuildRoot%staging" /cf "%BuildRootStaging%priconfig.xml"

rem Change to the build root directory
cd "%BuildRoot%"

rem Create the actual package. This does not like the trailing \
"%WinSDKDirBinx64%makeappx.exe" pack /v /o /d "%BuildRoot%staging" /p "%BuildRoot%Package.msix"

rem Do some more house cleaning
del "appcert.xml"

rem Create the app certification report. Note: This requires elevation!
"%WinSDKDir%\App Certification Kit\appcert.exe" reset
"%WinSDKDir%\App Certification Kit\appcert.exe" test -appxpackagepath "%BuildRoot%Package.msix" -reportoutputpath "%BuildRoot%appcert.xml"

:end
endlocal
