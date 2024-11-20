#!/bin/bash

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装必要依赖
echo "安装依赖..."
sudo apt install -y curl git build-essential

# 安装 Node.js (LTS 版本)
echo "安装 Node.js..."
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# 克隆 Uptime Kuma 仓库
echo "克隆 Uptime Kuma 仓库..."
git clone https://github.com/louislam/uptime-kuma.git
cd uptime-kuma

# 安装 NPM 依赖
echo "安装 NPM 依赖..."
npm install --production

# 启动 Uptime Kuma
echo "启动 Uptime Kuma..."
nohup node server/server.js > uptime-kuma.log 2>&1 &

# 提示访问地址
echo "Uptime Kuma 已启动！访问地址： http://<你的服务器IP>:3001"
echo "登录后可以在右上角选择简体中文作为界面语言。"

# 提示设置 pm2 开机自启
echo "你可以使用 pm2 确保 Uptime Kuma 在服务器重启后自动启动。"
echo "安装 pm2 并设置自启..."
sudo npm install -g pm2
pm2 start server/server.js --name uptime-kuma
pm2 startup
pm2 save

echo "安装完成！Uptime Kuma 会在服务器重启后自动启动。"
