#!/bin/bash

# HTTPS 설정 스크립트
# Usage: ./setup_https.sh your-domain.com your-email@example.com

set -e

DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Usage: ./setup_https.sh <domain> <email>"
    echo "Example: ./setup_https.sh api.example.com admin@example.com"
    exit 1
fi

echo "=== HTTPS 설정 시작 ==="
echo "도메인: $DOMAIN"
echo "이메일: $EMAIL"
echo ""

# Nginx 설치 확인
if ! command -v nginx &> /dev/null; then
    echo "Nginx를 설치합니다..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Certbot 설치 확인
if ! command -v certbot &> /dev/null; then
    echo "Certbot을 설치합니다..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
fi

# Nginx 설정 파일 생성
echo "Nginx 설정 파일을 생성합니다..."
sudo tee /etc/nginx/sites-available/pdf-to-jpg-api > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS 헤더 (백업용)
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
        
        # Preflight 요청 처리
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
        
        # 타임아웃 설정 (PDF 변환 시간 고려)
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }
}
EOF

# 심볼릭 링크 생성
if [ ! -f /etc/nginx/sites-enabled/pdf-to-jpg-api ]; then
    sudo ln -s /etc/nginx/sites-available/pdf-to-jpg-api /etc/nginx/sites-enabled/
fi

# 기본 사이트 비활성화 (선택사항)
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

# Nginx 설정 테스트
echo "Nginx 설정을 테스트합니다..."
sudo nginx -t

# Nginx 재시작
echo "Nginx를 재시작합니다..."
if command -v systemctl &> /dev/null; then
    # systemd 사용 시스템 (Ubuntu 16.04+, CentOS 7+, etc.)
    sudo systemctl restart nginx
    sudo systemctl enable nginx
elif command -v service &> /dev/null; then
    # init.d 사용 시스템 (오래된 Ubuntu, Debian, etc.)
    sudo service nginx restart
    sudo update-rc.d nginx enable 2>/dev/null || sudo chkconfig nginx on 2>/dev/null
elif [ -f /etc/init.d/nginx ]; then
    # 직접 init 스크립트 실행
    sudo /etc/init.d/nginx restart
else
    # macOS 또는 기타 시스템
    if [ -f /usr/local/bin/nginx ]; then
        sudo nginx -s reload || sudo nginx
    else
        echo "경고: Nginx 재시작 방법을 찾을 수 없습니다."
        echo "수동으로 재시작해주세요: sudo nginx -s reload"
    fi
fi

# Let's Encrypt SSL 인증서 발급
echo "SSL 인증서를 발급받습니다..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

echo ""
echo "=== HTTPS 설정 완료! ==="
echo "API URL: https://$DOMAIN"
echo ""
echo "테스트: curl https://$DOMAIN/health"
echo ""
echo "SSL 인증서는 자동으로 갱신됩니다."
echo "갱신 테스트: sudo certbot renew --dry-run"

