@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul

pushd "%~dp0"

if not exist bin mkdir bin
if not exist lib mkdir lib

fpc @fpcfg.cfg %*
set "ERRCOMP=!ERRORLEVEL!"

popd

exit /b %ERRCOMP%
