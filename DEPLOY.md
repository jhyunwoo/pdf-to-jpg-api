# Production 배포 가이드

## 빠른 배포 (1분)

```bash
# 1. 배포 스크립트 실행
./deploy.sh

# 2. 서버 시작
./start.sh
```

끝! 서버가 production 모드로 실행됩니다. 🚀

---

## 상세 배포 가이드

### 사전 요구사항

1. **Python 3.8+**
2. **Poppler** (PDF 변환용)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install -y poppler-utils
   
   # macOS
   brew install poppler
   ```

### 1단계: 코드 배포

```bash
# Git으로 코드 가져오기
git clone <repository-url>
cd pdf-to-jpg-api

# 또는 직접 업로드
```

### 2단계: 환경 설정 및 배포

```bash
./deploy.sh
```

이 스크립트는 다음을 수행합니다:
- ✅ Python 및 Poppler 확인
- ✅ 가상환경 생성
- ✅ 패키지 설치 (Flask, Gunicorn 등)
- ✅ 로그 디렉토리 생성
- ✅ 기존 프로세스 중지
- ✅ 실행 권한 설정

### 3단계: 서버 시작

```bash
./start.sh
```

서버가 백그라운드에서 실행됩니다.

---

## 서버 관리

### 서버 시작
```bash
./start.sh
```

### 서버 중지
```bash
./stop.sh
```

### 서버 재시작
```bash
./restart.sh
```

### 서버 상태 확인
```bash
./status.sh
```

또는:
```bash
ps aux | grep gunicorn
```

### 로그 확인

**실시간 로그 모니터링:**
```bash
# 접근 로그
tail -f logs/access.log

# 에러 로그
tail -f logs/error.log

# 애플리케이션 로그
tail -f logs/app.log
```

**로그 검색:**
```bash
# 최근 100줄
tail -100 logs/access.log

# 에러만 필터링
grep ERROR logs/error.log

# 특정 날짜
grep "2025-10-31" logs/access.log
```

---

## 환경 변수 설정

### 기본 환경 변수

배포 스크립트는 다음 환경 변수를 자동으로 설정합니다:

```bash
FLASK_ENV=production      # 환경 (production/development)
DEBUG=false              # 디버그 모드 (true/false)
PORT=3000               # 서버 포트
```

### 커스텀 설정

환경 변수를 변경하려면 스크립트를 수정하거나 `.env` 파일을 사용할 수 있습니다:

```bash
# .env 파일 생성
cat > .env << EOF
FLASK_ENV=production
DEBUG=false
PORT=8000
GUNICORN_WORKERS=4
EOF

# 환경 변수 로드 후 시작
export $(cat .env | xargs)
./start.sh
```

---

## Gunicorn 설정

`gunicorn_config.py` 파일에서 Gunicorn 설정을 조정할 수 있습니다:

### 주요 설정

```python
# 워커 수 (기본: CPU 코어 수 * 2 + 1)
workers = 4

# 타임아웃 (PDF 변환은 시간이 걸릴 수 있음)
timeout = 300  # 5분

# 바인드 주소
bind = "0.0.0.0:3000"

# 로그 파일
accesslog = 'logs/access.log'
errorlog = 'logs/error.log'
```

### 워커 수 설정

환경 변수로 워커 수를 조정할 수 있습니다:
```bash
export GUNICORN_WORKERS=8
./start.sh
```

권장 워커 수:
- **CPU 바운드 작업**: `(CPU 코어 수 * 2) + 1`
- **I/O 바운드 작업**: 더 많은 워커 사용 가능

---

## Nginx 리버스 프록시 (권장)

Production 환경에서는 Nginx를 프론트엔드로 사용하는 것을 권장합니다.

### Nginx 설정 예시

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 최대 업로드 크기 (대용량 PDF용)
    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 타임아웃 설정 (PDF 변환 시간 고려)
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
```

### Nginx 설정 적용

```bash
# 설정 파일 생성
sudo nano /etc/nginx/sites-available/pdf-api

# 심볼릭 링크 생성
sudo ln -s /etc/nginx/sites-available/pdf-api /etc/nginx/sites-enabled/

# 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

---

## Systemd 서비스 (자동 시작)

서버 재부팅 시 자동으로 시작하도록 설정:

### 서비스 파일 생성

```bash
sudo nano /etc/systemd/system/pdf-api.service
```

```ini
[Unit]
Description=PDF to JPG Converter API
After=network.target

[Service]
Type=notify
User=your-username
Group=your-group
WorkingDirectory=/path/to/pdf-to-jpg-api
Environment="FLASK_ENV=production"
Environment="PORT=3000"
ExecStart=/path/to/pdf-to-jpg-api/venv/bin/gunicorn -c gunicorn_config.py app:app
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=always

[Install]
WantedBy=multi-user.target
```

### 서비스 활성화

```bash
# 서비스 리로드
sudo systemctl daemon-reload

# 서비스 시작
sudo systemctl start pdf-api

# 부팅 시 자동 시작 활성화
sudo systemctl enable pdf-api

# 상태 확인
sudo systemctl status pdf-api

# 로그 확인
sudo journalctl -u pdf-api -f
```

---

## 모니터링

### 서버 헬스체크

```bash
curl http://localhost:3000/health
```

**응답 예시:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-31T12:00:00.000000"
}
```

### 프로세스 모니터링

```bash
# 프로세스 확인
ps aux | grep gunicorn

# 메모리 사용량
ps aux | grep gunicorn | awk '{sum+=$6} END {print sum/1024 " MB"}'

# 열린 파일 수
lsof -p $(cat logs/gunicorn.pid) | wc -l
```

---

## 문제 해결

### 포트가 이미 사용 중

```bash
# 포트 사용 중인 프로세스 찾기
sudo lsof -i :3000

# 프로세스 종료
sudo kill -9 <PID>
```

### 서버 응답 없음

```bash
# 로그 확인
tail -50 logs/error.log

# 워커 상태 확인
ps aux | grep gunicorn

# 강제 재시작
./stop.sh && sleep 2 && ./start.sh
```

### 메모리 부족

워커 수를 줄이거나 서버 리소스를 증가시키세요:
```bash
export GUNICORN_WORKERS=2
./restart.sh
```

---

## 보안 권장사항

1. **방화벽 설정**
   ```bash
   # UFW 사용 시
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

2. **HTTPS 설정** (Let's Encrypt)
   ```bash
   sudo apt-get install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

3. **환경 변수 보호**
   - `.env` 파일에 민감한 정보 저장
   - `.gitignore`에 `.env` 추가

4. **정기적인 업데이트**
   ```bash
   # 시스템 업데이트
   sudo apt-get update && sudo apt-get upgrade
   
   # Python 패키지 업데이트
   source venv/bin/activate
   pip install --upgrade -r requirements.txt
   ```

---

## 성능 최적화

1. **워커 수 조정**: CPU 코어에 맞게 설정
2. **타임아웃 조정**: PDF 크기에 따라 증가
3. **로그 로테이션**: logrotate 설정
4. **캐싱**: CDN 또는 Nginx 캐싱 사용

---

더 자세한 정보는 [README.md](README.md)를 참고하세요.

