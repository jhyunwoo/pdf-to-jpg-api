# PDF to JPG Converter & Upload API

Cloudflare R2에 업로드된 PDF 파일을 다운로드하여 JPG 이미지로 변환하고, 변환된 이미지를 지정된 API에 자동으로 업로드하는 Flask 기반 REST API입니다.

## 기능

- ✅ Cloudflare R2 (또는 모든 공개 URL)에서 PDF 파일 다운로드
- ✅ PDF를 고품질 JPG 이미지로 변환
- ✅ 변환된 각 페이지를 지정된 API에 PUT 요청으로 자동 업로드
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

#### Windows
1. [Poppler for Windows](http://blog.alivate.com.au/poppler-windows/)에서 다운로드
2. PATH에 bin 폴더 추가

## 빠른 시작 (자동 설치 스크립트)

### 방법 1: 자동 설치 및 실행 스크립트 사용 (권장)

가장 간단한 방법입니다. 스크립트가 자동으로 환경을 설정하고 서버를 실행합니다.

#### macOS/Linux
```bash
chmod +x setup_and_run.sh
./setup_and_run.sh
```

#### Windows
```cmd
setup_and_run.bat
```

이 스크립트는 다음을 자동으로 수행합니다:
- ✅ Python 버전 확인
- ✅ Poppler 설치 확인 및 설치 (macOS는 자동, Linux/Windows는 안내)
- ✅ 가상환경 생성
- ✅ 패키지 설치
- ✅ 서버 실행

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

### 환경이 이미 설정된 경우

#### macOS/Linux
```bash
./run.sh
```

#### Windows
```cmd
run.bat
```

### 또는 직접 실행
```bash
source venv/bin/activate  # 가상환경 활성화 (macOS/Linux)
# venv\Scripts\activate  # Windows
python app.py
```

서버가 `http://localhost:5000`에서 실행됩니다.

## 스크립트 파일 설명

- **`setup_and_run.sh`** / **`setup_and_run.bat`**: 환경 설정부터 서버 실행까지 한 번에 (최초 실행 시)
- **`setup.sh`**: 환경만 설정하고 서버는 실행하지 않음
- **`run.sh`** / **`run.bat`**: 이미 설정된 환경에서 서버만 실행

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
  "url": "https://your-r2-bucket.com/path/to/file.pdf",
  "upload_url": "https://api.example.com/upload/image",
  "headers": {
    "Authorization": "Bearer your-token-here"
  }
}
```

**파라미터:**
- `url` (필수): PDF 파일의 URL
- `upload_url` (필수): 변환된 이미지를 업로드할 API URL (각 이미지마다 PUT 요청)
- `headers` (선택): 업로드 요청에 포함할 커스텀 헤더

**응답 예시:**
```json
{
  "pdf_url": "https://your-r2-bucket.com/sample.pdf",
  "upload_url": "https://api.example.com/upload/image",
  "total_pages": 3,
  "uploaded": 3,
  "failed": 0,
  "status": "completed",
  "results": [
    {
      "page": 1,
      "status": "success",
      "status_code": 200,
      "message": "업로드 성공",
      "response": null
    },
    {
      "page": 2,
      "status": "success",
      "status_code": 200,
      "message": "업로드 성공",
      "response": null
    },
    {
      "page": 3,
      "status": "success",
      "status_code": 200,
      "message": "업로드 성공",
      "response": null
    }
  ]
}
```

**curl 예시:**
```bash
# PDF를 변환하고 API에 업로드
curl -X POST http://localhost:5000/convert \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-r2-bucket.com/sample.pdf",
    "upload_url": "https://api.example.com/upload/image",
    "headers": {
      "Authorization": "Bearer your-token-here"
    }
  }'

# 헤더 없이 업로드
curl -X POST http://localhost:5000/convert \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-r2-bucket.com/sample.pdf",
    "upload_url": "https://api.example.com/upload/image"
  }'
```

### 4. PDF 정보 조회
```
POST /convert/info
```

**요청 본문:**
```json
{
  "url": "https://your-r2-bucket.com/path/to/file.pdf"
}
```

**응답 예시:**
```json
{
  "url": "https://your-r2-bucket.com/path/to/file.pdf",
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
    'http://localhost:5000/convert',
    json={
        'url': 'https://your-r2-bucket.com/sample.pdf',
        'upload_url': 'https://api.example.com/upload/image',
        'headers': {
            'Authorization': 'Bearer your-token-here'
        }
    }
)

result = response.json()
print(f"변환 완료! {result['uploaded']}/{result['total_pages']} 페이지 업로드 성공")
print(f"상태: {result['status']}")

# 각 페이지별 업로드 결과 확인
for page_result in result['results']:
    print(f"페이지 {page_result['page']}: {page_result['status']} - {page_result['message']}")
```

### JavaScript로 API 호출
```javascript
// PDF를 변환하고 API에 업로드
fetch('http://localhost:5000/convert', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    url: 'https://your-r2-bucket.com/sample.pdf',
    upload_url: 'https://api.example.com/upload/image',
    headers: {
      'Authorization': 'Bearer your-token-here'
    }
  })
})
  .then(response => response.json())
  .then(data => {
    console.log(`총 ${data.total_pages}페이지 중 ${data.uploaded}페이지 업로드 성공`);
    console.log('업로드 결과:', data.results);
  });

// PDF 정보만 조회
fetch('http://localhost:5000/convert/info', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    url: 'https://your-r2-bucket.com/sample.pdf'
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

### 프로덕션 배포
프로덕션 환경에서는 Gunicorn이나 uWSGI를 사용하는 것을 권장합니다:

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

## 주의사항

- PDF 파일은 공개적으로 접근 가능한 URL이어야 합니다
- 업로드 API는 PUT 요청을 받아야 하며, `Content-Type: image/jpeg` 형식으로 전송됩니다
- 대용량 PDF 파일은 처리 시간이 오래 걸릴 수 있습니다
- 각 페이지는 순차적으로 업로드됩니다
- 업로드 실패한 페이지가 있어도 다음 페이지는 계속 처리됩니다
- 임시 파일은 자동으로 정리됩니다
- DPI 설정은 `app.py`에서 조정할 수 있습니다 (현재: 200 DPI)
- 업로드 타임아웃은 60초로 설정되어 있습니다

## 업로드 API 요구사항

이 API가 이미지를 업로드하는 외부 API는 다음 조건을 만족해야 합니다:

- **HTTP 메서드**: PUT
- **Content-Type**: `image/jpeg`
- **요청 본문**: JPEG 이미지의 바이너리 데이터
- **커스텀 헤더**: 필요시 `headers` 파라미터로 전달 가능 (예: Authorization)

**예시: 업로드 API가 받는 요청**
```http
PUT /upload/image HTTP/1.1
Host: api.example.com
Content-Type: image/jpeg
Authorization: Bearer your-token-here
Content-Length: 123456

[JPEG binary data]
```

## 라이선스

MIT License

## 기여

이슈 및 풀 리퀘스트를 환영합니다!

