#!/bin/bash

# 更新系统
apt update -y
apt upgrade -y

# 安装依赖
apt install -y curl git build-essential golang

# 创建项目目录
mkdir -p /root/nezha

# 克隆 GitHub 仓库
cd /root/nezha
git clone https://github.com/naiba/nezha.git .

# 切换到源码目录
cd /root/nezha

# 获取 Go 模块
go mod tidy

# 修改源码中的 GitHub 登录验证逻辑，确保使用本地用户名和密码
# 编辑源码，注释掉 GitHub OAuth 相关代码部分

# 编译 Nezha 面板服务
cd cmd/dashboard
go build -o nezha-server .

# 设置数据库和初始化（此处替换成你想要的用户名和密码）
echo "Creating database configuration..."
./nezha-server --init --username 346506686 --password 52169038

# 启动 Nezha 面板
./nezha-server

# 打印面板登录信息
echo "Nezha Panel has been installed and started!"
echo "Access it at: http://<your-server-ip>:8080"
echo "Use the following credentials to login:"
echo "Username: 346506686"
echo "Password: 52169038"

# 开放 8080 端口
ufw allow 8080
ufw reload
