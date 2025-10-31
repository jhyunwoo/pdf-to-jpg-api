#!/bin/bash

# PDF to JPG Converter API - Setup Only Script (macOS/Linux)
# 이 스크립트는 환경만 설정하고 서버는 실행하지 않습니다.

set -e

echo "================================================"
echo "PDF to JPG Converter API - 환경 설정"
echo "================================================"
echo ""

# Python 버전 확인
echo "📌 Python 버전 확인 중..."
if ! command -v python3 &> /dev/null; then
    echo "❌ 오류: Python3가 설치되어 있지 않습니다."
    exit 1
fi
echo "✅ $(python3 --version)"
echo ""

# Poppler 확인
echo "📌 Poppler 설치 확인 중..."
if ! command -v pdfinfo &> /dev/null; then
    echo "⚠️  Poppler가 설치되어 있지 않습니다."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   설치: brew install poppler"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "   설치: sudo apt-get install -y poppler-utils"
    fi
else
    echo "✅ Poppler 설치됨"
fi
echo ""

# 가상환경 생성
echo "📌 가상환경 생성 중..."
if [ -d "venv" ]; then
    echo "⚠️  가상환경이 이미 존재합니다. 삭제 후 재생성하시겠습니까? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf venv
        python3 -m venv venv
        echo "✅ 가상환경 재생성 완료"
    else
        echo "✅ 기존 가상환경 사용"
    fi
else
    python3 -m venv venv
    echo "✅ 가상환경 생성 완료"
fi
echo ""

# 가상환경 활성화
echo "📌 가상환경 활성화 중..."
source venv/bin/activate
echo "✅ 가상환경 활성화 완료"
echo ""

# pip 업그레이드
echo "📌 pip 업그레이드 중..."
pip install --upgrade pip --quiet
echo "✅ pip 업그레이드 완료"
echo ""

# 패키지 설치
echo "📌 패키지 설치 중..."
pip install -r requirements.txt
echo "✅ 패키지 설치 완료"
echo ""

echo "================================================"
echo "✅ 환경 설정 완료!"
echo "================================================"
echo ""
echo "서버를 실행하려면 다음 명령어를 사용하세요:"
echo ""
echo "  source venv/bin/activate"
echo "  python app.py"
echo ""
echo "또는 간단하게:"
echo "  ./run.sh"
echo ""

