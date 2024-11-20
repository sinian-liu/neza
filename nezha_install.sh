#!/bin/bash

# 更新系统并安装依赖
echo "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y git golang mysql-server make

# 克隆哪吒面板的仓库
echo "Cloning Nezha Panel repository..."
git clone https://github.com/naiba/nezha.git
cd nezha

# 编译面板
echo "Building Nezha Panel..."
make

# 提示用户输入用户名和密码
echo "Please enter a username for the admin account:"
read -p "Username: " username
echo "Please enter a password for the admin account:"
read -sp "Password: " password
echo

# 配置数据库连接（可以选择 MySQL 或 SQLite）
echo "Setting up database and configuration..."
# 这里假设您使用的是 MySQL 数据库，您可以根据需要修改为 SQLite
mysql -u root -e "CREATE DATABASE nezha;"

# 修改 config.json 文件以设置用户名和密码
cat > config.json <<EOL
{
  "auth": {
    "method": "local",  # 使用本地认证方式
    "username": "$username",  # 用户名
    "password": "$password"  # 密码
  },
  "database": {
    "type": "mysql",
    "host": "localhost",
    "port": 3306,
    "username": "root",
    "password": "",
    "dbname": "nezha"
  }
}
EOL

# 启动 Nezha 面板
echo "Starting Nezha Panel..."
./nezha-server &

# 提示用户面板的网址
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Nezha Panel has been installed and started successfully!"
echo "You can access it at http://$IP_ADDRESS:8080"
echo "Use the username and password you just created to log in."
