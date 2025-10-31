# 문제 해결 가이드

## Debian Buster (또는 구버전) 저장소 오류

### 증상
```
E: The repository 'http://deb.debian.org/debian buster Release' does not have a Release file.
```

### 원인
Debian Buster는 2022년에 EOL(End of Life)되어 archive.debian.org로 이동되었습니다.

### 해결 방법

#### 방법 1: 전용 설치 스크립트 사용 (권장)

```bash
chmod +x install_poppler_debian.sh
./install_poppler_debian.sh
```

이 스크립트는 자동으로:
1. 일반 apt-get 설치 시도
2. 실패 시 Debian Archive 저장소로 전환
3. 여전히 실패 시 소스에서 컴파일

#### 방법 2: 수동으로 저장소 변경

```bash
# 백업 생성
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# sources.list 수정
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF

# Archive 저장소용 설정
sudo tee /etc/apt/apt.conf.d/99archive > /dev/null <<EOF
Acquire::Check-Valid-Until "false";
EOF

# 업데이트 및 설치
sudo apt-get update
sudo apt-get install -y poppler-utils
```

#### 방법 3: Poppler 없이 진행 (테스트용)

Poppler 없이 서버를 실행할 수 있지만, PDF 변환 API는 작동하지 않습니다.

```bash
# setup_and_run.sh 실행 시 "Poppler 없이 계속" 선택
# 또는 직접:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

⚠️ **주의**: `/convert` 엔드포인트는 Poppler 없이는 오류를 반환합니다.

---

## Python 관련 오류

### Python을 찾을 수 없음
```bash
# Ubuntu/Debian
sudo apt-get install python3 python3-pip python3-venv

# CentOS/RHEL
sudo yum install python3 python3-pip
```

### 가상환경 생성 실패
```bash
# venv 모듈 설치
sudo apt-get install python3-venv  # Ubuntu/Debian
```

---

## 권한 오류

### 스크립트 실행 권한
```bash
chmod +x setup_and_run.sh
chmod +x run.sh
chmod +x install_poppler_debian.sh
```

### sudo 없이 실행하려면
Poppler를 사전 설치:
```bash
sudo apt-get install poppler-utils
```

그 다음 스크립트 실행 시 Poppler 설치 단계를 건너뜁니다.

---

## 패키지 설치 오류

### pip 업그레이드 필요
```bash
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 특정 패키지 설치 실패

#### pdf2image
```bash
pip install pdf2image --no-cache-dir
```

#### Pillow (이미지 처리 라이브러리)
```bash
# 시스템 의존성 먼저 설치
sudo apt-get install libjpeg-dev zlib1g-dev

# 그 다음 Pillow 설치
pip install Pillow
```

---

## 서버 실행 오류

### 포트 3000이 이미 사용 중
```bash
# app.py 수정하여 다른 포트 사용
# 마지막 줄 수정:
app.run(debug=True, host='0.0.0.0', port=8000)
```

또는 기존 프로세스 종료:
```bash
# 3000 포트 사용 중인 프로세스 찾기
sudo lsof -i :3000

# 프로세스 종료
kill -9 <PID>
```

---

## API 테스트 오류

### PDF 다운로드 실패
- PDF URL이 공개적으로 접근 가능한지 확인
- 방화벽이 외부 연결을 차단하지 않는지 확인

### 업로드 API 오류
- `upload_url`이 PUT 요청을 받는지 확인
- 인증 헤더가 올바른지 확인
- 업로드 API가 `Content-Type: image/jpeg`를 받는지 확인

---

## 로그 확인

### Flask 디버그 모드
기본적으로 활성화되어 있습니다. 콘솔에 상세한 오류 메시지가 표시됩니다.

### Python 오류 추적
```bash
python app.py 2>&1 | tee server.log
```

---

## 추가 도움

문제가 해결되지 않으면:
1. Python 버전 확인: `python3 --version` (3.8 이상 필요)
2. Poppler 설치 확인: `pdfinfo -v`
3. 가상환경 활성화 확인: `which python` (venv 경로가 나와야 함)

GitHub Issues에 다음 정보와 함께 문의:
- OS 및 버전
- Python 버전
- 오류 메시지 전문
- 실행한 명령어

