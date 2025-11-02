# Cloudflare Tunnel로 포트 없이 HTTPS 사용하기

포트 80, 443을 열 수 없는 환경에서 HTTPS를 사용하는 가장 좋은 방법입니다.

## 장점

- ✅ **포트 개방 불필요**: 80, 443 포트를 열 필요 없음
- ✅ **무료 HTTPS**: 자동으로 SSL 인증서 제공
- ✅ **무료 서비스**: Cloudflare Tunnel은 무료
- ✅ **DDoS 보호**: Cloudflare의 보안 기능 자동 적용
- ✅ **쉬운 설정**: 몇 분 안에 완료

## 전제 조건

- Cloudflare 계정 (무료)
- 도메인 (Cloudflare에 등록되어 있어야 함)

## 빠른 설정

### 1. 자동 설치 스크립트 실행

```bash
chmod +x setup_cloudflare_tunnel.sh
./setup_cloudflare_tunnel.sh
```

### 2. Cloudflare 로그인

```bash
cloudflared tunnel login
```

브라우저가 열리면 Cloudflare 계정으로 로그인하고 도메인을 선택하세요.

### 3. Tunnel 생성

```bash
cloudflared tunnel create pdf-to-jpg-api
```

출력 예시:
```
Created tunnel pdf-to-jpg-api with id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

이 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` 부분이 **TUNNEL_ID**입니다. 복사해두세요!

### 4. Tunnel 설정

```bash
./setup_cloudflare_tunnel.sh configure <TUNNEL_ID> pdf-to-jpg.moveto.kr
```

예시:
```bash
./setup_cloudflare_tunnel.sh configure 12345678-1234-1234-1234-123456789abc pdf-to-jpg.moveto.kr
```

### 5. Tunnel 실행

```bash
# 포그라운드 실행 (테스트용)
cloudflared tunnel run pdf-to-jpg-api

# 백그라운드 실행
nohup cloudflared tunnel run pdf-to-jpg-api > /tmp/cloudflared.log 2>&1 &

# 또는 systemd 서비스로 등록 (권장)
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### 6. 테스트

```bash
curl https://pdf-to-jpg.moveto.kr/health
```

## 수동 설정 (상세)

### 1. cloudflared 설치

#### Linux (AMD64)
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

#### Linux (ARM64)
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

#### macOS (Homebrew)
```bash
brew install cloudflared
```

#### macOS (수동)
```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz -o cloudflared.tgz
tar -xzf cloudflared.tgz
sudo mv cloudflared /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudflared
```

### 2. Cloudflare 인증

```bash
cloudflared tunnel login
```

브라우저에서 Cloudflare 계정으로 로그인하고 도메인을 선택합니다.
인증 파일이 `~/.cloudflared/cert.pem`에 저장됩니다.

### 3. Tunnel 생성

```bash
cloudflared tunnel create pdf-to-jpg-api
```

출력에서 Tunnel ID를 복사하세요.

### 4. 설정 파일 생성

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

다음 내용을 입력 (TUNNEL_ID를 실제 ID로 변경):

```yaml
tunnel: TUNNEL_ID
credentials-file: /home/YOUR_USERNAME/.cloudflared/TUNNEL_ID.json

ingress:
  - hostname: pdf-to-jpg.moveto.kr
    service: http://localhost:3000
  - service: http_status:404
```

**중요**: 
- `TUNNEL_ID`를 3단계에서 받은 실제 ID로 변경
- `YOUR_USERNAME`을 실제 사용자명으로 변경
- `credentials-file` 경로는 절대 경로를 사용하세요

### 5. DNS 라우팅 설정

```bash
cloudflared tunnel route dns pdf-to-jpg-api pdf-to-jpg.moveto.kr
```

이 명령어가 자동으로 Cloudflare DNS에 CNAME 레코드를 생성합니다.

### 6. Tunnel 실행

#### 테스트 실행 (포그라운드)
```bash
cloudflared tunnel run pdf-to-jpg-api
```

#### 백그라운드 실행
```bash
nohup cloudflared tunnel run pdf-to-jpg-api > /tmp/cloudflared.log 2>&1 &
```

#### systemd 서비스로 등록 (권장)
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### 7. 서비스 관리

#### 상태 확인
```bash
sudo systemctl status cloudflared
```

#### 로그 확인
```bash
sudo journalctl -u cloudflared -f
```

#### 재시작
```bash
sudo systemctl restart cloudflared
```

#### 중지
```bash
sudo systemctl stop cloudflared
```

## Tunnel 정보 확인

### Tunnel 목록
```bash
cloudflared tunnel list
```

### Tunnel 정보
```bash
cloudflared tunnel info pdf-to-jpg-api
```

### DNS 라우팅 확인
```bash
cloudflared tunnel route dns pdf-to-jpg-api
```

## 문제 해결

### 1. Tunnel이 연결되지 않음

```bash
# 로그 확인
sudo journalctl -u cloudflared -f

# 또는 직접 실행하여 에러 확인
cloudflared tunnel run pdf-to-jpg-api
```

### 2. API 서버가 실행 중인지 확인

```bash
curl http://localhost:3000/health
```

### 3. 설정 파일 확인

```bash
cat ~/.cloudflared/config.yml
```

### 4. Tunnel 재생성

```bash
# 기존 Tunnel 삭제
cloudflared tunnel delete pdf-to-jpg-api

# 새로 생성
cloudflared tunnel create pdf-to-jpg-api

# DNS 다시 설정
cloudflared tunnel route dns pdf-to-jpg-api pdf-to-jpg.moveto.kr
```

## 완전한 예제

```bash
# 1. 설치
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# 2. 로그인
cloudflared tunnel login

# 3. Tunnel 생성
cloudflared tunnel create pdf-to-jpg-api
# 출력: Created tunnel pdf-to-jpg-api with id abc123...

# 4. 설정 파일 생성
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml <<EOF
tunnel: abc123...
credentials-file: $HOME/.cloudflared/abc123....json

ingress:
  - hostname: pdf-to-jpg.moveto.kr
    service: http://localhost:3000
  - service: http_status:404
EOF

# 5. DNS 설정
cloudflared tunnel route dns pdf-to-jpg-api pdf-to-jpg.moveto.kr

# 6. 서비스 등록 및 시작
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# 7. 확인
curl https://pdf-to-jpg.moveto.kr/health
```

## 다중 도메인 설정

여러 도메인을 사용하려면:

```yaml
tunnel: TUNNEL_ID
credentials-file: /home/username/.cloudflared/TUNNEL_ID.json

ingress:
  - hostname: api1.example.com
    service: http://localhost:3000
  - hostname: api2.example.com
    service: http://localhost:3000
  - hostname: admin.example.com
    service: http://localhost:8080
  - service: http_status:404
```

각 도메인별 DNS 설정:
```bash
cloudflared tunnel route dns pdf-to-jpg-api api1.example.com
cloudflared tunnel route dns pdf-to-jpg-api api2.example.com
cloudflared tunnel route dns pdf-to-jpg-api admin.example.com
```

## 프론트엔드 코드 수정

```javascript
// 기존
const API_URL = 'http://165.132.141.230:30860';

// Cloudflare Tunnel 사용
const API_URL = 'https://pdf-to-jpg.moveto.kr';
```

## 비용

- **Cloudflare Tunnel**: 완전 무료
- **트래픽**: 무제한 무료
- **SSL 인증서**: 무료
- **DDoS 보호**: 무료

## 기타 대안들

포트를 열 수 없는 경우의 다른 대안:

1. **ngrok** (간단하지만 유료)
2. **LocalTunnel** (무료, 덜 안정적)
3. **Tailscale** (VPN 기반)
4. **Bore** (오픈소스 터널링)

하지만 **Cloudflare Tunnel**이 가장 안정적이고 프로덕션에 적합합니다.

## 요약

Cloudflare Tunnel을 사용하면:
- ✅ 포트 80, 443을 열 필요 없음
- ✅ 자동 HTTPS
- ✅ 무료
- ✅ DDoS 보호
- ✅ 프로덕션 사용 가능

```bash
# 간단 요약
./setup_cloudflare_tunnel.sh                              # 1. 설치
cloudflared tunnel login                                   # 2. 로그인
cloudflared tunnel create pdf-to-jpg-api                   # 3. 생성
./setup_cloudflare_tunnel.sh configure <ID> <DOMAIN>       # 4. 설정
sudo cloudflared service install && sudo systemctl start cloudflared  # 5. 시작
```

이제 `https://pdf-to-jpg.moveto.kr`로 접속할 수 있습니다! 🎉

