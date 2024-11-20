#!/bin/bash

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装 Node.js 和 npm
echo "安装 Node.js 和 npm..."
sudo apt install -y nodejs npm

# 安装 PM2（用于运行 Node.js 应用）
echo "安装 PM2..."
sudo npm install -g pm2

# 创建后端文件夹
echo "创建后端文件夹..."
mkdir -p /opt/server-monitor/backend
cd /opt/server-monitor/backend

# 创建 server.js 后端文件
echo "创建 server.js 文件..."
cat << 'EOF' > server.js
const express = require('express');
const app = express();
const port = 8080;

// 模拟服务器数据
let servers = [
  {
    id: 1,
    name: "Server 1",
    location: "USA",
    virtualization: "KVM",
    uptime: 34, // 天数
    load: "0.35", // 负载
    traffic: "2.1T/4.5T", // 流量使用/总量
    packetLoss: "0.2%", // 丢包率
  },
  {
    id: 2,
    name: "Server 2",
    location: "Germany",
    virtualization: "OpenVZ",
    uptime: 12,
    load: "0.12",
    traffic: "1.0T/2.5T",
    packetLoss: "0.1%",
  },
];

// 允许跨域
app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  next();
});

// 返回服务器列表
app.get('/api/servers', (req, res) => {
  res.json(servers);
});

// 启动服务
app.listen(port, () => {
  console.log(`Server running at http://0.0.0.0:${port}/`);
});
EOF

# 启动后端服务
echo "启动后端服务..."
pm2 start server.js --name server-monitor-backend

# 创建前端文件夹
echo "创建前端文件夹..."
mkdir -p /opt/server-monitor/frontend
cd /opt/server-monitor/frontend

# 创建 index.html 文件
echo "创建 index.html 文件..."
cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>服务器监控</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f4f4f4; }
  </style>
</head>
<body>
  <h1>服务器监控面板</h1>
  <table>
    <thead>
      <tr>
        <th>名称</th>
        <th>位置</th>
        <th>虚拟化</th>
        <th>运行天数</th>
        <th>负载</th>
        <th>流量</th>
        <th>丢包率</th>
      </tr>
    </thead>
    <tbody id="server-table"></tbody>
  </table>

  <script>
    async function fetchServers() {
      const response = await fetch('http://localhost:8080/api/servers');
      const servers = await response.json();
      const tableBody = document.getElementById('server-table');
      tableBody.innerHTML = servers.map(server => `
        <tr>
          <td>${server.name}</td>
          <td>${server.location}</td>
          <td>${server.virtualization}</td>
          <td>${server.uptime} 天</td>
          <td>${server.load}</td>
          <td>${server.traffic}</td>
          <td>${server.packetLoss}</td>
        </tr>
      `).join('');
    }

    fetchServers();
  </script>
</body>
</html>
EOF

# 设置前端文件权限
echo "设置前端文件权限..."
sudo chmod -R 755 /opt/server-monitor/frontend

# 输出完成信息
echo "部署完成！"
echo "1. 后端服务已在 8080 端口启动。"
echo "2. 前端文件位于 /opt/server-monitor/frontend/index.html，您可以通过 Web 服务器或直接浏览器访问。"

# 结束
exit 0
