#!/bin/bash

# PDF to JPG Converter API - 서버 상태 확인 스크립트

echo "================================================"
echo "PDF to JPG Converter API - 서버 상태"
echo "================================================"
echo ""

# PID 파일 확인
if [ ! -f "logs/gunicorn.pid" ]; then
    echo "❌ 서버가 실행 중이지 않습니다."
    echo "시작하려면: ./start.sh"
    exit 1
fi

PID=$(cat logs/gunicorn.pid)

# 프로세스 확인
if ps -p $PID > /dev/null 2>&1; then
    echo "✅ 서버 실행 중"
    echo ""
    echo "프로세스 정보:"
    ps -fp $PID
    echo ""
    echo "포트 정보:"
    PORT=${PORT:-3000}
    if command -v lsof &> /dev/null; then
        lsof -i :$PORT | grep LISTEN || echo "포트 $PORT에서 리스닝 중"
    fi
    echo ""
    echo "서버 주소: http://localhost:$PORT"
    echo ""
    echo "최근 로그 (access.log):"
    if [ -f "logs/access.log" ]; then
        tail -5 logs/access.log
    else
        echo "로그 파일 없음"
    fi
    echo ""
    echo "최근 에러 로그 (error.log):"
    if [ -f "logs/error.log" ]; then
        tail -5 logs/error.log
    else
        echo "에러 로그 없음"
    fi
else
    echo "❌ 프로세스가 실행 중이지 않습니다 (PID: $PID)"
    echo "PID 파일을 정리합니다..."
    rm -f logs/gunicorn.pid
    exit 1
fi

