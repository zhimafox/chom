@echo off

setlocal enabledelayedexpansion

:: 设置 CHROMIUM_DIR 为当前目录下的 chromium 子目录
set ROOT_DIR=%CD%
set CHROMIUM_DIR=%CD%\chromium
set SRC_DIR=%CHROMIUM_DIR%\src
echo SRC_DIR:%SRC_DIR%
:: 检查 chromium 目录是否存在，如果不存在则创建
if not exist "%SRC_DIR%" (
    echo no code here, you should run shell.cmd to download chromium code first.
    (goto :EOF)
)

set NINJA_DIR=%CD%\chromium\src\third_party\ninja

echo NINJA_DIR:%NINJA_DIR%
echo %SRC_DIR%\out\stable-sync-x64




::cmd /c "gn gen --ide=vs --ninja-executable=D:\repo\chom\chromium\src\third_party\ninja\ninja.exe --filters=//chrome --no-deps %SRC_DIR%\out\stable-sync-x64"
cmd /c "gn gen --ide=vs --ninja-executable=%NINJA_DIR%\ninja.exe --filters=//chrome --no-deps %SRC_DIR%\out\stable-sync-x64"

:: 退出脚本
endlocal
exit

:: cmd /c "autoninja -C out/stable-sync-x64 chrome_official_builder_no_unittests"
:: cmd /c "gn gen out\stable-nosync-x64"
:: cmd /c "autoninja -C out/stable-nosync-x64 chrome_official_builder_no_unittests"

:: cmd /c "gn clean out\stable-undefined-noarch"
:: cmd /c "gn gen out\stable-undefined-noarch"
:: cmd /c "autoninja -C out/stable-undefined-noarch pack_policy_templates"
:: cd ..