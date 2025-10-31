#!/bin/bash

# PDF to JPG Converter API - Production 배포 스크립트
# 이 스크립트는 production 환경을 처음 설정하고 배포합니다.

set -e

echo "================================================"
echo "PDF to JPG Converter API - Production 배포"
echo "================================================"
echo ""

# 환경 변수 설정
export FLASK_ENV=production
export DEBUG=false
export PORT=${PORT:-3000}

# Python 버전 확인
echo "📌 Python 버전 확인..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3가 설치되어 있지 않습니다."
    exit 1
fi
echo "✅ $(python3 --version)"
echo ""

# Poppler 확인
echo "📌 Poppler 설치 확인..."
if ! command -v pdfinfo &> /dev/null; then
    echo "❌ Poppler가 설치되어 있지 않습니다."
    echo "   설치: sudo apt-get install -y poppler-utils"
    exit 1
fi
echo "✅ Poppler 설치됨"
echo ""

# 가상환경 확인 및 생성
echo "📌 가상환경 설정..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ 가상환경 생성 완료"
else
    echo "✅ 가상환경이 이미 존재합니다"
fi
echo ""

# 가상환경 활성화
source venv/bin/activate

# pip 업그레이드
echo "📌 pip 업그레이드..."
pip install --upgrade pip --quiet
echo "✅ pip 업그레이드 완료"
echo ""

# 패키지 설치
echo "📌 패키지 설치 중..."
pip install -r requirements.txt --quiet
echo "✅ 패키지 설치 완료"
echo ""

# 로그 디렉토리 생성
echo "📌 로그 디렉토리 생성..."
mkdir -p logs
chmod 755 logs
echo "✅ 로그 디렉토리 생성 완료"
echo ""

# 기존 프로세스 중지
echo "📌 기존 프로세스 확인 및 중지..."
if [ -f "logs/gunicorn.pid" ]; then
    OLD_PID=$(cat logs/gunicorn.pid)
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "기존 프로세스 (PID: $OLD_PID) 중지 중..."
        kill -TERM $OLD_PID
        sleep 2
        
        # 강제 종료가 필요한 경우
        if ps -p $OLD_PID > /dev/null 2>&1; then
            kill -9 $OLD_PID
        fi
        echo "✅ 기존 프로세스 중지 완료"
    fi
fi
echo ""

# 권한 설정
chmod +x start.sh stop.sh restart.sh

echo "================================================"
echo "✅ 배포 준비 완료!"
echo "================================================"
echo ""
echo "서버를 시작하려면:"
echo "  ./start.sh"
echo ""
echo "또는 수동으로:"
echo "  source venv/bin/activate"
echo "  gunicorn -c gunicorn_config.py app:app"
echo ""

