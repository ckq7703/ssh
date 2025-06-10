#!/bin/bash

# 📥 Nhập thông tin từ người dùng
read -p "Nhập hostname Cloudflare Tunnel (ví dụ: hv1-node01.smartpro.edu.vn): " HOSTNAME
read -p "Nhập cổng SSH cục bộ (ví dụ: 2222): " PORT
read -p "Nhập tên user SSH (ví dụ: admin): " USERSSH

# 📦 Kiểm tra kiến trúc CPU
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_URL="cloudflared-darwin-amd64.tgz"
elif [[ "$ARCH" == "arm64" ]]; then
    ARCH_URL="cloudflared-darwin-arm64.tgz"
else
    echo "❌ Không hỗ trợ kiến trúc $ARCH"
    exit 1
fi

# 📁 Tải và giải nén nếu cloudflared chưa có
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "⏬ Tải cloudflared tương thích với $ARCH..."
    curl -LO "https://github.com/cloudflare/cloudflared/releases/latest/download/$ARCH_URL"
    tar -xvzf $ARCH_URL
    chmod +x cloudflared
    sudo mv cloudflared /usr/local/bin/
    rm $ARCH_URL
    echo "✅ cloudflared đã được cài đặt."
else
    echo "✅ cloudflared đã sẵn sàng."
fi

# 📌 Tạo PID file để quản lý tiến trình
PIDFILE="/tmp/cloudflared_ssh_$PORT.pid"

# 🔄 Nếu tunnel cũ đang chạy, dừng lại trước
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    echo "⚠️ Đang dừng tunnel cũ (PID $OLD_PID)..."
    kill "$OLD_PID"
    rm "$PIDFILE"
fi

# 🚀 Khởi chạy cloudflared dưới nền
echo "🚀 Khởi chạy tunnel SSH Cloudflare..."
cloudflared access ssh --hostname "$HOSTNAME" --url "ssh://localhost:$PORT" &

# 💾 Lưu PID
echo $! > "$PIDFILE"
sleep 2

# 🔐 Thực hiện kết nối SSH
echo "🔐 Kết nối SSH tới localhost:$PORT bằng user $USERSSH..."
sleep 1
ssh "$USERSSH"@localhost -p "$PORT"
