#!/bin/bash

# 1. 更新系统
echo "更新系统..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. 安装依赖
echo "安装依赖..."
sudo apt-get install -y python3-pip python3-dev build-essential nginx git

# 3. 安装 Flask 和 Gunicorn
echo "安装 Flask 和 Gunicorn..."
pip3 install flask gunicorn

# 4. 克隆项目到 /opt 目录
echo "克隆项目..."
cd /opt
git clone https://github.com/YOUR_GITHUB_USERNAME/vps-monitor.git

# 5. 配置 Nginx
echo "配置 Nginx..."
sudo cp /opt/vps-monitor/nginx/vps-monitor.conf /etc/nginx/sites-available/vps-monitor
sudo ln -s /etc/nginx/sites-available/vps-monitor /etc/nginx/sites-enabled/

# 配置 Nginx 以代理 Flask 应用
echo "配置 Nginx 代理设置..."
sudo bash -c 'cat > /etc/nginx/sites-available/vps-monitor <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;  # Flask 默认运行端口
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOF'

# 6. 检查防火墙设置并允许 HTTP 流量
echo "检查并配置防火墙..."
sudo ufw allow 'Nginx Full'
sudo ufw enable

# 7. 启动 Flask 应用（使用 Gunicorn）
echo "启动 Flask 应用..."
cd /opt/vps-monitor
gunicorn -w 4 -b 127.0.0.1:5000 app:app &  # 使用 Gunicorn 启动 Flask 应用

# 8. 重启 Nginx 以加载新配置
echo "重启 Nginx..."
sudo systemctl restart nginx

# 9. 确保 Nginx 和 Flask 启动成功
echo "检查 Nginx 状态..."
sudo systemctl status nginx

# 10. 提示完成
echo "安装完成！请访问您的服务器 IP 来查看监控信息。"
