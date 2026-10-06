@echo off
setlocal
set "DASHBOARD_BAT=%~f0"
cd /d "%~dp0"
set "DASHBOARD_PY="
where py >nul 2>&1
if not errorlevel 1 (
  py -3 -c "import sys;assert sys.version_info.major==3" >nul 2>&1
  if not errorlevel 1 set "DASHBOARD_PY=py -3"
)
if defined DASHBOARD_PY goto run
python -c "import sys;assert sys.version_info.major==3" >nul 2>&1
if not errorlevel 1 set "DASHBOARD_PY=python"
if defined DASHBOARD_PY goto run
python3 -c "import sys;assert sys.version_info.major==3" >nul 2>&1
if not errorlevel 1 set "DASHBOARD_PY=python3"
if defined DASHBOARD_PY goto run
set "DASHBOARD_BUNDLED=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if exist "%DASHBOARD_BUNDLED%" set DASHBOARD_PY="%DASHBOARD_BUNDLED%"
if defined DASHBOARD_PY goto run
echo Python 3 is required. Install Python 3 and enable Add Python to PATH, then run this file again.
if not defined BANKING_TEST_MODE pause
exit /b 1
:run
set "DASHBOARD_SCRATCH=E:\Codex_Workspace\tasks\banking_dashboard_runtime_%RANDOM%_%RANDOM%"
mkdir "%DASHBOARD_SCRATCH%" >nul 2>&1
if not exist "%DASHBOARD_SCRATCH%" (
  echo Cannot create the runtime folder on E:\Codex_Workspace. Check drive E and permissions.
  if not defined BANKING_TEST_MODE pause
  exit /b 1
)
set "TEMP=%DASHBOARD_SCRATCH%"
set "TMP=%DASHBOARD_SCRATCH%"
set "PYTHONDONTWRITEBYTECODE=1"
set "PYTHONIOENCODING=utf-8"
%DASHBOARD_PY% -c "import pathlib,sys;exec(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').split(chr(10)+'#__PYTHON__'+chr(10),1)[1])" "%DASHBOARD_BAT%" %*
set "DASHBOARD_EXIT=%ERRORLEVEL%"
if not "%DASHBOARD_EXIT%"=="0" if not defined BANKING_TEST_MODE pause
exit /b %DASHBOARD_EXIT%
#__PYTHON__
import argparse,http.server,pathlib,socket,sys,webbrowser
base=pathlib.Path(sys.argv[1]).resolve().parent
parser=argparse.ArgumentParser(description='Local Banking NIM Dashboard')
parser.add_argument('--no-browser',action='store_true')
parser.add_argument('--port',type=int,default=8000)
args=parser.parse_args(sys.argv[2:])
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(base),**kw)
    def end_headers(self):
        self.send_header('Cache-Control','no-store')
        self.send_header('Referrer-Policy','strict-origin-when-cross-origin')
        self.send_header('X-Content-Type-Options','nosniff')
        super().end_headers()
class Server(http.server.ThreadingHTTPServer):
    allow_reuse_address=False
    def server_bind(self):
        if hasattr(socket,'SO_EXCLUSIVEADDRUSE'):
            self.socket.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
        super().server_bind()
try:
    server=Server(('127.0.0.1',args.port),Handler)
except OSError:
    print(f'Port {args.port} is busy or cannot be opened. Close the other local server, then run this BAT again.')
    sys.exit(2)
url=f'http://localhost:{args.port}'
print('Dashboard ready: '+url,flush=True)
print('Keep this window open. Press Ctrl+C to stop the local server.',flush=True)
if not args.no_browser:webbrowser.open(url)
try:server.serve_forever()
except KeyboardInterrupt:print('Local server stopped.')
finally:server.server_close()
