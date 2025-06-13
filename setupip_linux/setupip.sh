#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script này với quyền sudo hoặc root."
  exit 1
fi

# --- HỎI NGƯỜI DÙNG CÓ MUỐN TẠO USER MỚI KHÔNG ---
read -p "Bạn có muốn tạo user mới không? (yes/no): " CREATE_USER
if [[ "$CREATE_USER" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
  read -p "Nhập tên user muốn tạo (ví dụ: devuser): " NEWUSER

  if id "$NEWUSER" &>/dev/null; then
    echo "User '$NEWUSER' đã tồn tại."
  else
    echo "Đang tạo user '$NEWUSER'..."
    useradd -m -s /bin/bash "$NEWUSER"
    echo "User '$NEWUSER' đã được tạo."
    passwd "$NEWUSER"
  fi
else
  echo "Bỏ qua bước tạo user mới."
fi

# --- HỎI NGƯỜI DÙNG CÓ MUỐN ĐỔI HOSTNAME KHÔNG ---
read -p "Bạn có muốn đổi hostname máy chủ không? (yes/no): " CHANGE_HOSTNAME
if [[ "$CHANGE_HOSTNAME" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
  read -p "Nhập hostname máy chủ muốn đặt (ví dụ: hv1-node01): " NEWHOSTNAME
  echo "Đang đặt hostname thành '$NEWHOSTNAME'..."
  hostnamectl set-hostname "$NEWHOSTNAME"
  echo "Hostname đã được đổi thành $(hostname)."
else
  echo "Bỏ qua bước đổi hostname."
fi

# Lấy danh sách interface mạng
echo "Danh sách interface mạng:"
ip link | grep -E '^[0-9]+: (eth|en)' | awk '{print $2}' | sed 's/://'
echo "Nhập tên interface mạng (ví dụ: eth0, ens33):"
read interface

# Kiểm tra interface hợp lệ
if ! ip link show "$interface" >/dev/null 2>&1; then
  echo "Interface $interface không hợp lệ."
  exit 1
fi

# Nhập số cuối của địa chỉ IP từ người dùng
echo "Nhập số cuối của địa chỉ IP (ví dụ: 100 để tạo 192.168.1.100):"
read ip_last_octet

# Kiểm tra số cuối hợp lệ (1-254)
if ! echo "$ip_last_octet" | grep -qE '^[1-9][0-9]{0,2}$|^254$' || [ "$ip_last_octet" -lt 1 ] || [ "$ip_last_octet" -gt 254 ]; then
  echo "Số cuối của IP không hợp lệ (phải từ 1 đến 254)."
  exit 1
fi

# Cố định các giá trị
ip_addr="192.168.1.$ip_last_octet"
subnet="24"
gateway="192.168.1.1"
dns="8.8.8.8,8.8.4.4"

# Cấu hình Netplan
echo "Đang cấu hình Netplan cho $interface..."
netplan_file="/etc/netplan/01-netcfg.yaml"
cat > "$netplan_file" << EOF
network:
  version: 2
  ethernets:
    $interface:
      addresses:
        - $ip_addr/$subnet
      gateway4: $gateway
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF
if [ $? -ne 0 ]; then
  echo "Lỗi: Không thể tạo file Netplan."
  exit 1
fi

# Áp dụng cấu hình Netplan
netplan apply
if [ $? -ne 0 ]; then
  echo "Lỗi: Không thể áp dụng cấu hình Netplan."
  exit 1
fi

# Kiểm tra cấu hình
echo "Cấu hình IP hiện tại:"
ip addr show "$interface"

echo "Cấu hình IP tĩnh hoàn tất. Cấu hình sẽ được lưu vĩnh viễn sau khi reboot."

# Cài đặt Docker nếu chưa có
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker chưa có. Đang cài đặt docker.io..."
  apt update
  apt install -y docker.io
  systemctl enable --now docker
else
  echo "Docker đã được cài đặt."
fi

# Chạy container Cloudflare Tunnel
echo "Khởi chạy container cloudflared..."
docker rm -f smartprossh 2>/dev/null

docker run -d --name smartprossh --restart=always \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run \
  --token eyJhIjoiYjY3OTYwMGZmY2ZmZGQ2N2EwODRlZTczNjE5Y2FlZGUiLCJ0IjoiNmUwYmQyMmYtOTQ5ZS00YjQ4LTg5ZjctNTA2NzRkMDhhZjU4IiwicyI6Ik16VXhOalJqWkRjdFpETTRNQzAwT1RneExXRm1aV0l0WW1Wa1pHSXdObUUzTldSbSJ9

echo "Container smartprossh đã được khởi chạy."