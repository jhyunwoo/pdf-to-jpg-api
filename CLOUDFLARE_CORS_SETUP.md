# Cloudflare Tunnel에서 CORS 완벽 설정하기

Cloudflare Tunnel을 사용할 때 모든 origin에서의 요청을 허용하는 방법입니다.

## 1. Flask 앱 레벨 CORS (이미 설정됨)

`app.py`에 이미 다음이 설정되어 있습니다:

```python
from flask_cors import CORS

CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

이것만으로도 충분하지만, 더 확실하게 하려면 Cloudflare 레벨에서도 설정할 수 있습니다.

## 2. Cloudflare Transform Rules로 CORS 헤더 추가

### 방법 A: Cloudflare 대시보드 사용 (권장)

1. **Cloudflare 대시보드 접속**
   - https://dash.cloudflare.com 로그인
   - 도메인 선택 (예: moveto.kr)

2. **Transform Rules 메뉴로 이동**
   - 왼쪽 메뉴: `Rules` → `Transform Rules`
   - `HTTP Response Headers` 선택
   - `Create rule` 클릭

3. **규칙 생성**
   - **Rule name**: `CORS Allow All Origins`
   
   - **When incoming requests match**: 
     - Field: `Hostname`
     - Operator: `equals`
     - Value: `pdf-to-jpg.moveto.kr`
   
   - **Then**: `Set static`을 선택하고 다음 헤더들을 추가:
     
     | Header name | Value |
     |-------------|-------|
     | `Access-Control-Allow-Origin` | `*` |
     | `Access-Control-Allow-Methods` | `GET, POST, PUT, DELETE, OPTIONS` |
     | `Access-Control-Allow-Headers` | `Content-Type, Authorization, X-Requested-With` |
     | `Access-Control-Max-Age` | `86400` |

4. **Deploy** 클릭

### 방법 B: Cloudflare API 사용

```bash
# Cloudflare API Token 필요 (대시보드에서 생성)

ZONE_ID="your-zone-id"  # Cloudflare 대시보드에서 확인
API_TOKEN="your-api-token"

curl -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/rulesets/phases/http_response_headers_transform/entrypoint" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "rules": [
      {
        "action": "rewrite",
        "action_parameters": {
          "headers": {
            "Access-Control-Allow-Origin": {
              "operation": "set",
              "value": "*"
            },
            "Access-Control-Allow-Methods": {
              "operation": "set",
              "value": "GET, POST, PUT, DELETE, OPTIONS"
            },
            "Access-Control-Allow-Headers": {
              "operation": "set",
              "value": "Content-Type, Authorization, X-Requested-With"
            },
            "Access-Control-Max-Age": {
              "operation": "set",
              "value": "86400"
            }
          }
        },
        "expression": "(http.host eq \"pdf-to-jpg.moveto.kr\")",
        "description": "CORS Allow All Origins"
      }
    ]
  }'
```

## 3. Cloudflare Workers로 CORS 처리 (고급)

더 세밀한 제어가 필요하다면 Cloudflare Worker를 사용할 수 있습니다.

### Worker 코드

Cloudflare 대시보드:
1. `Workers & Pages` 메뉴
2. `Create application` → `Create Worker`
3. 다음 코드 입력:

```javascript
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // OPTIONS 요청 처리 (Preflight)
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders()
    })
  }

  // 원본 요청을 백엔드로 전달
  const response = await fetch(request)
  
  // CORS 헤더 추가
  const newResponse = new Response(response.body, response)
  const headers = corsHeaders()
  
  for (const [key, value] of Object.entries(headers)) {
    newResponse.headers.set(key, value)
  }
  
  return newResponse
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Max-Age': '86400'
  }
}
```

4. `Save and Deploy` 클릭
5. Worker 라우트 설정:
   - `Triggers` → `Add route`
   - Route: `pdf-to-jpg.moveto.kr/*`
   - Zone: moveto.kr 선택

## 4. 테스트

### CORS 테스트 명령어

```bash
# Preflight 요청 테스트
curl -X OPTIONS https://pdf-to-jpg.moveto.kr/convert \
  -H "Origin: https://pdf-to-summary-web.moveto.workers.dev" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v

# 실제 요청 테스트
curl -X POST https://pdf-to-jpg.moveto.kr/convert \
  -H "Origin: https://pdf-to-summary-web.moveto.workers.dev" \
  -H "Content-Type: application/json" \
  -d '{"pdfUrl": "https://example.com/test.pdf", "uploadUrl": "https://example.com/upload"}' \
  -v
```

### 브라우저 콘솔에서 테스트

```javascript
// 브라우저 개발자 도구 콘솔에서 실행
fetch('https://pdf-to-jpg.moveto.kr/health', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log('성공:', data))
.catch(error => console.error('에러:', error));
```

### 예상 응답 헤더

성공적으로 설정되면 다음 헤더들이 포함되어야 합니다:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
Access-Control-Max-Age: 86400
```

## 5. 문제 해결

### CORS 에러가 계속 발생하는 경우

1. **Flask-CORS 확인**
```bash
# requirements.txt에 있는지 확인
grep flask-cors requirements.txt

# 설치 확인
pip list | grep -i cors
```

2. **Cloudflare 캐시 삭제**
```bash
# Cloudflare 대시보드
# Caching → Configuration → Purge Everything
```

3. **브라우저 캐시 삭제**
- 개발자 도구 (F12)
- Network 탭
- "Disable cache" 체크
- 페이지 새로고침 (Ctrl+Shift+R)

4. **응답 헤더 확인**
```bash
curl -I https://pdf-to-jpg.moveto.kr/health
```

## 6. 완전한 설정 예제

### app.py (이미 설정됨)

```python
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)

# CORS 설정 - 모든 origin 허용
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "expose_headers": ["Content-Type", "Authorization"],
        "supports_credentials": False,
        "max_age": 86400
    }
})
```

### 프론트엔드 요청 예제

```javascript
// React, Vue, 또는 일반 JavaScript에서
const response = await fetch('https://pdf-to-jpg.moveto.kr/convert', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    // Authorization 헤더가 필요한 경우
    // 'Authorization': 'Bearer your-token'
  },
  body: JSON.stringify({
    pdfUrl: 'https://example.com/file.pdf',
    uploadUrl: 'https://pdf-to-summary-api.moveto.workers.dev/upload-image'
  })
});

const data = await response.json();
console.log(data);
```

## 7. 보안 고려사항

### 프로덕션에서 특정 origin만 허용하기 (권장)

모든 origin(`*`)을 허용하는 것보다 특정 도메인만 허용하는 것이 더 안전합니다:

#### app.py 수정

```python
CORS(app, resources={
    r"/*": {
        "origins": [
            "https://pdf-to-summary-web.moveto.workers.dev",
            "https://yourdomain.com",
            "http://localhost:5173",  # 개발 환경
            "http://localhost:3000"   # 개발 환경
        ],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
        "supports_credentials": True  # 쿠키를 사용하는 경우
    }
})
```

#### Cloudflare Transform Rules (특정 origin만)

```javascript
// Worker 코드 수정
function corsHeaders(origin) {
  const allowedOrigins = [
    'https://pdf-to-summary-web.moveto.workers.dev',
    'https://yourdomain.com'
  ];
  
  const allowOrigin = allowedOrigins.includes(origin) ? origin : allowedOrigins[0];
  
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Max-Age': '86400'
  }
}
```

## 요약

**가장 간단한 방법** (추천):

1. ✅ Flask-CORS가 이미 설정되어 있음 (`app.py`)
2. ✅ Cloudflare Tunnel 사용 시 추가 설정 불필요
3. ✅ 문제 발생 시 Cloudflare Transform Rules 추가

**설정 확인**:
```bash
# 1. Flask-CORS 설치 확인
pip show flask-cors

# 2. 서버 재시작
./restart.sh

# 3. CORS 테스트
curl -I https://pdf-to-jpg.moveto.kr/health
```

Flask-CORS가 이미 모든 origin을 허용하도록 설정되어 있으므로, Cloudflare Tunnel을 사용하면 바로 작동해야 합니다! 🎉

