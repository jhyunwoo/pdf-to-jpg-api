#!/bin/bash

# Cloudflare Tunnel 설정 스크립트
# 포트 80, 443을 열 수 없는 환경에서 HTTPS 사용하기

set -e

TUNNEL_NAME="pdf-to-jpg-api"

echo "=== Cloudflare Tunnel 설정 ==="
echo ""
echo "이 스크립트는 포트를 열지 않고도 HTTPS를 사용할 수 있게 해줍니다."
echo ""

# OS 감지
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        ARCH="arm64"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "arm64" ]]; then
        ARCH="arm64"
    fi
else
    echo "지원하지 않는 OS입니다."
    exit 1
fi

# cloudflared 설치 확인
if ! command -v cloudflared &> /dev/null; then
    echo "cloudflared를 설치합니다..."
    
    if [[ "$OS" == "linux" ]]; then
        # Linux 설치
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${OS}-${ARCH} -O cloudflared
        sudo mv cloudflared /usr/local/bin/
        sudo chmod +x /usr/local/bin/cloudflared
    elif [[ "$OS" == "darwin" ]]; then
        # macOS 설치
        if command -v brew &> /dev/null; then
            brew install cloudflared
        else
            curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${OS}-${ARCH}.tgz -o cloudflared.tgz
            tar -xzf cloudflared.tgz
            sudo mv cloudflared /usr/local/bin/
            sudo chmod +x /usr/local/bin/cloudflared
            rm cloudflared.tgz
        fi
    fi
    
    echo "✓ cloudflared 설치 완료"
else
    echo "✓ cloudflared가 이미 설치되어 있습니다"
fi

echo ""
echo "=== 다음 단계를 따라주세요 ==="
echo ""
echo "1. Cloudflare 로그인 (브라우저가 열립니다):"
echo "   cloudflared tunnel login"
echo ""
echo "2. Tunnel 생성:"
echo "   cloudflared tunnel create $TUNNEL_NAME"
echo ""
echo "3. Tunnel ID 확인 (위 명령어 출력에서 복사):"
echo "   [출력 예시: Created tunnel pdf-to-jpg-api with id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]"
echo ""
echo "4. 설정 파일 생성:"
echo "   이 스크립트를 다시 실행하거나 수동으로 설정하세요."
echo "   ./setup_cloudflare_tunnel.sh configure <TUNNEL_ID> <DOMAIN>"
echo ""
echo "=== 자동 설정을 원하시면 ==="
echo "1. 먼저 수동으로 위 1-2번 단계를 실행하세요"
echo "2. 그 다음 이 명령어를 실행하세요:"
echo "   ./setup_cloudflare_tunnel.sh configure <TUNNEL_ID> pdf-to-jpg.moveto.kr"
echo ""

# configure 모드
if [ "$1" = "configure" ]; then
    TUNNEL_ID=$2
    DOMAIN=$3
    
    if [ -z "$TUNNEL_ID" ] || [ -z "$DOMAIN" ]; then
        echo "사용법: $0 configure <TUNNEL_ID> <DOMAIN>"
        exit 1
    fi
    
    echo "=== Tunnel 설정 중 ==="
    
    # 설정 디렉토리 생성
    mkdir -p ~/.cloudflared
    
    # 설정 파일 생성
    cat > ~/.cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:3000
  - service: http_status:404
EOF
    
    echo "✓ 설정 파일 생성 완료: ~/.cloudflared/config.yml"
    
    # DNS 라우팅 설정
    echo ""
    echo "DNS 라우팅을 설정합니다..."
    cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN
    
    echo ""
    echo "=== 설정 완료! ==="
    echo ""
    echo "Tunnel을 시작하려면:"
    echo "  cloudflared tunnel run $TUNNEL_NAME"
    echo ""
    echo "백그라운드로 실행하려면:"
    echo "  nohup cloudflared tunnel run $TUNNEL_NAME > /dev/null 2>&1 &"
    echo ""
    echo "systemd 서비스로 등록하려면:"
    echo "  sudo cloudflared service install"
    echo "  sudo systemctl start cloudflared"
    echo "  sudo systemctl enable cloudflared"
    echo ""
    echo "이제 https://$DOMAIN 으로 접속할 수 있습니다!"
fi
