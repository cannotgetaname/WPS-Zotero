#!/bin/bash
# WPS-Zotero Proxy 手动启动脚本 (Linux)
# 当 WPS 无法自动启动代理时使用此脚本
#
# 使用方法：
#   启动:  ./start_proxy.sh
#   停止:  ./start_proxy.sh kill
#
# 也可以设置开机自启：
#   cp start_proxy.sh ~/.config/autostart/wps-zotero-proxy.sh
#   或添加到 crontab: @reboot /path/to/start_proxy.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROXY="$SCRIPT_DIR/proxy.py"
PIDFILE="/tmp/wps-zotero-proxy.pid"
LOGFILE="$HOME/.wps-zotero-proxy.log"

case "${1:-start}" in
    start)
        # 检查是否已在运行
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            echo "代理已在运行 (PID: $(cat "$PIDFILE"))"
            exit 0
        fi

        # 先杀掉旧实例
        python3 "$PROXY" kill 2>/dev/null || true
        sleep 0.5

        # 后台启动
        nohup python3 "$PROXY" > /dev/null 2>&1 &
        PID=$!
        echo $PID > "$PIDFILE"
        sleep 1

        if kill -0 "$PID" 2>/dev/null; then
            echo "WPS-Zotero 代理已启动 (PID: $PID)"
            echo "日志文件: $LOGFILE"
            echo "注意：请确保 Zotero 已运行"
        else
            echo "启动失败！请检查日志: $LOGFILE"
            rm -f "$PIDFILE"
            exit 1
        fi
        ;;
    kill|stop)
        python3 "$PROXY" kill 2>/dev/null || true
        rm -f "$PIDFILE"
        echo "代理已停止"
        ;;
    status)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            echo "代理运行中 (PID: $(cat "$PIDFILE"))"
            # 检查 Zotero 是否在运行
            if python3 -c "import socket; s=socket.socket(); s.settimeout(0.5); s.connect(('127.0.0.1',23119)); s.close(); print('Zotero 可达')" 2>/dev/null; then
                echo "Zotero 可达 : OK"
            else
                echo "Zotero 可达 : 无法连接 (Zotero 可能未启动)"
            fi
        else
            echo "代理未运行"
        fi
        ;;
    *)
        echo "用法: $0 {start|stop|kill|status}"
        exit 1
        ;;
esac
