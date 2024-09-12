@echo off
setlocal EnableDelayedExpansion

:: 定义日志文件的路径
set "LOG_FILE=%~dp0setup_log.txt"

:: 清空日志文件以准备新的日志记录
echo Starting fresh log. > "%LOG_FILE%"

:: 使用函数
call :LogInfo "Init log file"
call :LogInfo "##### [0] Init log file #####"
call :LogInfo "##### [0] Init log file #####"



:: 定义一个函数来记录信息，带有一个参数
:LogInfo
set "logStr=%~1"
echo !logStr! >> "%LOG_FILE%"
echo !logStr!
goto :EOF

pause
endlocal
exit