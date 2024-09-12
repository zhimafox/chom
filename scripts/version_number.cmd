@echo off
setlocal

:: 设置版本号文件路径
set "FILE_PATH=%CD%\big_version_number.txt"

:: 检查文件是否存在
if not exist "%FILE_PATH%" (
    echo %FILE_PATH% not found.
    set "BIG_VERSION_NUMBER=127"
    echo Default version number set to %VERSION_NUMBER%.
    echo %BIG_VERSION_NUMBER% > "%FILE_PATH%"
    goto :EOF
)

:: 读取文件内容
set /p BIG_VERSION_NUMBER=<"%FILE_PATH%"

:: 输出版本号
echo %BIG_VERSION_NUMBER%

endlocal