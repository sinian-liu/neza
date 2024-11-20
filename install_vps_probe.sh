#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
  echo "请使用 root 用户运行此脚本。"
  exit 1
fi

# 更新系统并安装依赖
echo "更新系统并安装依赖..."
apt update && apt upgrade -y
apt install -y curl git build-essential

# 检查并安装 Node.js (16.x)
echo "检查并安装 Node.js..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs

# 检查 Node.js 和 npm 是否安装成功
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
  echo "Node.js 或 npm 安装失败，请检查后重试。"
  exit 1
fi

# 下载 Uptime Kuma 源码
echo "下载 Uptime Kuma..."
git clone https://github.com/louislam/uptime-kuma.git /opt/uptime-kuma

# 进入安装目录
cd /opt/uptime-kuma || exit

# 安装依赖
echo "安装依赖，这可能需要一些时间..."
npm install --production

# 创建系统服务
echo "创建系统服务..."
cat <<EOF > /etc/systemd/system/uptime-kuma.service
[Unit]
Description=Uptime Kuma
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/uptime-kuma
ExecStart=/usr/bin/node server/server.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
echo "启用并启动 Uptime Kuma 服务..."
systemctl daemon-reload
systemctl enable uptime-kuma
systemctl start uptime-kuma

# 检查服务状态
echo "检查服务状态..."
systemctl status uptime-kuma --no-pager

# 显示安装完成信息
echo "Uptime Kuma 已成功安装并启动！"
echo "您可以通过 http://<你的服务器IP>:3001 访问 Uptime Kuma。"
