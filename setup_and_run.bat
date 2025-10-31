@echo off
REM PDF to JPG Converter API - Setup and Run Script (Windows)
REM 이 스크립트는 가상환경을 생성하고 필요한 패키지를 설치한 후 서버를 실행합니다.

echo ================================================
echo PDF to JPG Converter API - 설치 및 실행
echo ================================================
echo.

REM 1. Python 버전 확인
echo [1/7] Python 버전 확인 중...
python --version >nul 2>&1
if errorlevel 1 (
    echo [오류] Python이 설치되어 있지 않습니다.
    echo Python 3.8 이상을 설치해주세요: https://www.python.org/downloads/
    pause
    exit /b 1
)

python --version
echo.

REM 2. Poppler 설치 확인
echo [2/7] Poppler 설치 확인 중...
where pdfinfo >nul 2>&1
if errorlevel 1 (
    echo [경고] Poppler가 설치되어 있지 않습니다.
    echo.
    echo Poppler 설치 방법:
    echo 1. https://github.com/oschwartz10612/poppler-windows/releases/ 에서 다운로드
    echo 2. 압축 해제 후 bin 폴더를 시스템 PATH에 추가
    echo.
    echo 또는 Chocolatey 사용:
    echo choco install poppler
    echo.
    set /p continue="Poppler 없이 계속하시겠습니까? (설치 후 다시 실행 권장) [y/N]: "
    if /i not "%continue%"=="y" (
        echo 설치를 취소합니다.
        pause
        exit /b 1
    )
) else (
    echo Poppler가 이미 설치되어 있습니다.
)
echo.

REM 3. 가상환경 확인 및 생성
echo [3/7] Python 가상환경 확인 중...
if exist "venv\" (
    echo 가상환경이 이미 존재합니다.
) else (
    echo 가상환경 생성 중...
    python -m venv venv
    if errorlevel 1 (
        echo [오류] 가상환경 생성 실패
        pause
        exit /b 1
    )
    echo 가상환경 생성 완료
)
echo.

REM 4. 가상환경 활성화
echo [4/7] 가상환경 활성화 중...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo [오류] 가상환경 활성화 실패
    pause
    exit /b 1
)
echo 가상환경 활성화 완료
echo.

REM 5. pip 업그레이드
echo [5/7] pip 업그레이드 중...
python -m pip install --upgrade pip --quiet
echo pip 업그레이드 완료
echo.

REM 6. 패키지 설치
echo [6/7] 필요한 패키지 설치 중...
if exist "requirements.txt" (
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [오류] 패키지 설치 실패
        pause
        exit /b 1
    )
    echo 패키지 설치 완료
) else (
    echo [오류] requirements.txt 파일을 찾을 수 없습니다.
    pause
    exit /b 1
)
echo.

REM 7. 서버 실행
echo ================================================
echo 설치 완료! Flask 서버를 시작합니다...
echo ================================================
echo.
echo 서버 주소: http://localhost:5000
echo 종료하려면 Ctrl+C를 누르세요
echo.

REM Flask 앱 실행
python app.py

