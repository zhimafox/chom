::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: The script of config depot_tools environment and download chromium code.
::
:: Author: Fox Guo
:: Date:2024/9/12
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

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
set ROOT_DIR=%CD%
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
:: call :LogInfo " path:%CHROMIUM_DIR%\depot_tools"
:: call :LogInfo "_"
:: call :LogInfo "system Path:%PATH%"


:: 构建期望添加到 PATH 的路径
set "DEPOT_TOOLS_PATH=%CHROMIUM_DIR%\depot_tools"

:: 检查系统 PATH 环境变量是否已经包含了 depot_tools 路径
if "!PATH:%DEPOT_TOOLS_PATH%=%!" neq "!PATH!" (
    echo The path !DEPOT_TOOLS_PATH! is already in the PATH.
) else (
    echo The path !DEPOT_TOOLS_PATH! is not in the PATH. Adding...
    set "PATH=%DEPOT_TOOLS_PATH%;%PATH%"
    call :LogInfo "Updated system Path: %PATH%"
)

:: 测试 depot_tools 路径是否有效
where gclient >nul 2>&1
if !errorlevel! equ 0 (
    call :LogInfo "gclient is found in PATH. The update was successful."
) else (
    call :LogInfo "gclient is not found in PATH. The update failed."
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
        echo     "managed": False,
        echo     "custom_deps": {},
        echo     "custom_vars": {
        echo         "checkout_pgo_profiles": True,
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
    call :LogInfo "branch %VERSION_NUMBER% existed, checkout directly"
    call :LogInfo "git checkout %VERSION_NUMBER%"
    cmd /c "git checkout %VERSION_NUMBER%"
)
call :UpdateStatus "9"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【如果没有gclient sync过代码，则同步下】::::::::::::::::::::::::::::::
if !STATUS_NUM! LSS 10 (
    call :LogInfo "gclient sync --with_branch_heads -f -R -Dc"
    cmd /c "gclient sync --with_branch_heads -f -R -D"
) else (
    call :LogInfo "gclient synced before, don't sync"
)
call :LogInfo "gclient sync finished."
call :UpdateStatus "10"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::


:::::::::::::::::::::::::::::::::::【拷贝arg.gn文件】::::::::::::::::::::::::::::::
call :LogInfo "#######[11. copy arg.gn]###############"
set "OUT_SOURCE_DIR=%ROOT_DIR%\config\out"
set "OUT_TARGET_DIR=%CHROMIUM_DIR%\src\out"

call :LogInfo OUT_SOURCE_DIR:%OUT_SOURCE_DIR%
call :LogInfo OUT_TARGET_DIR:%OUT_TARGET_DIR%

:: 检查目标文件夹是否存在
if not exist "%OUT_TARGET_DIR%" (
    :: 目标文件夹不存在，创建它并复制源文件夹
    mkdir "%OUT_SOURCE_DIR%"
    xcopy /E /I /Y "%OUT_SOURCE_DIR%" "%OUT_TARGET_DIR%"
    echo The 'out' folder has been copied to "%OUT_TARGET_DIR%".
) else (
    :: 目标文件夹已存在，不执行复制
    echo The 'out' folder already exists in "%OUT_TARGET_DIR%". No copy performed.
)
call :LogInfo "copy finished finished."
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::end::

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