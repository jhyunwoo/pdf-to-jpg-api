#!/bin/bash

# PDF to JPG Converter API - Run Script (macOS/Linux)
# 이미 설정된 환경에서 서버만 실행합니다.

set -e

# 가상환경 확인
if [ ! -d "venv" ]; then
    echo "❌ 오류: 가상환경이 존재하지 않습니다."
    echo "먼저 다음 스크립트를 실행하세요:"
    echo "  ./setup_and_run.sh"
    echo "또는"
    echo "  ./setup.sh"
    exit 1
fi

# 가상환경 활성화
source venv/bin/activate

# 서버 실행
echo "================================================"
echo "PDF to JPG Converter API 서버 시작"
echo "================================================"
echo ""
echo "서버 주소: http://localhost:3000"
echo "종료하려면 Ctrl+C를 누르세요"
echo ""

python app.py

