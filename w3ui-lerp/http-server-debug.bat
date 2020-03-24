@echo off
set EXE=E:\portable\GoogleChromePortable\App\Chrome-bin\chrome.exe
set DATA=E:\portable\GoogleChromePortable\_debug
rem start dbgview.exe
rem %EXE% --user-data-dir=%DATA% -first-run
rem %EXE% --no-sandbox --user-data-dir=%DATA% --js-flags="--trace-opt --trace-deopt --trace-bailout" http://localhost:8080
rem %EXE% --no-sandbox --user-data-dir=%DATA% --js-flags="--trace-opt --trace-deopt --trace-bailout --redirect-code-traces" --no-default-browser-check --ignore-certificate-errors --disable-translate http://localhost:8080
rem TODO
exit

