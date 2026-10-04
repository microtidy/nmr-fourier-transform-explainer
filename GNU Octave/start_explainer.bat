@echo off
setlocal enabledelayedexpansion
rem ============================================================
rem  Fourier Transform Explainer - GNU Octave launcher (Windows)
rem  Locates octave-gui.exe, sets Qt and font-cache environment,
rem  then starts the explainer.
rem  Set OCTAVE_HOME to override the Octave installation folder.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "OCT_GUI="

if defined OCTAVE_HOME (
  if exist "%OCTAVE_HOME%\mingw64\bin\octave-gui.exe" set "OCT_GUI=%OCTAVE_HOME%\mingw64\bin\octave-gui.exe"
  if not defined OCT_GUI if exist "%OCTAVE_HOME%\bin\octave-gui.exe" set "OCT_GUI=%OCTAVE_HOME%\bin\octave-gui.exe"
)
if not defined OCT_GUI if exist "D:\Tools\GNU Octave\octave-11.3.0-w64\mingw64\bin\octave-gui.exe" set "OCT_GUI=D:\Tools\GNU Octave\octave-11.3.0-w64\mingw64\bin\octave-gui.exe"
if not defined OCT_GUI if exist "C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin\octave-gui.exe" set "OCT_GUI=C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin\octave-gui.exe"
if not defined OCT_GUI if exist "C:\Program Files\GNU Octave\mingw64\bin\octave-gui.exe" set "OCT_GUI=C:\Program Files\GNU Octave\mingw64\bin\octave-gui.exe"
if not defined OCT_GUI (
  for %%I in (octave-gui.exe) do if not "%%~$PATH:I"=="" set "OCT_GUI=%%~$PATH:I"
)

if not defined OCT_GUI (
  echo.
  echo GNU Octave ^(octave-gui.exe^) was not found.
  echo Please install GNU Octave from https://octave.org/download
  echo or set OCTAVE_HOME to the Octave installation folder.
  echo.
  pause
  exit /b 1
)

for %%I in ("%OCT_GUI%") do set "OCT_BIN=%%~dpI"
set "OCT_ROOT=%OCT_BIN%..\.."

if exist "%OCT_ROOT%\mingw64\qt6\plugins" (
  set "QT_PLUGIN_PATH=%OCT_ROOT%\mingw64\qt6\plugins"
  set "QT_QPA_PLATFORM_PLUGIN_PATH=%OCT_ROOT%\mingw64\qt6\plugins\platforms"
)
set "XDG_CACHE_HOME=%OCT_ROOT%\cache"
if not exist "%XDG_CACHE_HOME%" mkdir "%XDG_CACHE_HOME%" 2>nul

echo Using Octave: %OCT_GUI%
pushd "%SCRIPT_DIR%"
"%OCT_GUI%" --quiet --persist --eval "run_fourier_explainer_octave;"
popd
endlocal
