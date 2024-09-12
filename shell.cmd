@echo off

setlocal enabledelayedexpansion

:::::::::::::::::::::::::::::::::::【Setup状态获取】:::::::::::::::::::::::::::::::::::::start::
:: 设置状态文件路径
set "STATUS_FILE=%~dp0setup_status.txt"
:: 检查文件是否存在
:: 检查文件是否存在
if not exist "!STATUS_FILE!" (
    call :LogInfo "!STATUS_FILE! not found."
    set "SETUP_STATUS=0"
    call :LogInfo "Default setup status set to !SETUP_STATUS!."
) else (
   :: 读取文件内容并去除前后空格与换行
    for /f "usebackq delims=" %%i in ("!STATUS_FILE!") do (
        set "raw=%%i"
        :: 去除前后空格和换行符
        for /f "tokens=*" %%a in ("!raw!") do set "clean=%%a"
        set "SETUP_STATUS=!clean: =!"
    )
    call :LogInfo "Setup status read from file: !SETUP_STATUS!."
)

:: 将字符串转换为整数
set "IS_NUMERIC=1"
set "STATUS_NUM=0"
for /f "delims=0123456789" %%i in ("!SETUP_STATUS!") do set "IS_NUMERIC=0"

if !IS_NUMERIC! EQU 1 (
    set /a STATUS_NUM=!SETUP_STATUS!
) else (
    call :LogInfo "!SETUP_STATUS! is not a valid number."
    goto :eof
)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::

:::::::::::::::::::::::::::::::::::【Log设置】::::::::::::::::::::::::::::::::::::::::::::start::
:: 定义日志文件的路径
set "LOG_FILE=%~dp0setup_log.txt"
:: 清空日志文件以准备新的日志记录
echo Starting fresh lo1g. > "%LOG_FILE%"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【创建工作目录】::::::::::::::::::::::::::::::::::::::start::
call :LogInfo "##### [1] create work dir"
:: 设置 CHROMIUM_DIR 为当前目录下的 chromium 子目录
set CHROMIUM_DIR=%CD%\chromium

:: 检查 chromium 目录是否存在，如果不存在则创建
if not exist "%CHROMIUM_DIR%" (
    call :LogInfo "chromium directory not found, creating..."
    mkdir "%CHROMIUM_DIR%"
)
:: 切换到 chromium 目录
cd /d "%CHROMIUM_DIR%"
call :LogInfo "done and go on"
call :UpdateStatus "1"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【下载与更新depot_tools】:::::::::::::::::::::::::::::start::
call :LogInfo "_"
call :LogInfo "#######[2. download or update depot_tools]###############"
:: 检查 depot_tools 目录是否存在，如果不存在则使用 git clone 下载
if not exist "%CHROMIUM_DIR%\depot_tools" (
    call :LogInfo "depot_tools not found, cloning..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "%CHROMIUM_DIR%\depot_tools"
    call :LogInfo "depot_tools cloned successfully."
) 
call :LogInfo "done and go on set depot_tools environment PATH variable
call :UpdateStatus "2"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【设置depot_tools环境】::::::::::::::::::::::::::::::::start::
call :LogInfo "_"
call :LogInfo "#######[3. set depot_tools environment PATH variable]"
:: 更新 PATH 环境变量

call :LogInfo "Checking if the new paths are included in the PATH environment variable..."
call :LogInfo "%PATH:%CHROMIUM_DIR%\depot_tools=%"
call :LogInfo "%PATH%"
:: 检查 depot_tools 路径是否在 PATH 环境变量中
if "%PATH:%CHROMIUM_DIR%\depot_tools=%"=="%PATH%" (
    :: 没找到， 退出
    call :LogInfo "Warning: depot_tools path is not in the PATH."
    call :LogInfo "set environment PATH:%CHROMIUM_DIR%\scripts;%PATH%
    :: call :LogInfo "Current PATH: %PATH%
    :: %CHROMIUM_DIR%\scripts;%PATH%
    set "PATH=%CHROMIUM_DIR%\depot_tools;%PATH%"
    if "%PATH:%CHROMIUM_DIR%\depot_tools=%"=="%PATH%" (
        call :LogInfo "Success: depot_tools path is included in the PATH."
    ) else (
        call :LogInfo "failed: depot_tools path failed."
        pause
        exit
    )
) else (
    :: 找到
    call :LogInfo "Success: depot_tools path is included in the PATH."
)
call :LogInfo "done and go on set global variable for download chromium"
call :UpdateStatus "3"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【设置全局变量】::::::::::::::::::::::::::::::::::::::::::start::
call :LogInfo "_"
call :LogInfo "#######[4. set global variable for download chromium]###############"
:: 设置命令提示符标题
title Chromium Shell

:: 设置全局变量
set IN_CHROMIUM_BUILDER=1

set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set NINJA_SUMMARIZE_BUILD=1
set PYTHONDONTWRITEBYTECODE=1

:: 配置 Git
cmd /c "git config --global core.autocrlf false"
cmd /c "git config --global core.filemode false"
cmd /c "git config --global branch.autosetuprebase always"
call :LogInfo "done and go on create .gclient"
call :UpdateStatus "4"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【创建.gclient，并将chromium git信息写入】:::::::::::::::::start::
call :LogInfo "_"
call :LogInfo "#######[5. create .gclient, and fillin chromium git info]###############"

:: 检查 chromium 目录是否存在，如果不存在则创建
if not exist "%CHROMIUM_DIR%" (
    call :LogInfo "chromium directory not found, creating..."
    mkdir "%CHROMIUM_DIR%"
)

:: 切换到 chromium 目录
cd /d "%CHROMIUM_DIR%"

:: 检查 .gclient 文件是否存在，如果不存在则创建并写入内容
if not exist "%CHROMIUM_DIR%\.gclient" (
        call :LogInfo "Creating .gclient file...
    (
        echo solutions = [
        echo {
        echo     "name": "src",
        echo     "url": "https://chromium.googlesource.com/chromium/src.git",  
        echo     "managed": false,
        echo     "custom_deps": {},
        echo     "custom_vars": {
        echo         "checkout_pgo_profiles": true,
        echo     },
        echo },
        echo ]
    ) > "%CHROMIUM_DIR%\.gclient"
    call :LogInfo ".gclient file created successfully."
) else (
    call :LogInfo ".gclient file already exists."
)
call :LogInfo "done and go on download chromium code"
call :UpdateStatus "5"
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【下载chromium代码，如果之前下载过，则用gclient sync同步】::::::start::
call :LogInfo "_"
call :LogInfo "#######[6. download chromium code]###############"

if not exist "%CHROMIUM_DIR%\src" (
    call :LogInfo "Didn't fetch before, fetching chromium..."
    fetch --no-history chromium
    call :LogInfo "Fetch successfully."
) else (
    call :LogInfo "Syncing using gclient..."
   :: gclient sync -D
    call :LogInfo "Sync successfully."
)
call :LogInfo "done and go on"
call :UpdateStatus "6"
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【读取版本号信息，根据版本好来下载对应branch代码】::::::::::::::start::
call :LogInfo "#######[7. read version number as: %VERSION_NUMBER%]###############"
:: 调用 version_number.cmd 并获取版本号

:: 设置版本号文件路径
set "FILE_PATH=%CD%\..\version_number.txt"
call :LogInfo "FILE_PATH=%CD%\version_number.txt"
:: 检查文件是否存在
if not exist "!FILE_PATH!" (
    call :LogInfo "!FILE_PATH! not found."
    set "VERSION_NUMBER=127.0.6533.73"
    call :LogInfo "Default version number set to !VERSION_NUMBER!."
) else (
    :: 读取文件内容
    set /p VERSION_NUMBER=<"!FILE_PATH!"
    call :LogInfo "Version number read from file: !VERSION_NUMBER!."
)

:: 调用 version_number.cmd 并获取版本号
call "%~dp0version_number.cmd"

:: 输出获取到的版本号
call :LogInfo "The version number is: !VERSION_NUMBER!"
call :LogInfo "done and go on checkout to %VERSION_NUMBER%"
call :UpdateStatus "7"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【创建目标版本号分支】:::::::::::::::::::::::::::::::::::::::start::
call :LogInfo "_"
call :LogInfo "#######[8. checkout to %VERSION_NUMBER%]###############"

cd src
call :LogInfo "git reset --hard"
cmd /c "git reset --hard"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【如果没有fetch过目标版本号分支，则fetch下】:::::::::::::::::::start::
:: 检查 SETUP_STATUS 是否小于 8
if !STATUS_NUM! LSS 8 (
    :: call :LogInfo "git -c core.deltaBaseCacheLimit=2g fetch origin %VERSION_NUMBER% --tags --progress"
    :: cmd /c "git -c core.deltaBaseCacheLimit=2g fetch origin %VERSION_NUMBER% --tags --progress"
    call :LogInfo "git -c fetch origin %VERSION_NUMBER% --tags --progress"
    cmd /c "git -c fetch origin %VERSION_NUMBER% --tags --progress"
) else (
    call :LogInfo "fetched before, don't fetch again"
)
call :UpdateStatus "8"
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【如果没有创建过目标版本号分支，则创建下，并切换过去】:::::::::::start::
if !STATUS_NUM! LSS 9 (
    call :LogInfo "git checkout -b %VERSION_NUMBER%"
    cmd /c "git checkout -b %VERSION_NUMBER%"
    call :LogInfo "git checkout %VERSION_NUMBER%"
    cmd /c "git checkout %VERSION_NUMBER%"
) else (
    call :LogInfo "checkout -b %VERSION_NUMBER% before, checkout directly"
    call :LogInfo "git checkout %VERSION_NUMBER%"
    cmd /c "git checkout %VERSION_NUMBER%"
)
call :UpdateStatus "9"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【如果没有gclient sync过代码，则同步下】::::::::::::::::::::::::::::::
if !STATUS_NUM! LSS 9 (
    cmd /c "gclient sync --with_branch_heads -f -R -D"
) else (
    call :LogInfo "gclient synced before, don't sync"
)
call :UpdateStatus "10"

:: del /Q out\stable-sync-x64\*.manifest
:: del /Q out\stable-nosync-x64\*.manifest
cd ..
call :LogInfo "checkout and gclient sync finished."
pause

:: 定义一个函数来记录信息，带有一个参数
:LogInfo
set "logStr=%~1"
echo !logStr! >> "%LOG_FILE%"
echo !logStr!
goto :EOF

:: 定义一个函数来编译状态，带有一个参数
:UpdateStatus
set "statusStr=%~1"
echo !statusStr! > "%STATUS_FILE%"
goto :EOF

:: 退出脚本
endlocal
exit