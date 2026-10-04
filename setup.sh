#!/usr/bin/env bash
#
# Bài 2 (Session 03) - Trang lỗi 404 tùy chỉnh cho Nginx
#   - Web root: /var/www/my-web/html/
#   - error_page 404 /404.html
#   - location = /404.html { internal; }  (chặn truy cập trực tiếp)
#
# Cách dùng (trên máy chủ Ubuntu, quyền root):
#   chmod +x setup.sh
#   sudo ./setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB="/var/www/my-web/html"

echo "==> Cài Nginx (nếu chưa có)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx curl

echo "==> Tạo web root và copy file"
mkdir -p "$WEB"
cp "$SCRIPT_DIR/www/my-web/html/index.html" "$WEB/index.html"
cp "$SCRIPT_DIR/www/my-web/html/404.html"   "$WEB/404.html"

echo "==> Phân quyền"
chown -R www-data:www-data /var/www/my-web
find /var/www/my-web -type d -exec chmod 755 {} \;
find /var/www/my-web -type f -exec chmod 644 {} \;

echo "==> Cấu hình Nginx: my-web.conf"
cp "$SCRIPT_DIR/nginx/my-web.conf" /etc/nginx/sites-available/my-web.conf
ln -sf /etc/nginx/sites-available/my-web.conf /etc/nginx/sites-enabled/my-web.conf
# Bỏ default site để tránh trùng cổng 80
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx 2>/dev/null || service nginx restart

echo "==> Kiểm tra"
echo "  [1] Truy cập đường dẫn KHÔNG tồn tại:"
curl -s -o /dev/null -w "      /invalid-path-demo -> HTTP %{http_code}\n" http://localhost/invalid-path-demo
echo "  [2] Truy cập TRỰC TIẾP /404.html (phải bị chặn = 404):"
curl -s -o /dev/null -w "      /404.html -> HTTP %{http_code}\n" http://localhost/404.html
echo "  [3] Nội dung trang lỗi trả về cho đường dẫn sai:"
curl -s http://localhost/invalid-path-demo | grep -i '<title>'

echo "==> Hoàn tất."
