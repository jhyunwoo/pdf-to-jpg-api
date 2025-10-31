#!/bin/bash

# PDF to JPG Converter API - Setup and Run Script (macOS/Linux)
# 이 스크립트는 가상환경을 생성하고 필요한 패키지를 설치한 후 서버를 실행합니다.

set -e  # 에러 발생 시 스크립트 중단

echo "================================================"
echo "PDF to JPG Converter API - 설치 및 실행"
echo "================================================"
echo ""

# 1. Python 버전 확인
echo "📌 Python 버전 확인 중..."
if ! command -v python3 &> /dev/null; then
    echo "❌ 오류: Python3가 설치되어 있지 않습니다."
    echo "   Python 3.8 이상을 설치해주세요: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "✅ $PYTHON_VERSION 감지됨"
echo ""

# 2. Poppler 설치 확인
echo "📌 Poppler 설치 확인 중..."
if ! command -v pdfinfo &> /dev/null; then
    echo "⚠️  Poppler가 설치되어 있지 않습니다."
    echo ""
    
    # OS 감지
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "macOS가 감지되었습니다. Homebrew를 사용하여 Poppler를 설치합니다..."
        if command -v brew &> /dev/null; then
            echo "Homebrew로 Poppler 설치 중..."
            brew install poppler
            echo "✅ Poppler 설치 완료"
        else
            echo "❌ 오류: Homebrew가 설치되어 있지 않습니다."
            echo "   다음 명령어로 Homebrew를 설치하거나:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo ""
            echo "   수동으로 Poppler를 설치해주세요:"
            echo "   brew install poppler"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "Linux가 감지되었습니다."
        echo "다음 명령어로 Poppler를 설치해주세요:"
        echo ""
        echo "  Ubuntu/Debian: sudo apt-get install -y poppler-utils"
        echo "  CentOS/RHEL: sudo yum install -y poppler-utils"
        echo ""
        read -p "Poppler를 설치하시겠습니까? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y poppler-utils
                echo "✅ Poppler 설치 완료"
            elif command -v yum &> /dev/null; then
                sudo yum install -y poppler-utils
                echo "✅ Poppler 설치 완료"
            else
                echo "❌ 패키지 매니저를 찾을 수 없습니다. 수동으로 설치해주세요."
                exit 1
            fi
        else
            echo "Poppler 없이는 API가 작동하지 않습니다. 나중에 설치해주세요."
            exit 1
        fi
    fi
else
    echo "✅ Poppler가 이미 설치되어 있습니다."
fi
echo ""

# 3. 가상환경 확인 및 생성
echo "📌 Python 가상환경 확인 중..."
if [ -d "venv" ]; then
    echo "✅ 가상환경이 이미 존재합니다."
else
    echo "가상환경 생성 중..."
    python3 -m venv venv
    echo "✅ 가상환경 생성 완료"
fi
echo ""

# 4. 가상환경 활성화
echo "📌 가상환경 활성화 중..."
source venv/bin/activate

if [ -z "$VIRTUAL_ENV" ]; then
    echo "❌ 오류: 가상환경 활성화 실패"
    exit 1
fi
echo "✅ 가상환경 활성화 완료"
echo ""

# 5. pip 업그레이드
echo "📌 pip 업그레이드 중..."
pip install --upgrade pip > /dev/null 2>&1
echo "✅ pip 업그레이드 완료"
echo ""

# 6. 패키지 설치
echo "📌 필요한 패키지 설치 중..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo "✅ 패키지 설치 완료"
else
    echo "❌ 오류: requirements.txt 파일을 찾을 수 없습니다."
    exit 1
fi
echo ""

# 7. 서버 실행
echo "================================================"
echo "✅ 설치 완료! Flask 서버를 시작합니다..."
echo "================================================"
echo ""
echo "서버 주소: http://localhost:5000"
echo "종료하려면 Ctrl+C를 누르세요"
echo ""

# Flask 앱 실행
python app.py

