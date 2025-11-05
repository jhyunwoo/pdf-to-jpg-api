#!/bin/bash

# Cloudflare Tunnel 시작 스크립트
# systemctl이 없는 환경용

TUNNEL_NAME="pdf-to-jpg-api"
LOG_FILE="/tmp/cloudflared.log"
PID_FILE="/tmp/cloudflared.pid"

case "$1" in
    start)
        echo "Cloudflare Tunnel을 시작합니다..."
        
        # 이미 실행 중인지 확인
        if [ -f "$PID_FILE" ]; then
            OLD_PID=$(cat "$PID_FILE")
            if ps -p "$OLD_PID" > /dev/null 2>&1; then
                echo "Tunnel이 이미 실행 중입니다 (PID: $OLD_PID)"
                exit 1
            fi
        fi
        
        # 백그라운드로 실행
        nohup cloudflared tunnel run "$TUNNEL_NAME" > "$LOG_FILE" 2>&1 &
        
        # PID 저장
        echo $! > "$PID_FILE"
        
        echo "✓ Tunnel 시작됨 (PID: $(cat $PID_FILE))"
        echo "로그: tail -f $LOG_FILE"
        ;;
        
    stop)
        echo "Cloudflare Tunnel을 중지합니다..."
        
        if [ ! -f "$PID_FILE" ]; then
            echo "PID 파일을 찾을 수 없습니다."
            # 그래도 프로세스 찾아서 종료 시도
            pkill -f "cloudflared tunnel run"
            exit 0
        fi
        
        PID=$(cat "$PID_FILE")
        
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID"
            sleep 2
            
            # 강제 종료
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID"
            fi
            
            rm -f "$PID_FILE"
            echo "✓ Tunnel 중지됨"
        else
            echo "Tunnel이 실행 중이 아닙니다."
            rm -f "$PID_FILE"
        fi
        ;;
        
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
        
    status)
        if [ ! -f "$PID_FILE" ]; then
            echo "✗ Tunnel이 실행 중이 아닙니다."
            exit 1
        fi
        
        PID=$(cat "$PID_FILE")
        
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✓ Tunnel이 실행 중입니다 (PID: $PID)"
            echo ""
            echo "프로세스 정보:"
            ps -p "$PID" -o pid,cmd,etime
            echo ""
            echo "최근 로그 (5줄):"
            tail -5 "$LOG_FILE"
        else
            echo "✗ PID 파일은 존재하지만 프로세스가 실행 중이 아닙니다."
            rm -f "$PID_FILE"
            exit 1
        fi
        ;;
        
    logs)
        if [ ! -f "$LOG_FILE" ]; then
            echo "로그 파일을 찾을 수 없습니다."
            exit 1
        fi
        
        if [ "$2" = "-f" ] || [ "$2" = "--follow" ]; then
            tail -f "$LOG_FILE"
        else
            tail -50 "$LOG_FILE"
        fi
        ;;
        
    *)
        echo "사용법: $0 {start|stop|restart|status|logs [-f]}"
        echo ""
        echo "명령어:"
        echo "  start    - Tunnel 시작"
        echo "  stop     - Tunnel 중지"
        echo "  restart  - Tunnel 재시작"
        echo "  status   - Tunnel 상태 확인"
        echo "  logs     - 로그 보기 (logs -f: 실시간)"
        exit 1
        ;;
esac

exit 0

