@echo off
REM ===========================================================================
REM  Cross-platform (Windows) convenience runner for the SauceDemo login tests.
REM  Dependencies are managed with uv; the suite runs through `uv run`.
REM
REM  Default: run Chrome and Firefox in parallel (via pabot), merged into one
REM  report. Set BROWSER to run a single browser only.
REM
REM  Usage:
REM    run_tests.bat                       (Chrome and Firefox in parallel)
REM    set BROWSER=chrome & run_tests.bat  (single browser: chrome or firefox)
REM    set HEADLESS=False  & run_tests.bat (show the browser window[s])
REM ===========================================================================
setlocal

if "%HEADLESS%"=="" set HEADLESS=True
if "%RESULTS_DIR%"=="" set RESULTS_DIR=results

cd /d "%~dp0"

if not "%BROWSER%"=="" (
    uv run robot --variable BROWSER:%BROWSER% --variable HEADLESS:%HEADLESS% --outputdir %RESULTS_DIR% %* tests\
) else (
    uv run pabot --argumentfile1 args\chrome.args --argumentfile2 args\firefox.args --variable HEADLESS:%HEADLESS% --outputdir %RESULTS_DIR% %* tests\
)

endlocal

