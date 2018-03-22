@ECHO OFF
call gettests.bat
echo.
<nul (set /p x="Running official tests ... ")
echo.
echo.
dist32\runtest.exe official.decTest
IF ERRORLEVEL 1 echo FAIL
<nul (set /p x="Running additional tests ... ")
echo.
echo.
dist32\runtest.exe additional.decTest
IF ERRORLEVEL 1 echo FAIL


