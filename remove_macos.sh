#!/bin/bash

echo "📋 Danh sách các tunnel SSH đang chạy:"
echo "---------------------------------------"

# ✅ Liệt kê các PID file của cloudflared tunnel
FOUND=0
for pidfile in /tmp/cloudflared_ssh_*.pid; do
  if [ -f "$pidfile" ]; then
    port=$(basename "$pidfile" | sed 's/cloudflared_ssh_//' | sed 's/.pid//')
    pid=$(cat "$pidfile")
    if ps -p "$pid" > /dev/null 2>&1; then
      echo "🔹 PORT: $port | PID: $pid | Tình trạng: ĐANG CHẠY"
      FOUND=1
    else
      echo "⚠️ PORT: $port | PID: $pid | Tình trạng: KHÔNG CÒN CHẠY (xoá file PID)"
      rm "$pidfile"
    fi
  fi
done

if [ $FOUND -eq 0 ]; then
  echo "⚠️ Không có tunnel SSH nào đang chạy."
  exit 0
fi

echo "---------------------------------------"
read -p "👉 Nhập PORT bạn muốn dừng: " PORT
PIDFILE="/tmp/cloudflared_ssh_$PORT.pid"

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "🛑 Dừng tunnel (PID $PID)..."
    kill "$PID" && rm "$PIDFILE"
    echo "✅ Đã dừng tunnel trên port $PORT"
  else
    echo "⚠️ Tiến trình không còn tồn tại, xoá file PID."
    rm "$PIDFILE"
  fi
else
  echo "❌ Không tìm thấy tunnel nào đang chạy với port $PORT"
fi
