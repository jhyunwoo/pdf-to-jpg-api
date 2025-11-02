#!/bin/bash

# CORS 테스트 스크립트
# Usage: ./test_cors.sh [URL]

URL=${1:-"https://pdf-to-jpg.moveto.kr"}
ORIGIN="https://pdf-to-summary-web.moveto.workers.dev"

echo "=== CORS 테스트 시작 ==="
echo "API URL: $URL"
echo "Origin: $ORIGIN"
echo ""

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Preflight 요청 테스트 (OPTIONS)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Preflight 요청 테스트 (OPTIONS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PREFLIGHT_RESPONSE=$(curl -s -X OPTIONS "$URL/health" \
  -H "Origin: $ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -i)

echo "$PREFLIGHT_RESPONSE"
echo ""

# CORS 헤더 확인
if echo "$PREFLIGHT_RESPONSE" | grep -qi "Access-Control-Allow-Origin: \*"; then
    echo -e "${GREEN}✓ Access-Control-Allow-Origin: * 설정됨${NC}"
else
    echo -e "${RED}✗ Access-Control-Allow-Origin 누락${NC}"
fi

if echo "$PREFLIGHT_RESPONSE" | grep -qi "Access-Control-Allow-Methods"; then
    echo -e "${GREEN}✓ Access-Control-Allow-Methods 설정됨${NC}"
else
    echo -e "${RED}✗ Access-Control-Allow-Methods 누락${NC}"
fi

if echo "$PREFLIGHT_RESPONSE" | grep -qi "Access-Control-Allow-Headers"; then
    echo -e "${GREEN}✓ Access-Control-Allow-Headers 설정됨${NC}"
else
    echo -e "${RED}✗ Access-Control-Allow-Headers 누락${NC}"
fi

echo ""

# 2. 실제 GET 요청 테스트
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. GET 요청 테스트 (/health)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

GET_RESPONSE=$(curl -s -X GET "$URL/health" \
  -H "Origin: $ORIGIN" \
  -i)

echo "$GET_RESPONSE"
echo ""

if echo "$GET_RESPONSE" | grep -qi "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✓ CORS 헤더 포함됨${NC}"
else
    echo -e "${RED}✗ CORS 헤더 누락${NC}"
fi

echo ""

# 3. 실제 POST 요청 테스트
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. POST 요청 테스트 (API 호출 시뮬레이션)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 실제 convert API를 호출하지 않고 헤더만 확인
POST_RESPONSE=$(curl -s -X POST "$URL/health" \
  -H "Origin: $ORIGIN" \
  -H "Content-Type: application/json" \
  -i)

echo "$POST_RESPONSE"
echo ""

if echo "$POST_RESPONSE" | grep -qi "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✓ POST 요청 CORS 헤더 포함됨${NC}"
else
    echo -e "${RED}✗ POST 요청 CORS 헤더 누락${NC}"
fi

echo ""

# 4. 요약
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 테스트 요약"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 모든 필수 헤더 확인
REQUIRED_HEADERS=(
    "Access-Control-Allow-Origin"
    "Access-Control-Allow-Methods"
    "Access-Control-Allow-Headers"
)

ALL_PASS=true
for header in "${REQUIRED_HEADERS[@]}"; do
    if echo "$PREFLIGHT_RESPONSE" | grep -qi "$header"; then
        echo -e "${GREEN}✓${NC} $header"
    else
        echo -e "${RED}✗${NC} $header"
        ALL_PASS=false
    fi
done

echo ""

if [ "$ALL_PASS" = true ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    모든 CORS 테스트 통과! ✓${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}    CORS 설정에 문제가 있습니다 ✗${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "문제 해결:"
    echo "1. Flask-CORS가 설치되어 있는지 확인: pip show flask-cors"
    echo "2. 서버를 재시작: ./restart.sh"
    echo "3. CLOUDFLARE_CORS_SETUP.md 문서 참조"
fi

echo ""
echo "=== 테스트 완료 ==="

