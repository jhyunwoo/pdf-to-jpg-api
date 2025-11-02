# HTTPS 설정 가이드

Mixed Content 에러를 해결하기 위해 API 서버를 HTTPS로 설정하는 방법입니다.

## 전제 조건

1. **도메인 필요**: DNS A 레코드가 서버 IP를 가리켜야 합니다
   - 예: `api.yourdomain.com` → `165.132.141.230`
   
2. **포트 80, 443 개방**: 방화벽에서 HTTP(80), HTTPS(443) 포트가 열려 있어야 합니다

## 방법 1: 자동 설정 스크립트 (권장) ⭐

```bash
# 실행 권한 부여
chmod +x setup_https.sh

# 실행 (도메인과 이메일 입력)
./setup_https.sh api.yourdomain.com your-email@example.com
```

이 스크립트가 자동으로 수행하는 작업:
- ✅ Nginx 설치
- ✅ Certbot 설치
- ✅ Nginx 리버스 프록시 설정
- ✅ Let's Encrypt SSL 인증서 발급
- ✅ HTTP → HTTPS 자동 리다이렉트 설정
- ✅ SSL 인증서 자동 갱신 설정

## 방법 2: 수동 설정

### 1. Nginx 설치

```bash
sudo apt-get update
sudo apt-get install -y nginx
```

### 2. Certbot 설치

```bash
sudo apt-get install -y certbot python3-certbot-nginx
```

### 3. Nginx 설정 파일 생성

```bash
sudo nano /etc/nginx/sites-available/pdf-to-jpg-api
```

다음 내용을 입력 (도메인을 자신의 것으로 변경):

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS 헤더
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
        
        # 타임아웃 설정
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }
}
```

### 4. 설정 활성화

```bash
# 심볼릭 링크 생성
sudo ln -s /etc/nginx/sites-available/pdf-to-jpg-api /etc/nginx/sites-enabled/

# 기본 사이트 비활성화 (선택)
sudo rm /etc/nginx/sites-enabled/default

# 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 5. SSL 인증서 발급

```bash
sudo certbot --nginx -d api.yourdomain.com --non-interactive --agree-tos -m your-email@example.com --redirect
```

## 방법 3: Cloudflare Tunnel (도메인 없이도 가능)

도메인이 없거나 Cloudflare를 사용 중이라면 Cloudflare Tunnel을 사용할 수 있습니다.

### 1. Cloudflared 설치

```bash
# Linux AMD64
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# 또는
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
sudo mv cloudflared /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudflared
```

### 2. Cloudflare 로그인

```bash
cloudflared tunnel login
```

### 3. Tunnel 생성

```bash
cloudflared tunnel create pdf-to-jpg-api
```

### 4. 설정 파일 생성

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

다음 내용 입력:

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/<username>/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: api.yourdomain.com
    service: http://localhost:3000
  - service: http_status:404
```

### 5. DNS 레코드 생성

```bash
cloudflared tunnel route dns pdf-to-jpg-api api.yourdomain.com
```

### 6. Tunnel 실행

```bash
# 포그라운드 실행
cloudflared tunnel run pdf-to-jpg-api

# 또는 백그라운드 서비스로 실행
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## DNS 설정

도메인의 DNS 설정에서 A 레코드를 추가하세요:

```
Type: A
Name: api (또는 원하는 서브도메인)
Value: 165.132.141.230 (서버 IP)
TTL: 300 (5분) 또는 Auto
```

DNS 전파는 최대 48시간이 걸릴 수 있지만 보통 몇 분 내에 완료됩니다.

## 확인

### 1. DNS 확인

```bash
# Linux/Mac
dig api.yourdomain.com

# 또는
nslookup api.yourdomain.com
```

### 2. HTTP 접속 확인

```bash
curl http://api.yourdomain.com/health
```

### 3. HTTPS 접속 확인

```bash
curl https://api.yourdomain.com/health
```

### 4. 웹 브라우저에서 확인

```
https://api.yourdomain.com/
```

## SSL 인증서 자동 갱신

Let's Encrypt 인증서는 90일마다 갱신해야 합니다. Certbot이 자동으로 설정합니다.

### 갱신 테스트

```bash
sudo certbot renew --dry-run
```

### 수동 갱신

```bash
sudo certbot renew
sudo systemctl reload nginx
```

## 방화벽 설정

포트 80, 443을 열어야 합니다:

### UFW 사용 시

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

### iptables 사용 시

```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables-save
```

### 클라우드 제공자 (AWS, GCP, Azure 등)

보안 그룹 또는 방화벽 규칙에서 포트 80, 443을 허용하세요.

## 프론트엔드 코드 수정

HTTPS 설정 후 프론트엔드에서 API URL을 변경하세요:

```javascript
// 변경 전
const API_URL = 'http://165.132.141.230:30860';

// 변경 후
const API_URL = 'https://api.yourdomain.com';
```

## 문제 해결

### Nginx 로그 확인

```bash
# 에러 로그
sudo tail -f /var/log/nginx/error.log

# 액세스 로그
sudo tail -f /var/log/nginx/access.log
```

### Certbot 로그 확인

```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Nginx 재시작

```bash
sudo systemctl restart nginx
```

### SSL 인증서 정보 확인

```bash
sudo certbot certificates
```

## 추가 보안 설정 (선택사항)

### SSL 설정 강화

`/etc/nginx/sites-available/pdf-to-jpg-api` 파일에 추가:

```nginx
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;
    
    # SSL 인증서 (certbot이 자동으로 추가)
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    
    # SSL 보안 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # HSTS (선택사항)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # 나머지 설정...
}
```

## 요약

1. ✅ 도메인 준비 및 DNS 설정
2. ✅ `./setup_https.sh api.yourdomain.com your-email@example.com` 실행
3. ✅ 방화벽 포트 80, 443 개방
4. ✅ `https://api.yourdomain.com/health` 확인
5. ✅ 프론트엔드 API URL 변경

이제 Mixed Content 에러 없이 HTTPS로 안전하게 API를 사용할 수 있습니다! 🔒

