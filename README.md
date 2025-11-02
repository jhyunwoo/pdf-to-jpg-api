# PDF to JPG Converter & Upload API

Cloudflare R2에 업로드된 PDF 파일을 다운로드하여 JPG 이미지로 변환하고, 변환된 이미지를 지정된 API에 자동으로 업로드하는 Flask 기반 REST API입니다.

## 기능

- ✅ Cloudflare R2 (또는 모든 공개 URL)에서 PDF 파일 다운로드
- ✅ PDF를 고품질 JPG 이미지로 변환
- ✅ 변환된 각 페이지를 지정된 API에 RAW 바디 스트리밍 PUT 요청으로 자동 업로드
- ✅ 커스텀 헤더 지원 (Authorization 등)
- ✅ 업로드 성공/실패 상세 정보 제공
- ✅ PDF 정보 조회 (페이지 수)

## 사전 요구사항

### 시스템 의존성

이 프로젝트는 `pdf2image` 라이브러리를 사용하며, 이는 `poppler`에 의존합니다.

#### macOS
```bash
brew install poppler
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y poppler-utils
```

**⚠️ Debian Buster 등 구버전 사용 시:**
저장소 404 오류가 발생하면 전용 설치 스크립트를 사용하세요:
```bash
./install_poppler_debian.sh
```

#### CentOS/RHEL
```bash
sudo yum install -y poppler-utils
```

> **참고**: 이 API는 Linux/Unix 환경에 최적화되어 있습니다.

## 빠른 시작

### 개발 환경

개발 환경에서 테스트하려면:

```bash
chmod +x setup_and_run.sh
./setup_and_run.sh
```

이 스크립트는 다음을 자동으로 수행합니다:
- ✅ Python 버전 확인
- ✅ Poppler 설치 확인 및 설치
- ✅ 가상환경 생성
- ✅ 패키지 설치
- ✅ 개발 서버 실행

### Production 환경 ⭐

Production 환경에서 배포하려면:

```bash
# 1. 배포 (최초 1회)
./deploy.sh

# 2. 서버 시작
./start.sh
```

**서버 관리:**
- 시작: `./start.sh`
- 중지: `./stop.sh`
- 재시작: `./restart.sh`
- 상태 확인: `./status.sh`

자세한 배포 가이드는 **[DEPLOY.md](DEPLOY.md)**를 참고하세요.

### 방법 2: 수동 설치

1. 저장소 클론 (또는 프로젝트 디렉토리로 이동)
```bash
cd pdf-to-jpg-api
```

2. 가상환경 생성 및 활성화 (권장)
```bash
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate  # Windows
```

3. 의존성 설치
```bash
pip install -r requirements.txt
```

## 실행

### 개발 환경
```bash
./run.sh
```

또는 직접 실행:
```bash
source venv/bin/activate
python app.py
```

### Production 환경
```bash
./start.sh    # 백그라운드에서 실행
./status.sh   # 상태 확인
./stop.sh     # 중지
./restart.sh  # 재시작
```

서버가 `http://localhost:3000`에서 실행됩니다.

## 스크립트 파일 설명

### 개발용
- **`setup_and_run.sh`**: 개발 환경 설정 + 서버 실행 (최초 실행)
- **`setup.sh`**: 환경만 설정
- **`run.sh`**: 개발 서버 실행 (Flask 내장 서버)

### Production용 ⭐
- **`deploy.sh`**: Production 배포 (환경 설정 + Gunicorn 설치)
- **`start.sh`**: Production 서버 시작 (백그라운드)
- **`stop.sh`**: 서버 중지
- **`restart.sh`**: 서버 재시작
- **`status.sh`**: 서버 상태 확인

### 기타
- **`install_poppler_debian.sh`**: Debian/Ubuntu용 Poppler 설치
- **`gunicorn_config.py`**: Gunicorn 설정 파일

## API 엔드포인트

### 1. 홈 (API 정보)
```
GET /
```

응답 예시:
```json
{
  "service": "PDF to JPG Converter API",
  "version": "1.0.0",
  "endpoints": {...}
}
```

### 2. 헬스 체크
```
GET /health
```

응답 예시:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-31T12:00:00.000000"
}
```

### 3. PDF를 JPG로 변환하고 API에 업로드
```
POST /convert
```

**요청 본문:**
```json
{
  "pdfUrl": "https://your-r2-bucket.com/path/to/file.pdf",
  "uploadUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image",
  "headers": {
    "Authorization": "Bearer your-token-here"
  }
}
```

**파라미터:**
- `pdfUrl` (필수): PDF 파일의 URL
- `uploadUrl` (필수): 변환된 이미지를 업로드할 API 기본 URL (각 이미지마다 PUT /upload-image/:filename 요청)
- `headers` (선택): 업로드 요청에 포함할 커스텀 헤더

**응답 예시:**
```json
{
  "pdfUrl": "https://your-r2-bucket.com/sample.pdf",
  "uploadUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image",
  "totalPages": 3,
  "uploaded": 3,
  "failed": 0,
  "status": "completed",
  "results": [
    {
      "page": 1,
      "status": "success",
      "statusCode": 200,
      "message": "업로드 성공",
      "uploadedUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image/page_1.jpg",
      "response": {
        "ok": true,
        "key": "uploaded-image-key",
        "url": "https://...",
        "size": 123456
      }
    },
    {
      "page": 2,
      "status": "success",
      "statusCode": 200,
      "message": "업로드 성공",
      "uploadedUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image/page_2.jpg",
      "response": {
        "ok": true,
        "key": "uploaded-image-key",
        "url": "https://...",
        "size": 123456
      }
    },
    {
      "page": 3,
      "status": "success",
      "statusCode": 200,
      "message": "업로드 성공",
      "uploadedUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image/page_3.jpg",
      "response": {
        "ok": true,
        "key": "uploaded-image-key",
        "url": "https://...",
        "size": 123456
      }
    }
  ]
}
```

**curl 예시:**
```bash
# PDF를 변환하고 API에 업로드
curl -X POST http://localhost:3000/convert \
  -H "Content-Type: application/json" \
  -d '{
    "pdfUrl": "https://your-r2-bucket.com/sample.pdf",
    "uploadUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image",
    "headers": {
      "Authorization": "Bearer your-token-here"
    }
  }'

# 헤더 없이 업로드
curl -X POST http://localhost:3000/convert \
  -H "Content-Type: application/json" \
  -d '{
    "pdfUrl": "https://your-r2-bucket.com/sample.pdf",
    "uploadUrl": "https://pdf-to-summary-api.moveto.workers.dev/upload-image"
  }'
```

### 4. PDF 정보 조회
```
POST /convert/info
```

**요청 본문:**
```json
{
  "pdfUrl": "https://your-r2-bucket.com/path/to/file.pdf"
}
```

**응답 예시:**
```json
{
  "pdfUrl": "https://your-r2-bucket.com/path/to/file.pdf",
  "pages": 5,
  "status": "success"
}
```

## 사용 예시

### Python으로 API 호출
```python
import requests

# PDF를 변환하고 API에 업로드
response = requests.post(
    'http://localhost:3000/convert',
    json={
        'pdfUrl': 'https://your-r2-bucket.com/sample.pdf',
        'uploadUrl': 'https://pdf-to-summary-api.moveto.workers.dev/upload-image',
        'headers': {
            'Authorization': 'Bearer your-token-here'
        }
    }
)

result = response.json()
print(f"변환 완료! {result['uploaded']}/{result['totalPages']} 페이지 업로드 성공")
print(f"상태: {result['status']}")

# 각 페이지별 업로드 결과 확인
for page_result in result['results']:
    print(f"페이지 {page_result['page']}: {page_result['status']} - {page_result['message']}")
    if page_result.get('response'):
        print(f"  업로드된 URL: {page_result['response'].get('url')}")
```

### JavaScript로 API 호출
```javascript
// PDF를 변환하고 API에 업로드
fetch('http://localhost:3000/convert', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    pdfUrl: 'https://your-r2-bucket.com/sample.pdf',
    uploadUrl: 'https://pdf-to-summary-api.moveto.workers.dev/upload-image',
    headers: {
      'Authorization': 'Bearer your-token-here'
    }
  })
})
  .then(response => response.json())
  .then(data => {
    console.log(`총 ${data.totalPages}페이지 중 ${data.uploaded}페이지 업로드 성공`);
    console.log('업로드 결과:', data.results);
  });

// PDF 정보만 조회
fetch('http://localhost:3000/convert/info', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    pdfUrl: 'https://your-r2-bucket.com/sample.pdf'
  })
})
  .then(response => response.json())
  .then(data => console.log('페이지 수:', data.pages));
```

## 에러 처리

API는 다음과 같은 에러 응답을 반환합니다:

```json
{
  "error": "에러 제목",
  "message": "상세 에러 메시지"
}
```

**일반적인 에러 코드:**
- `400`: 잘못된 요청 (URL 누락 또는 잘못된 형식)
- `500`: 서버 오류 (다운로드 실패, 변환 실패 등)

## 개발

### 디버그 모드
앱은 기본적으로 디버그 모드로 실행됩니다. 프로덕션 환경에서는 `app.py`를 수정하거나 WSGI 서버를 사용하세요.

### Production 배포

Production 환경에서는 Gunicorn을 사용합니다:

```bash
# 간단한 방법
./deploy.sh
./start.sh

# 또는 수동으로
source venv/bin/activate
gunicorn -c gunicorn_config.py app:app
```

**자세한 배포 가이드**: [DEPLOY.md](DEPLOY.md)

#### Production 설정
- ✅ Gunicorn WSGI 서버
- ✅ 다중 워커 프로세스
- ✅ 백그라운드 실행
- ✅ 자동 재시작
- ✅ 로그 관리
- ✅ 환경 변수 설정

## 주의사항

- PDF 파일은 공개적으로 접근 가능한 URL이어야 합니다
- 업로드 API는 PUT 요청을 받아야 하며, RAW 바이너리 스트림으로 전송됩니다
- 파일명은 URL 경로에 포함됩니다 (예: PUT /upload-image/page_1.jpg)
- 대용량 PDF 파일은 처리 시간이 오래 걸릴 수 있습니다
- 각 페이지는 순차적으로 업로드됩니다
- 업로드 실패한 페이지가 있어도 다음 페이지는 계속 처리됩니다
- 임시 파일은 자동으로 정리됩니다
- DPI 설정은 `app.py`에서 조정할 수 있습니다 (현재: 200 DPI)
- 업로드 타임아웃은 60초로 설정되어 있습니다

## 업로드 API 요구사항

이 API가 이미지를 업로드하는 외부 API는 다음 조건을 만족해야 합니다:

- **HTTP 메서드**: PUT
- **URL 형식**: `/upload-image/:filename` (파일명이 URL 경로에 포함됨)
- **Content-Type**: `image/jpeg`
- **요청 본문**: JPEG 이미지의 RAW 바이너리 스트림
- **파일명**: `page_{페이지번호}.jpg` (예: page_1.jpg, page_2.jpg)
- **커스텀 헤더**: 필요시 `headers` 파라미터로 전달 가능 (예: Authorization)

**예시: 업로드 API가 받는 요청**
```http
PUT /upload-image/page_1.jpg HTTP/1.1
Host: pdf-to-summary-api.moveto.workers.dev
Content-Type: image/jpeg
Authorization: Bearer your-token-here
Content-Length: 123456

[JPEG binary data - RAW byte stream]
```

**예상 응답 형식:**
```json
{
  "ok": true,
  "key": "unique-image-key",
  "url": "https://storage.example.com/images/unique-image-key.jpg",
  "size": 123456
}
```

## 문제 해결

설치 또는 실행 중 문제가 발생하면 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)를 참고하세요.

주요 문제:
- **Debian Buster 저장소 오류**: `./install_poppler_debian.sh` 실행
- **Poppler 설치 실패**: 전용 설치 스크립트 또는 수동 설치
- **포트 충돌**: `app.py`에서 포트 번호 변경
- **패키지 설치 오류**: pip 업그레이드 및 재설치

## 라이선스

MIT License

## 기여

이슈 및 풀 리퀘스트를 환영합니다!

