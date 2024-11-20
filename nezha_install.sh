#!/bin/bash

# 1. 更新并安装必要的依赖
echo "更新系统和安装必要的依赖..."
apt-get update -y
apt-get upgrade -y
apt-get install -y golang-go git make build-essential

# 2. 设置 Go 环境变量
echo "设置 Go 环境变量..."
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin" >> ~/.bashrc
source ~/.bashrc

# 3. 下载 Nezha 面板源码
echo "克隆 Nezha 面板源码..."
cd /root
git clone https://github.com/naiba/nezha.git
cd nezha

# 4. 安装并配置 Go 依赖
echo "安装并配置 Go 依赖..."
go mod tidy

# 5. 编译 Nezha 面板服务
echo "编译 Nezha 面板服务..."
cd cmd/dashboard
go build -o nezha-server .

# 6. 配置 Nezha 面板
echo "创建数据库和配置文件..."
echo "请输入管理员用户名:"
read admin_user
echo "请输入管理员密码:"
read admin_password

# 初始化 Nezha 面板
./nezha-server -admin-user="$admin_user" -admin-password="$admin_password"

# 7. 设置文件权限
echo "设置文件权限..."
chmod +x ./nezha-server

# 8. 启动 Nezha 面板服务
echo "启动 Nezha 面板..."
./nezha-server

# 9. 防火墙设置
echo "设置防火墙，允许访问 8080 端口..."
ufw allow 8080
ufw reload

# 10. 提示用户访问面板
echo "Nezha 面板已成功启动！"
echo "你可以通过以下地址访问 Nezha 面板："
echo "http://$(hostname -I | awk '{print $1}'):8080"
echo "使用以下凭证登录："
echo "用户名: $admin_user"
echo "密码: $admin_password"
