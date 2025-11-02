# 빠른 시작 가이드

## 개발 환경 - 1분 안에 시작하기

### 로컬 테스트/개발

```bash
# 1. 스크립트 실행 권한 부여 (최초 1회만)
chmod +x setup_and_run.sh

# 2. 실행
./setup_and_run.sh
```

끝! 🎉 개발 서버가 http://localhost:3000 에서 실행됩니다.

## Production 환경 - 배포하기 ⭐

### 서버 배포 (최초 1회)

```bash
# 배포 스크립트 실행
./deploy.sh

# 서버 시작
./start.sh
```

끝! 🚀 Production 서버가 백그라운드에서 실행됩니다.

### 서버 관리

```bash
./status.sh    # 상태 확인
./stop.sh      # 중지
./restart.sh   # 재시작
./start.sh     # 시작
```

---

## API 테스트하기

### 1. 서버 상태 확인

```bash
curl http://localhost:3000/health
```

### 2. PDF를 JPG로 변환하고 업로드

```bash
curl -X POST http://localhost:3000/convert \
  -H "Content-Type: application/json" \
  -d '{
    "pdfUrl": "https://your-r2-bucket.com/sample.pdf",
    "uploadUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image",
    "headers": {
      "Authorization": "Bearer your-token"
    }
  }'
```

### 3. Python으로 테스트

```python
import requests

response = requests.post(
    'http://localhost:3000/convert',
    json={
        'pdfUrl': 'https://your-r2-bucket.com/sample.pdf',
        'uploadUrl': 'https://pdf-to-summary-api.moveto.workers.dev/upload-image',
        'headers': {
            'Authorization': 'Bearer your-token'
        }
    }
)

result = response.json()
print(f"업로드 완료: {result['uploaded']}/{result['totalPages']} 페이지")
```

---

## 다음 실행부터는?

### 개발 환경
```bash
./run.sh
```

### Production 환경
```bash
./start.sh    # 시작
./status.sh   # 상태 확인
./stop.sh     # 중지
```

---

## 문제 해결

### Poppler가 설치되지 않았다는 오류

#### macOS
```bash
brew install poppler
```

#### Ubuntu/Debian (최신 버전)
```bash
sudo apt-get update
sudo apt-get install -y poppler-utils
```

#### Debian Buster 또는 구버전 (저장소 404 오류 발생 시)
```bash
chmod +x install_poppler_debian.sh
./install_poppler_debian.sh
```

이 스크립트가 자동으로 문제를 해결합니다:
- Archive 저장소로 전환
- 또는 소스에서 컴파일

자세한 내용: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

#### CentOS/RHEL
```bash
sudo yum install -y poppler-utils
```

### Python을 찾을 수 없다는 오류

Python 3.8 이상을 설치해주세요: https://www.python.org/downloads/

---

## 더 알아보기

- **기본 사용법**: [README.md](README.md)
- **Production 배포**: [DEPLOY.md](DEPLOY.md) ⭐
- **문제 해결**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

