@if not defined debug echo off

set LOGFILE=%temp%\my_powershell_script.log
md %temp%
echo Running %1 in system context >> %LOGFILE%

echo Executing "PsExec.exe -i -s cmd.exe /c powershell.exe %1%" >> %LOGFILE%

rem Download and launch URL at %1
PsExec64.exe -accepteula -nobanner -i -s cmd.exe /c powershell.exe -noprofile -executionpolicy bypass -command "start-transcript -OutputDirectory %temp% ; iwr %1 | iex ; Stop-transcript; exit $LastExitCode" 2>&1 >> %LOGFILE%
echo result: %ERRORLEVEL% >> %LOGFILE%

exit /B %ErrorLevel%
