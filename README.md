# Bài 2 (Session 03): Cấu hình trang lỗi tùy chỉnh (Custom Error Page 404)

## 1. Mục tiêu

- Cấu hình Nginx phục vụ **trang lỗi 404 tự thiết kế** thay cho trang mặc định.
- Bảo mật tệp `404.html` bằng chỉ thị `internal` để **chặn truy cập trực tiếp** từ Internet.

## 2. Cấu trúc thư mục

```
Ex02/
├── README.md
├── setup.sh                          # Script deploy + kiểm tra
├── nginx/
│   └── my-web.conf                   # Server Block + error_page 404
└── www/
    └── my-web/
        └── html/
            ├── index.html            # -> /var/www/my-web/html/
            └── 404.html              # -> /var/www/my-web/html/
```

## 3. Ràng buộc

- `404.html` tùy biến lưu tại `/var/www/my-web/html/`.
- Server Block dùng `error_page 404 /404.html;`.
- `location = /404.html { root ...; internal; }` để chặn truy cập trực tiếp `http://<IP>/404.html`.

## 4. Thực hiện

### 4.1. Tạo web root và 404.html

```bash
sudo mkdir -p /var/www/my-web/html
sudo cp www/my-web/html/index.html /var/www/my-web/html/
sudo cp www/my-web/html/404.html   /var/www/my-web/html/
sudo chown -R www-data:www-data /var/www/my-web
sudo find /var/www/my-web -type d -exec chmod 755 {} \;
sudo find /var/www/my-web -type f -exec chmod 644 {} \;
```

### 4.2. Cấu hình Server Block

File `/etc/nginx/sites-available/my-web.conf` (nội dung: `nginx/my-web.conf`):

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /var/www/my-web/html;
    index index.html;

    error_page 404 /404.html;

    location = /404.html {
        root /var/www/my-web/html;
        internal;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
```

```bash
sudo ln -sf /etc/nginx/sites-available/my-web.conf /etc/nginx/sites-enabled/my-web.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 4.3. Chạy nhanh bằng script

```bash
chmod +x setup.sh
sudo ./setup.sh
```

## 5. Kiểm tra

**Truy cập đường dẫn không tồn tại:**

```bash
curl -I http://<IP_ADDRESS>/invalid-path-demo
```

**Truy cập trực tiếp tệp lỗi (phải bị chặn):**

```bash
curl -I http://<IP_ADDRESS>/404.html
```

Kết quả thực tế trên máy chủ (Ubuntu):

```
$ curl -s -o /dev/null -w "/invalid-path-demo -> HTTP %{http_code}\n" http://localhost/invalid-path-demo
/invalid-path-demo -> HTTP 404

$ curl -s -o /dev/null -w "/404.html -> HTTP %{http_code}\n" http://localhost/404.html
/404.html -> HTTP 404

$ curl -s http://localhost/invalid-path-demo | grep -i '<title>'
    <title>404 - Không tìm thấy trang</title>
```

- Đường dẫn sai → **404** kèm **nội dung HTML tùy biến**.
- Truy cập trực tiếp `/404.html` → **404** (bị `internal` chặn).

## 6. Kết luận

- Nginx phục vụ trang lỗi 404 tùy chỉnh cho mọi đường dẫn không tồn tại.
- Tệp `404.html` được bảo vệ bằng `internal`, không thể truy cập trực tiếp từ Internet.
