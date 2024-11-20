#!/bin/bash

echo "=========================="
echo "  VPS 多功能监控工具安装"
echo "=========================="

# 更新系统
echo "更新系统..."
apt update && apt upgrade -y

# 安装基础工具
echo "安装基础工具..."
apt install -y python3 python3-pip git curl wget unzip net-tools

# 安装 Flask
echo "安装 Flask 和依赖..."
pip3 install flask prometheus_client requests

# 安装 Prometheus
echo "安装 Prometheus..."
PROMETHEUS_VERSION="2.47.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 /opt/prometheus
rm prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cat <<EOF >/opt/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'vps_monitor'
    static_configs:
      - targets: ['localhost:9000']
EOF

# 安装 Grafana
echo "安装 Grafana..."
wget https://dl.grafana.com/oss/release/grafana-10.2.0.linux-amd64.tar.gz
tar -xzf grafana-10.2.0.linux-amd64.tar.gz
mv grafana-10.2.0 /opt/grafana
rm grafana-10.2.0.linux-amd64.tar.gz

# 设置 Flask 应用
echo "配置 Flask 应用..."
mkdir -p /opt/vps_monitor
cat <<'EOF' >/opt/vps_monitor/app.py
from flask import Flask, jsonify, request
import time
import platform
from prometheus_client import start_http_server, Gauge

app = Flask(__name__)

# 初始化监控指标
vps_uptime = Gauge("vps_uptime", "VPS 运行时间（天）", ["name"])
vps_load = Gauge("vps_load", "VPS 系统负载", ["name"])
vps_packet_loss = Gauge("vps_packet_loss", "VPS 丢包率", ["name"])
vps_traffic = Gauge("vps_traffic", "VPS 流量（MB）", ["name"])
vps_virtualization = Gauge("vps_virtualization", "虚拟化类型", ["name"])
vps_country = Gauge("vps_country", "VPS 国家", ["name"])

# 模拟数据（在实际部署时需要采集真实数据）
@app.route("/add_vps", methods=["POST"])
def add_vps():
    data = request.json
    name = data.get("name", "Unnamed VPS")
    uptime = data.get("uptime", 0)
    load = data.get("load", 0)
    packet_loss = data.get("packet_loss", 0)
    traffic = data.get("traffic", 0)
    virtualization = data.get("virtualization", "Unknown")
    country = data.get("country", "Unknown")

    vps_uptime.labels(name=name).set(uptime)
    vps_load.labels(name=name).set(load)
    vps_packet_loss.labels(name=name).set(packet_loss)
    vps_traffic.labels(name=name).set(traffic)
    vps_virtualization.labels(name=name).set(virtualization)
    vps_country.labels(name=name).set(country)

    return jsonify({"status": "success", "message": f"VPS {name} added/updated."})

@app.route("/")
def index():
    return jsonify({"message": "VPS Monitor API is running!"})

if __name__ == "__main__":
    start_http_server(9000)
    app.run(host="0.0.0.0", port=5000)
EOF

# 配置 Prometheus 服务
echo "配置 Prometheus 服务..."
cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
User=root
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 配置 Grafana 服务
echo "配置 Grafana 服务..."
cat <<EOF >/etc/systemd/system/grafana.service
[Unit]
Description=Grafana
After=network.target

[Service]
User=root
ExecStart=/opt/grafana/bin/grafana-server
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 配置 Flask 服务
echo "配置 Flask 服务..."
cat <<EOF >/etc/systemd/system/vps_monitor.service
[Unit]
Description=VPS Monitor Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/opt/vps_monitor
ExecStart=/usr/bin/python3 /opt/vps_monitor/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启动所有服务
echo "启动所有服务..."
systemctl daemon-reload
systemctl enable prometheus grafana vps_monitor
systemctl start prometheus grafana vps_monitor

# 输出完成信息
echo "=========================="
echo "  VPS 多功能监控工具安装完成"
echo "=========================="
echo "访问 Grafana 界面：http://<你的IP>:3000"
echo "默认用户名: admin, 密码: admin"
echo "可以通过 POST 请求向 http://<你的IP>:5000/add_vps 添加 VPS 数据"
