#!/bin/bash

echo "开始安装监控系统..."

# 更新系统
sudo apt update -y && sudo apt upgrade -y

# 安装必要软件
echo "安装依赖软件..."
sudo apt install -y python3 python3-pip sqlite3 curl unzip

# 安装 Netdata（用于监控性能）
echo "安装 Netdata..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

# 配置 Python 环境
echo "安装 Python 依赖..."
pip3 install flask flask-sqlalchemy requests

# 创建监控文件夹
mkdir -p /opt/server_monitor
cd /opt/server_monitor

# 下载前端和后端代码
echo "下载监控系统代码..."
cat <<EOF > app.py
from flask import Flask, render_template, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os
import subprocess
import time

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///monitor.db'
db = SQLAlchemy(app)

# 数据库模型
class Server(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    ip = db.Column(db.String(50), nullable=False)
    country = db.Column(db.String(50), nullable=False)
    virtualization = db.Column(db.String(50), nullable=False)
    uptime = db.Column(db.Integer, default=0)  # 运行时间（天）
    traffic_in = db.Column(db.Float, default=0.0)
    traffic_out = db.Column(db.Float, default=0.0)
    load = db.Column(db.Float, default=0.0)
    packet_loss = db.Column(db.Float, default=0.0)

# 创建数据库
with app.app_context():
    db.create_all()

@app.route('/')
def index():
    servers = Server.query.all()
    return render_template('index.html', servers=servers)

@app.route('/add_server', methods=['POST'])
def add_server():
    data = request.get_json()
    new_server = Server(
        name=data['name'],
        ip=data['ip'],
        country=data['country'],
        virtualization=data['virtualization'],
        uptime=data.get('uptime', 0)
    )
    db.session.add(new_server)
    db.session.commit()
    return jsonify({'message': 'Server added successfully!'})

@app.route('/update_server', methods=['POST'])
def update_server():
    data = request.get_json()
    server = Server.query.get(data['id'])
    if server:
        server.traffic_in = data['traffic_in']
        server.traffic_out = data['traffic_out']
        server.load = data['load']
        server.packet_loss = data['packet_loss']
        db.session.commit()
        return jsonify({'message': 'Server updated successfully!'})
    return jsonify({'error': 'Server not found!'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

cat <<EOF > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Monitor</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-4">
    <h1>服务器监控面板</h1>
    <table class="table table-striped">
        <thead>
            <tr>
                <th>名称</th>
                <th>IP 地址</th>
                <th>国家</th>
                <th>虚拟化</th>
                <th>运行天数</th>
                <th>流量 (入/出)</th>
                <th>负载</th>
                <th>丢包率</th>
            </tr>
        </thead>
        <tbody>
            {% for server in servers %}
            <tr>
                <td>{{ server.name }}</td>
                <td>{{ server.ip }}</td>
                <td>{{ server.country }}</td>
                <td>{{ server.virtualization }}</td>
                <td>{{ server.uptime }}</td>
                <td>{{ server.traffic_in }} / {{ server.traffic_out }}</td>
                <td>{{ server.load }}</td>
                <td>{{ server.packet_loss }}%</td>
            </tr>
            {% endfor %}
        </tbody>
    </table>
</div>
</body>
</html>
EOF

# 启动服务
echo "启动监控系统..."
python3 app.py &
echo "监控系统已启动，请访问 http://<服务器IP>:8080 查看。"
