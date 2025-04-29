#!/bin/bash

# Script thêm quy tắc audit và cấu hình proxy apt
SOURCE_FILE="/etc/apt/sources.list"
BACKUP_FILE="/etc/apt/sources.list.bk"
APT_PROXY_FILE="/etc/apt/apt.conf.d/95proxy"
# Backup trước khi sửa
cp "$SOURCE_FILE" "$BACKUP_FILE" || { echo "Backup sources.list thất bại!" >&2; exit 1; }
echo "==> Đã backup $SOURCE_FILE thành $BACKUP_FILE."

# Đổi http thành https cho các dòng deb
sed -i 's|^deb http://|deb https://|g' "$SOURCE_FILE"

echo "==> Đã cập nhật $SOURCE_FILE từ http thành https."

# Cấu hình proxy cho apt
echo "==> Thiết lập proxy cho APT..."
cat <<EOF > "$APT_PROXY_FILE"
Acquire::http::Proxy "http://10.38.221.91:6000";
Acquire::https::Proxy "http://10.38.221.91:6000";
EOF
echo "==> Đã ghi file proxy $APT_PROXY_FILE."

apt install auditd -y

# Đường dẫn file audit.rules
AUDIT_RULES_FILE="/etc/audit/rules.d/audit.rules"
BACKUPAD_FILE="/etc/audit/rules.d/audit-bk.rules"

# Backup nhanh gọn
cp "$AUDIT_RULES_FILE" "$BACKUPAD_FILE"

# Nội dung quy tắc audit cần thêm
RULE_ROOT='-a always,exit -F arch=b64 -S login -F euid=0 -k root_login_success'
RULE_ADMIN='-a always,exit -F arch=b64 -S login -F euid>=1000 -F euid!=0 -k admin_login_success'

# Thêm quy tắc nếu chưa có
grep -Fxq "$RULE_ROOT" "$AUDIT_RULES_FILE" || echo "$RULE_ROOT" >> "$AUDIT_RULES_FILE"
grep -Fxq "$RULE_ADMIN" "$AUDIT_RULES_FILE" || echo "$RULE_ADMIN" >> "$AUDIT_RULES_FILE"
systemctl restart auditd
echo "==> Đã thêm quy tắc audit."
