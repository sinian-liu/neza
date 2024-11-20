#!/bin/bash

# 更新系统
echo "更新系统..."
sudo apt update -y
sudo apt upgrade -y

# 安装 Go 环境
echo "安装 Go 语言环境..."
sudo apt install -y golang-go

# 安装 MySQL（如果未安装）
echo "安装 MySQL 数据库..."
sudo apt install -y mysql-server

# 安装其他依赖
echo "安装必要依赖..."
sudo apt install -y git curl

# 获取 Nezha 面板代码
echo "获取 Nezha 面板代码..."
cd ~
git clone https://github.com/naiba/nezha.git
cd nezha

# 安装依赖
echo "安装项目依赖..."
go mod tidy

# 提示用户输入用户名和密码
read -p "请输入管理员用户名: " username
read -sp "请输入管理员密码: " password
echo

# 创建数据库和配置文件
echo "创建数据库配置文件..."
cat > config.json <<EOF
{
    "server": "0.0.0.0",
    "port": "8080",
    "database": {
        "type": "mysql",
        "host": "localhost",
        "port": "3306",
        "username": "root",
        "password": "",
        "dbname": "nezha"
    }
}
EOF

# 编译项目
echo "开始编译 Nezha 面板..."
go build -o nezha-server ./cmd/dashboard

# 启动 Nezha 面板
echo "启动 Nezha 面板..."
./nezha-server &

# 提示用户访问网址
echo "Nezha 面板已启动!"
echo "你可以通过以下地址访问面板："
echo "http://$(curl -s ifconfig.me):8080"

# 提示用户使用刚刚创建的用户名和密码登录
echo "使用以下凭证登录："
echo "用户名: $username"
echo "密码: $password"

echo "安装完成!"
