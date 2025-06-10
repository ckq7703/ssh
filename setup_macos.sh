#!/bin/bash

# Nhập thông tin từ người dùng
read -p "Nhập hostname Tunnel (ví dụ: hv1-node01.smartpro.edu.vn): " HOSTNAME
read -p "Nhập cổng SSH cục bộ (ví dụ: 2222): " PORT
read -p "Nhập tên user SSH (ví dụ: admin): " USERSSH

# Kiểm tra nếu cloudflared chưa cài
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared chưa có. Đang tải..."

  ARCH=$(uname -m)
  if [[ "$ARCH" == "x86_64" ]]; then
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz"
  elif [[ "$ARCH" == "arm64" ]]; then
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz"
  else
    echo "Kiến trúc CPU không được hỗ trợ: $ARCH"
    exit 1
  fi

  curl -LO "$URL"
  tar -xzf cloudflared-*.tgz
  rm cloudflared-*.tgz

  # Kiểm tra thư mục đích
  if [ ! -d "/usr/local/bin" ]; then
    echo "Tạo thư mục /usr/local/bin vì chưa tồn tại..."
    sudo mkdir -p /usr/local/bin
  fi

  sudo mv cloudflared /usr/local/bin/cloudflared
  sudo chmod +x /usr/local/bin/cloudflared

  echo "đã được cài đặt."
else
  echo "đã có sẵn."
fi

# Tạo PID file để quản lý tiến trình
PIDFILE="/tmp/cloudflared_ssh_$PORT.pid"

# Nếu tunnel cũ đang chạy, dừng lại trước
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    echo "Đang dừng tunnel cũ (PID $OLD_PID)..."
    kill "$OLD_PID"
    rm "$PIDFILE"
fi

# Khởi chạy cloudflared dưới nền
echo "Khởi chạy tunnel SSH Cloudflare..."
cloudflared access ssh --hostname "$HOSTNAME" --url "ssh://localhost:$PORT" &

# Lưu PID
echo $! > "$PIDFILE"
sleep 2

# Thực hiện kết nối SSH
echo "Kết nối SSH tới localhost:$PORT bằng user $USERSSH..."
sleep 1
ssh "$USERSSH"@localhost -p "$PORT"
