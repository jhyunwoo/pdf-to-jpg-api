#!/bin/bash

# PDF to JPG Converter API - Production 재시작 스크립트

echo "================================================"
echo "PDF to JPG Converter API - Production 재시작"
echo "================================================"
echo ""

# 중지
./stop.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "서버 재시작 중..."
    sleep 2
    
    # 시작
    ./start.sh
else
    echo "❌ 서버 중지 실패"
    exit 1
fi

