@echo off
setlocal
cd /d "%~dp0"
set "DASHBOARD_PY="
where py >nul 2>&1
if not errorlevel 1 (
  py -3 -c "import sys" >nul 2>&1
  if not errorlevel 1 set "DASHBOARD_PY=py -3"
)
if defined DASHBOARD_PY goto run
python -c "import sys" >nul 2>&1
if not errorlevel 1 set "DASHBOARD_PY=python"
if defined DASHBOARD_PY goto run
set "DASHBOARD_BUNDLED=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if exist "%DASHBOARD_BUNDLED%" set DASHBOARD_PY="%DASHBOARD_BUNDLED%"
if defined DASHBOARD_PY goto run
echo Python 3 is required. Install Python and enable Add Python to PATH.
pause
exit /b 1
:run
%DASHBOARD_PY% -c "import pathlib,sys;exec(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').split(chr(10)+'#__PYTHON__'+chr(10),1)[1])" "%~f0" %*
if errorlevel 1 (
  pause
  exit /b 1
)
exit /b 0
#__PYTHON__
import hashlib,http.server,json,os,pathlib,subprocess,sys,time,urllib.request,webbrowser
base=pathlib.Path(sys.argv[1]).resolve().parent
url='http://localhost:8000'
marker='banking-two-files-40b2a96ded7d432e'
def running():
    try:
        with urllib.request.urlopen(url+'/index.html',timeout=2) as response:
            return marker in response.read(4096).decode('utf-8',errors='replace')
    except Exception:
        return False
if not running():
    server_code="import http.server,os;os.chdir("+repr(str(base))+");http.server.ThreadingHTTPServer(('127.0.0.1',8000),http.server.SimpleHTTPRequestHandler).serve_forever()"
    flags=getattr(subprocess,'CREATE_NO_WINDOW',0)
    process=subprocess.Popen([sys.executable,'-c',server_code],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,creationflags=flags)
    for attempt in range(40):
        if running():break
        if process.poll() is not None:break
        time.sleep(.2)
    if not running():
        print('Port 8000 is occupied or the server could not start. Close the other local server, then retry.')
        sys.exit(1)
if '--no-browser' not in sys.argv:webbrowser.open(url)
print('Dashboard ready: '+url)
