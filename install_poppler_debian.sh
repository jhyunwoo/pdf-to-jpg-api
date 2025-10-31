#!/bin/bash

# Poppler 설치 스크립트 (Debian/Ubuntu)
# Debian Buster와 같은 구버전에서도 작동하도록 설계

set -e

echo "================================================"
echo "Poppler 설치 스크립트"
echo "================================================"
echo ""

# Debian 버전 확인
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME $VERSION"
    echo ""
fi

# 방법 1: 일반 apt-get 시도
echo "📌 방법 1: apt-get으로 설치 시도..."
if sudo apt-get update 2>/dev/null && sudo apt-get install -y poppler-utils 2>/dev/null; then
    echo "✅ Poppler 설치 완료!"
    exit 0
fi

echo ""
echo "⚠️  일반 apt-get 설치 실패. 대체 방법을 시도합니다..."
echo ""

# 방법 2: Debian Archive 사용 (Debian Buster 등 구버전용)
if [[ "$ID" == "debian" ]] && [[ "$VERSION_ID" == "10" ]]; then
    echo "📌 방법 2: Debian Buster Archive 저장소 사용..."
    echo ""
    echo "Debian Buster는 EOL되어 archive로 이동되었습니다."
    echo "/etc/apt/sources.list를 백업하고 수정합니다..."
    echo ""
    
    # sources.list 백업
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d-%H%M%S)
    
    # archive 저장소로 변경
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF
    
    # Acquire::Check-Valid-Until 비활성화 (archive 저장소용)
    sudo tee /etc/apt/apt.conf.d/99archive > /dev/null <<EOF
Acquire::Check-Valid-Until "false";
EOF
    
    echo "저장소 설정 업데이트 완료"
    echo ""
    
    # 업데이트 및 설치
    if sudo apt-get update && sudo apt-get install -y poppler-utils; then
        echo "✅ Poppler 설치 완료!"
        exit 0
    fi
fi

# 방법 3: 소스에서 컴파일 (최후의 수단)
echo ""
echo "📌 방법 3: 소스에서 컴파일..."
echo "이 방법은 시간이 걸릴 수 있습니다."
echo ""

# 필요한 빌드 도구 설치 시도
sudo apt-get install -y build-essential cmake pkg-config libfontconfig1-dev libjpeg-dev libpng-dev || true

# Poppler 다운로드 및 컴파일
cd /tmp
wget -q https://poppler.freedesktop.org/poppler-23.12.0.tar.xz
tar -xf poppler-23.12.0.tar.xz
cd poppler-23.12.0
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_QT5=OFF -DENABLE_QT6=OFF
make -j$(nproc)
sudo make install
sudo ldconfig

echo "✅ Poppler 소스 컴파일 및 설치 완료!"

