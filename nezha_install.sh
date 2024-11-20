#!/bin/bash

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装必要的软件包
echo "安装依赖..."
sudo apt install -y python3 python3-pip python3-venv sqlite3 nginx curl git

# 创建项目目录
echo "创建项目目录..."
mkdir -p /opt/vps-monitor
cd /opt/vps-monitor

# 克隆 GitHub 仓库
echo "克隆 GitHub 仓库..."
git clone https://github.com/your-username/vps-monitor.git .
cd /opt/vps-monitor

# 设置 Python 环境
echo "设置 Python 环境..."
python3 -m venv venv
source venv/bin/activate

# 安装 Python 依赖
echo "安装 Python 依赖..."
pip install -r requirements.txt

# 配置数据库
echo "设置数据库..."
sqlite3 vps_monitor.db <<EOF
CREATE TABLE IF NOT EXISTS vps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    ip TEXT NOT NULL,
    virtualization TEXT,
    uptime INTEGER,
    traffic TEXT,
    load TEXT,
    packet_loss TEXT
);
EOF

# 配置 Nginx
echo "配置 Nginx..."
sudo cp /opt/vps-monitor/nginx/vps-monitor.conf /etc/nginx/sites-available/vps-monitor
sudo ln -s /etc/nginx/sites-available/vps-monitor /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# 启动 Flask 应用
echo "启动 Flask 应用..."
python3 app.py &

# 配置自动启动服务
echo "配置自动启动服务..."
echo "[Unit]
Description=VPS Monitor

[Service]
ExecStart=/opt/vps-monitor/venv/bin/python3 /opt/vps-monitor/app.py
WorkingDirectory=/opt/vps-monitor
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/vps-monitor.service

sudo systemctl daemon-reload
sudo systemctl enable vps-monitor
sudo systemctl start vps-monitor

echo "VPS 监控系统安装完成！"
echo "访问地址：http://<你的服务器 IP>"
echo "使用默认管理员账号：admin/admin"
