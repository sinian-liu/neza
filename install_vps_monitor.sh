#!/bin/bash

# 确保脚本在 root 用户下运行
if [[ $EUID -ne 0 ]]; then
    echo "本脚本需要以 root 用户运行" 
    exit 1
fi

# 安装依赖
echo "安装基础依赖..."
apt update && apt upgrade -y
apt install -y git python3 python3-pip python3-venv nginx curl

# 克隆 GitHub 仓库（公开仓库）
echo "克隆 GitHub 仓库..."
git clone https://github.com/YOUR_GITHUB_USERNAME/vps-monitor.git /opt/vps-monitor
cd /opt/vps-monitor

# 设置 Python 虚拟环境
echo "创建并激活 Python 虚拟环境..."
python3 -m venv venv
source venv/bin/activate

# 安装 Python 依赖
echo "安装 Python 依赖..."
cat <<EOL > requirements.txt
Flask==2.1.1
requests==2.26.0
gunicorn==20.1.0
EOL
pip install -r requirements.txt

# 配置 Nginx
echo "配置 Nginx..."
cat <<EOL > /etc/nginx/sites-available/vps-monitor
server {
    listen 80;
    server_name your_domain_or_ip;

    location / {
        proxy_pass http://127.0.0.1:8080;  # 假设应用运行在 8080 端口
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# 创建符号链接
ln -s /etc/nginx/sites-available/vps-monitor /etc/nginx/sites-enabled/

# 重启 Nginx
echo "重启 Nginx 服务..."
systemctl restart nginx

# 配置 Systemd 服务
echo "配置 Systemd 服务..."
cat <<EOL > /etc/systemd/system/vps-monitor.service
[Unit]
Description=VPS Monitor Application
After=network.target

[Service]
User=www-data
WorkingDirectory=/opt/vps-monitor
ExecStart=/opt/vps-monitor/venv/bin/gunicorn -b 0.0.0.0:8080 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# 启动服务
echo "启动 VPS Monitor 服务..."
systemctl enable vps-monitor
systemctl start vps-monitor

# 输出成功信息
echo "安装完成！"
echo "访问您的 Web 界面查看监控信息： http://your_domain_or_ip"
