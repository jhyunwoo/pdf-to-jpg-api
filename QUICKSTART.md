# 빠른 시작 가이드

## 1분 안에 시작하기

### macOS에서 실행

```bash
# 1. 스크립트 실행 권한 부여 (최초 1회만)
chmod +x setup_and_run.sh

# 2. 실행
./setup_and_run.sh
```

끝! 🎉 서버가 http://localhost:5000 에서 실행됩니다.

### Windows에서 실행

```cmd
setup_and_run.bat
```

끝! 🎉 서버가 http://localhost:5000 에서 실행됩니다.

---

## API 테스트하기

### 1. 서버 상태 확인

```bash
curl http://localhost:5000/health
```

### 2. PDF를 JPG로 변환하고 업로드

```bash
curl -X POST http://localhost:5000/convert \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-r2-bucket.com/sample.pdf",
    "upload_url": "https://api.example.com/upload/image",
    "headers": {
      "Authorization": "Bearer your-token"
    }
  }'
```

### 3. Python으로 테스트

```python
import requests

response = requests.post(
    'http://localhost:5000/convert',
    json={
        'url': 'https://your-r2-bucket.com/sample.pdf',
        'upload_url': 'https://api.example.com/upload/image',
        'headers': {
            'Authorization': 'Bearer your-token'
        }
    }
)

result = response.json()
print(f"업로드 완료: {result['uploaded']}/{result['total_pages']} 페이지")
```

---

## 다음 실행부터는?

이미 환경이 설정되어 있다면 더 빠르게 실행할 수 있습니다:

### macOS/Linux
```bash
./run.sh
```

### Windows
```cmd
run.bat
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

#### Windows
1. [Poppler for Windows](https://github.com/oschwartz10612/poppler-windows/releases/) 다운로드
2. 압축 해제 후 `bin` 폴더를 시스템 PATH에 추가

### Python을 찾을 수 없다는 오류

Python 3.8 이상을 설치해주세요: https://www.python.org/downloads/

---

더 자세한 내용은 [README.md](README.md)를 참고하세요!

