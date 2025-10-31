#!/bin/bash

# PDF to JPG Converter API - Production 시작 스크립트

set -e

# 환경 변수 설정
export FLASK_ENV=production
export DEBUG=false
export PORT=${PORT:-3000}

echo "================================================"
echo "PDF to JPG Converter API - Production 시작"
echo "================================================"
echo ""

# 가상환경 확인
if [ ! -d "venv" ]; then
    echo "❌ 가상환경이 존재하지 않습니다."
    echo "먼저 ./deploy.sh를 실행하세요."
    exit 1
fi

# 로그 디렉토리 확인
if [ ! -d "logs" ]; then
    mkdir -p logs
fi

# 가상환경 활성화
source venv/bin/activate

# 이미 실행 중인지 확인
if [ -f "logs/gunicorn.pid" ]; then
    PID=$(cat logs/gunicorn.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "⚠️  서버가 이미 실행 중입니다 (PID: $PID)"
        echo ""
        echo "재시작하려면: ./restart.sh"
        echo "중지하려면: ./stop.sh"
        exit 1
    fi
fi

echo "서버 시작 중..."
echo ""

# Gunicorn으로 서버 시작 (백그라운드)
gunicorn -c gunicorn_config.py app:app --daemon

# PID 확인
if [ -f "logs/gunicorn.pid" ]; then
    PID=$(cat logs/gunicorn.pid)
    echo "✅ 서버가 성공적으로 시작되었습니다!"
    echo ""
    echo "서버 정보:"
    echo "  - PID: $PID"
    echo "  - 주소: http://localhost:$PORT"
    echo "  - 로그: logs/access.log, logs/error.log"
    echo ""
    echo "서버 상태 확인:"
    echo "  ps -p $PID"
    echo ""
    echo "서버 중지:"
    echo "  ./stop.sh"
    echo ""
    echo "로그 확인:"
    echo "  tail -f logs/access.log"
    echo "  tail -f logs/error.log"
else
    echo "❌ 서버 시작 실패"
    echo "logs/error.log를 확인하세요."
    exit 1
fi

