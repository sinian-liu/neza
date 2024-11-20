#!/bin/bash
# 云监控平台一键安装脚本

# 安装所需软件
echo "正在安装必要的软件包..."
apt update
apt install -y python3 python3-pip sqlite3 nginx git

# 创建项目目录
mkdir -p /opt/cloud-monitor
cd /opt/cloud-monitor

# 初始化后端代码
echo "初始化后端代码..."
cat > /opt/cloud-monitor/app.py << 'EOF'
from flask import Flask, jsonify, request
import sqlite3
import time

app = Flask(__name__)

# 数据库初始化
DATABASE = '/opt/cloud-monitor/data.db'

def init_db():
    with sqlite3.connect(DATABASE) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS servers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                location TEXT,
                virtualization TEXT,
                uptime INTEGER DEFAULT 0,
                traffic_in REAL DEFAULT 0,
                traffic_out REAL DEFAULT 0,
                load REAL DEFAULT 0,
                packet_loss REAL DEFAULT 0
            )
        ''')
        conn.commit()

@app.route('/api/servers', methods=['GET', 'POST'])
def manage_servers():
    if request.method == 'GET':
        with sqlite3.connect(DATABASE) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM servers')
            servers = cursor.fetchall()
        return jsonify(servers)

    if request.method == 'POST':
        data = request.json
        with sqlite3.connect(DATABASE) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO servers (name, location, virtualization, uptime, traffic_in, traffic_out, load, packet_loss)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (data['name'], data['location'], data['virtualization'], data['uptime'],
                  data['traffic_in'], data['traffic_out'], data['load'], data['packet_loss']))
            conn.commit()
        return jsonify({"status": "success"}), 201

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
EOF

# 初始化前端代码
echo "初始化前端代码..."
mkdir -p /opt/cloud-monitor/static
cat > /opt/cloud-monitor/static/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>云监控平台</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #333; color: #fff; margin: 0; padding: 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #444; padding: 10px; text-align: center; }
        th { background-color: #555; }
        tr:nth-child(even) { background-color: #444; }
        .container { width: 90%; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>云监控平台</h1>
        <table>
            <thead>
                <tr>
                    <th>名称</th>
                    <th>位置</th>
                    <th>虚拟化</th>
                    <th>运行时间（天）</th>
                    <th>流量进</th>
                    <th>流量出</th>
                    <th>负载</th>
                    <th>丢包率</th>
                </tr>
            </thead>
            <tbody id="server-table">
            </tbody>
        </table>
    </div>
    <script>
        async function fetchServers() {
            const response = await fetch('/api/servers');
            const servers = await response.json();
            const table = document.getElementById('server-table');
            table.innerHTML = '';
            servers.forEach(server => {
                const row = `<tr>
                    <td>${server[1]}</td>
                    <td>${server[2]}</td>
                    <td>${server[3]}</td>
                    <td>${server[4]}</td>
                    <td>${server[5].toFixed(2)} GB</td>
                    <td>${server[6].toFixed(2)} GB</td>
                    <td>${server[7]}</td>
                    <td>${server[8].toFixed(2)}%</td>
                </tr>`;
                table.innerHTML += row;
            });
        }

        setInterval(fetchServers, 5000); // 每5秒刷新一次
        fetchServers();
    </script>
</body>
</html>
EOF

# 安装 Python 包
echo "安装 Python 依赖..."
pip3 install flask

# 启动后端服务
echo "启动后端服务..."
nohup python3 /opt/cloud-monitor/app.py > /dev/null 2>&1 &

# 配置 Nginx
echo "配置 Nginx..."
cat > /etc/nginx/sites-available/cloud-monitor << 'EOF'
server {
    listen 8080;
    server_name _;
    root /opt/cloud-monitor/static;

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        index index.html;
    }
}
EOF

ln -s /etc/nginx/sites-available/cloud-monitor /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

echo "部署完成！访问 http://<你的服务器IP>:8080 查看监控平台。"
