#!/bin/bash

echo "Các dịch vụ SSH Tunnel đang có trên hệ thống:"
echo

# Tìm tất cả các file service có tên bắt đầu bằng "ssh_port"
AVAILABLE_SERVICES=$(ls /etc/systemd/system/ssh_port*.service 2>/dev/null)

if [ -z "$AVAILABLE_SERVICES" ]; then
    echo "Không tìm thấy dịch vụ nào bắt đầu bằng ssh_port."
    exit 1
fi

# Hiển thị danh sách dịch vụ
for SERVICE_FILE in $AVAILABLE_SERVICES; do
    SERVICE_NAME=$(basename "$SERVICE_FILE" .service)
    STATUS=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)
    echo "$SERVICE_NAME - Trạng thái: $STATUS"
done

echo
read -p "Nhập PORT của dịch vụ cần gỡ (ví dụ: 2222): " PORT

SERVICE_NAME=ssh_port$PORT

echo "Đang gỡ dịch vụ [$SERVICE_NAME]..."

if [ -f /etc/systemd/system/$SERVICE_NAME.service ]; then
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl disable $SERVICE_NAME
    sudo rm /etc/systemd/system/$SERVICE_NAME.service
    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    echo "Đã gỡ bỏ dịch vụ $SERVICE_NAME thành công."
else
    echo "Dịch vụ $SERVICE_NAME không tồn tại."
fi
