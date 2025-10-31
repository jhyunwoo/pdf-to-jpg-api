"""
Gunicorn 설정 파일 (Production 환경용)
"""
import os
import multiprocessing

# 서버 소켓
bind = f"0.0.0.0:{os.getenv('PORT', '3000')}"
backlog = 2048

# 워커 프로세스
workers = int(os.getenv('GUNICORN_WORKERS', multiprocessing.cpu_count() * 2 + 1))
worker_class = 'sync'
worker_connections = 1000
timeout = 300  # PDF 변환 및 업로드는 시간이 걸릴 수 있으므로 넉넉하게 설정
keepalive = 2

# 로깅
accesslog = 'logs/access.log'
errorlog = 'logs/error.log'
loglevel = 'info'
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# 프로세스 이름
proc_name = 'pdf-to-jpg-api'

# 데몬 모드 (백그라운드 실행)
daemon = False

# PID 파일
pidfile = 'logs/gunicorn.pid'

# 재시작 설정
max_requests = 1000
max_requests_jitter = 50

# 보안
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

def on_starting(server):
    """서버 시작 시 실행"""
    print("=" * 50)
    print("PDF to JPG Converter API - Production")
    print("=" * 50)
    print(f"Workers: {workers}")
    print(f"Bind: {bind}")
    print(f"Timeout: {timeout}s")
    print("=" * 50)

def on_reload(server):
    """재시작 시 실행"""
    print("Server reloading...")

def worker_exit(server, worker):
    """워커 종료 시 실행"""
    print(f"Worker {worker.pid} exited")

