#!/bin/bash

# 更新系统
echo "更新系统..."
apt update -y && apt upgrade -y

# 安装 Python 和必要的依赖
echo "安装 Python 和依赖..."
apt install -y python3 python3-pip python3-venv nginx git

# 克隆 GitHub 仓库到本地
echo "克隆仓库..."
git clone https://github.com/YOUR_GITHUB_USERNAME/vps-monitor.git
cd vps-monitor

# 创建并激活虚拟环境
echo "创建并激活 Python 虚拟环境..."
python3 -m venv venv
source venv/bin/activate

# 安装 Python 依赖
echo "安装 Python 依赖..."
pip install -r requirements.txt

# 配置 Nginx
echo "配置 Nginx..."
cp nginx/vps-monitor.conf /etc/nginx/sites-available/vps-monitor
ln -s /etc/nginx/sites-available/vps-monitor /etc/nginx/sites-enabled/

# 重启 Nginx 服务
echo "重启 Nginx 服务..."
systemctl restart nginx

# 创建并启动 Systemd 服务
echo "配置 Systemd 服务..."
cp vps-monitor.service /etc/systemd/system/
systemctl enable vps-monitor
systemctl start vps-monitor

echo "安装完成！访问您的 Web 界面查看监控信息。"
