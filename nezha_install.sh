#!/bin/bash

# 更新系统
echo "正在更新系统..."
sudo apt update -y && sudo apt upgrade -y

# 安装基本依赖
echo "正在安装必需的依赖..."
sudo apt install -y git curl build-essential

# 安装 Node.js（如果未安装）
echo "正在安装 Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 下载 ServerStatus 源代码
echo "正在下载 ServerStatus..."
cd /opt
sudo git clone https://github.com/mikferris/ServerStatus.git
cd ServerStatus

# 安装 Node.js 依赖
echo "正在安装依赖..."
sudo npm install

# 设置配置文件
echo "正在设置配置文件..."
cat <<EOL > config.json
{
  "port": 3000,
  "hostname": "localhost",
  "update_interval": 2000,
  "monitoring_interval": 10000
}
EOL

# 启动 ServerStatus
echo "正在启动 ServerStatus..."
sudo npm start &

# 安装 PM2 以便自动启动
echo "正在安装 PM2..."
sudo npm install -g pm2
pm2 start npm --name "serverstatus" -- start
pm2 startup
pm2 save

echo "安装完成！访问：http://<你的VPSIP>:3000 查看 ServerStatus"
