@echo off
Title Packing Smokeview for all platforms

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use SMV/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

call %envfile%

%svn_drive%
echo.
echo cleaning Test Smokeview's on all platforms
call %svn_root%\SMV\scripts\MAKEdistwin32.bat
call %svn_root%\SMV\scripts\MAKEdistwin64.bat
call %svn_root%\SMV\scripts\MAKEdistosx32.bat
call %svn_root%\SMV\scripts\MAKEdistosx64.bat
call %svn_root%\SMV\scripts\MAKEdistlinux32.bat
call %svn_root%\SMV\scripts\MAKEdistlinux64.bat

pause