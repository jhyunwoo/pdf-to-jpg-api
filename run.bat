@echo off
REM PDF to JPG Converter API - Run Script (Windows)
REM 이미 설정된 환경에서 서버만 실행합니다.

REM 가상환경 확인
if not exist "venv\" (
    echo [오류] 가상환경이 존재하지 않습니다.
    echo 먼저 setup_and_run.bat를 실행하세요.
    pause
    exit /b 1
)

REM 가상환경 활성화
call venv\Scripts\activate.bat

REM 서버 실행
echo ================================================
echo PDF to JPG Converter API 서버 시작
echo ================================================
echo.
echo 서버 주소: http://localhost:5000
echo 종료하려면 Ctrl+C를 누르세요
echo.

python app.py

