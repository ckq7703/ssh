#!/bin/bash

# Kiểm tra cloudflared đã được cài chưa
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "Cloudflared chưa được cài. Đang tải và cài đặt..."
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
    sudo mv cloudflared /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    echo "Cloudflared đã được cài đặt."
else
    echo "Cloudflared đã có sẵn."
fi

echo

#Nhập hostname và port từ người dùng
read -p "Nhập hostname (ví dụ: hv1-node02.smartpro.edu.vn): " HOSTNAME
read -p "Nhập port SSH cục bộ (ví dụ: 2222): " PORT

#Xử lý tên dịch vụ dựa vào port
SERVICE_NAME=ssh_port$PORT
USER_NAME=$(whoami)

echo "Đang tạo dịch vụ SSH Tunnel với:"
echo "HOSTNAME: $HOSTNAME"
echo "PORT: $PORT"
echo "SERVICE_NAME: $SERVICE_NAME"
echo

# Tạo file systemd service
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null
[Unit]
Description=SSH Tunnel on Port $PORT
After=network.target

[Service]
ExecStart=/usr/local/bin/cloudflared access ssh --hostname $HOSTNAME --url ssh://localhost:$PORT
Restart=always
RestartSec=5
User=$USER_NAME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

#Khởi động và kích hoạt dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo
echo "Dịch vụ [$SERVICE_NAME] đã được tạo và khởi chạy!"
echo "Xem trạng thái bằng: sudo systemctl status $SERVICE_NAME"
echo

read -p "Nhập tên người dùng để SSH (ví dụ: admin): " SSH_USER
# Chờ dịch vụ khởi động vài giây (tùy mạng)
echo "..."
sleep 3

# Thực hiện kết nối SSH
echo "Mở kết nối SSH đến localhost:$PORT với user: $SSH_USER"
ssh "$SSH_USER"@localhost -p "$PORT"