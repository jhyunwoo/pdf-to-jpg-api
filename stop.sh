#!/bin/bash

# PDF to JPG Converter API - Production 중지 스크립트

echo "================================================"
echo "PDF to JPG Converter API - Production 중지"
echo "================================================"
echo ""

# PID 파일 확인
if [ ! -f "logs/gunicorn.pid" ]; then
    echo "⚠️  실행 중인 서버를 찾을 수 없습니다."
    echo "PID 파일이 존재하지 않습니다: logs/gunicorn.pid"
    exit 1
fi

PID=$(cat logs/gunicorn.pid)

# 프로세스 확인
if ! ps -p $PID > /dev/null 2>&1; then
    echo "⚠️  프로세스가 실행 중이지 않습니다 (PID: $PID)"
    rm -f logs/gunicorn.pid
    exit 1
fi

echo "서버 중지 중... (PID: $PID)"

# Graceful shutdown
kill -TERM $PID

# 최대 10초 대기
for i in {1..10}; do
    if ! ps -p $PID > /dev/null 2>&1; then
        echo "✅ 서버가 정상적으로 중지되었습니다."
        rm -f logs/gunicorn.pid
        exit 0
    fi
    sleep 1
    echo "대기 중... ($i/10)"
done

# 강제 종료
echo "⚠️  Graceful shutdown 실패. 강제 종료합니다..."
kill -9 $PID
rm -f logs/gunicorn.pid

if ! ps -p $PID > /dev/null 2>&1; then
    echo "✅ 서버가 강제 종료되었습니다."
else
    echo "❌ 서버 종료 실패"
    exit 1
fi

