# MuSheet 后端启动教程

本文档详细介绍如何启动和运行 MuSheet 后端服务器。

## 目录

1. [环境要求](#环境要求)
2. [开发环境启动](#开发环境启动)
3. [生产环境部署](#生产环境部署)
4. [常见问题](#常见问题)
5. [API 测试](#api-测试)

---

## 环境要求

### 必需软件

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| Dart SDK | 3.0+ | Serverpod 运行时 |
| Docker | 20.0+ | 容器化数据库 |
| Docker Compose | 2.0+ | 服务编排 |

### 安装 Dart SDK

**Windows:**
```powershell
# 使用 Chocolatey
choco install dart-sdk

# 或使用 Scoop
scoop install dart
```

**macOS:**
```bash
brew tap dart-lang/dart
brew install dart
```

**Linux:**
```bash
sudo apt update
sudo apt install dart
```

### 安装 Serverpod CLI

```bash
dart pub global activate serverpod_cli
```

确保 `~/.pub-cache/bin` 已添加到系统 PATH。

---

## 开发环境启动

### 步骤 1：启动数据库

后端需要 PostgreSQL 和 Redis。使用 Docker Compose 启动：

```bash
cd server
docker-compose up -d postgres redis
```

验证数据库运行状态：
```bash
docker-compose ps
```

应该看到：
```
NAME                    STATUS
musheet_postgres        running
musheet_redis           running
```

### 步骤 2：安装依赖

```bash
cd server/musheet_server
dart pub get
```

### 步骤 3：生成 Serverpod 代码

**重要**: 每次修改 `lib/src/protocol/` 目录下的 YAML 文件后，都需要重新生成代码。

```bash
cd server/musheet_server
serverpod generate
```

生成成功后会看到：
```
Serverpod generate completed successfully.
```

### 步骤 4：初始化数据库

首次运行时需要创建数据库表：

```bash
cd server/musheet_server
serverpod create-migration
```

### 步骤 5：启动服务器

```bash
cd server/musheet_server
dart run bin/main.dart  --apply-migrations
```

启动成功后会看到：
```
SERVERPOD version: 3.0.1, dart: 3.10.3 (stable) (Tue Dec 2 01:04:53 2025 -0800) on "windows_x64", time: 2025-12-16 03:49:59.415314Z
...
Serverpod start complete.
```

### 验证服务器运行

打开浏览器访问：
- 健康检查: http://localhost:8080/status/health
- 服务器信息: http://localhost:8080/status/info

---

## 快速启动脚本

### Windows (PowerShell)

创建 `start-server.ps1`:

```powershell
# 启动数据库
cd server
docker-compose up -d postgres redis

# 等待数据库就绪
Start-Sleep -Seconds 5

# 启动服务器
cd musheet_server
dart run bin/main.dart
```

### macOS / Linux (Bash)

创建 `start-server.sh`:

```bash
#!/bin/bash
set -e

# 启动数据库
cd server
docker-compose up -d postgres redis

# 等待数据库就绪
echo "Waiting for database..."
sleep 5

# 启动服务器
cd musheet_server
dart run bin/main.dart
```

运行：
```bash
chmod +x start-server.sh
./start-server.sh
```

---

## 生产环境部署

### 使用 Docker Compose 完整部署

```bash
cd server

# 复制环境变量模板
cp .env.example .env

# 编辑配置
nano .env
```

配置 `.env` 文件:
```env
POSTGRES_USER=musheet
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=musheet
REDIS_PASSWORD=your_redis_password
JWT_SECRET=your_jwt_secret_at_least_32_chars
```

启动所有服务：
```bash
docker-compose up -d
```

### 使用部署脚本

```bash
cd server
./scripts/deploy.sh production full
```

---

## 手机测试配置

当从手机连接到开发环境的后端时：

### 1. 找到电脑 IP 地址

**Windows:**
```powershell
ipconfig
```
找到 IPv4 地址，例如 `192.168.1.100`

**macOS/Linux:**
```bash
ifconfig | grep inet
```

### 2. 在 Flutter App 中配置

在 App 的 **Settings → Backend Debug** 页面：
- 将 Server URL 改为 `http://192.168.1.100:8080`
- 点击 "Test Connection" 测试连接

### 3. 防火墙设置

确保电脑防火墙允许 8080 端口的入站连接。

**Windows:**
```powershell
# 以管理员身份运行
netsh advfirewall firewall add rule name="MuSheet Server" dir=in action=allow protocol=tcp localport=8080
```

---

## 常见问题

### Q: `serverpod generate` 命令失败

**A:** 确保已安装 serverpod_cli：
```bash
dart pub global activate serverpod_cli
```

并确保 PATH 包含 `~/.pub-cache/bin`

### Q: 数据库连接失败

**A:** 检查 Docker 容器状态：
```bash
docker-compose ps
docker-compose logs postgres
```

确保 PostgreSQL 端口 5432 没有被占用。

### Q: 端口 8080 被占用

**A:** 修改 `config/development.yaml` 中的端口：
```yaml
apiServer:
  port: 8081  # 改为其他端口
```

### Q: Redis 连接失败

**A:** 检查 Redis 状态：
```bash
docker-compose logs redis
```

### Q: 生成代码时出现 YAML 解析错误

**A:** 检查 `lib/src/protocol/` 目录下的 YAML 文件格式是否正确。

---

## API 测试

### 使用 curl 测试

**健康检查:**
```bash
curl http://localhost:8080/status/health
```

**注册用户:**
```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","displayName":"Test User"}'
```

**登录:**
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 使用 Flutter App 测试

1. 启动后端服务器
2. 运行 Flutter App
3. 进入 **Settings → Backend Debug**
4. 输入服务器 URL
5. 点击 "Test Connection"
6. 使用测试账号进行 Register/Login 测试

---

## 服务器端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 8080 | API Server | 主 API 服务 |
| 8081 | Insights | 管理面板 |
| 8082 | Web Server | Web 静态资源 |
| 5432 | PostgreSQL | 数据库 |
| 6379 | Redis | 缓存 |

---

## 停止服务器

### 停止 Dart 服务器

按 `Ctrl+C` 终止运行中的服务器进程。

### 停止 Docker 服务

```bash
cd server
docker-compose down
```

### 停止并删除所有数据

```bash
cd server
docker-compose down -v
```

⚠️ **警告**: `-v` 参数会删除所有数据库数据！

---

## 下一步

- 查看 [server/README.md](../server/README.md) 了解完整的 API 文档
- 查看 [backend_architecture.md](./backend_architecture.md) 了解后端架构设计

重构数据库：
# 进入 server 目录
cd server

# 停止服务
docker-compose down

# 删除所有数据卷（包括数据库数据）
docker-compose down -v

# 重新启动（会重新初始化数据库）
docker-compose up -d
