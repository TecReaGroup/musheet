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

确保 Serverpod CLI 可执行目录已添加到系统 PATH。

- Windows 常见路径：`C:\Users\<用户名>\AppData\Local\Pub\Cache\bin`
- macOS / Linux 常见路径：`~/.pub-cache/bin`

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
dart run bin/main.dart --apply-migrations
```

当前 Docker 配置中默认暴露以下端口，见 [`server/docker-compose.yml`](server/docker-compose.yml:57)：
- `8080`：API
- `8081`：Serverpod Insights
- `8082`：Server Web

### 验证服务器运行

打开浏览器访问：
- 健康检查: `http://localhost:8080/status/health`
- 服务器信息: `http://localhost:8080/status/info`
- Insights: `http://localhost:8081/insights`

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

### Admin Web UI（可选）

当前项目包含独立的 Flutter Web 管理端 [`server/admin_web/`](server/admin_web)，并通过 [`server/docker-compose.yml`](server/docker-compose.yml:98) 以可选服务方式启动。

启动包含管理端的完整环境：

```bash
cd server
docker-compose --profile with-admin up -d
```

管理端默认访问地址：
- `http://localhost:3000`

> 说明：旧文档中的部署脚本说明已移除，因为当前仓库中未提供对应的 [`deploy.sh`](server/scripts) 脚本实现。

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

在 App 中将后端地址配置为：
- `http://192.168.1.100:8080`

当前客户端会从本地持久化配置中读取 `backend_server_url`，并在启动时恢复，见 [`lib/main.dart`](lib/main.dart:54)。如果未配置地址，客户端会记录 “no server configured” 并跳过远程初始化。

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

并确保 PATH 包含对应的 Pub Cache bin 目录。

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

## 完全重置数据库（不保留任何数据）

如果需要从头开始，删除所有现有数据并重建数据库：

### 方法 1：使用 Docker Compose（推荐）

```bash
# 进入 server 目录
cd server

# 停止所有服务
docker-compose down

# 删除所有数据卷（包括数据库数据）
docker-compose down -v

# 重新启动数据库
docker-compose up -d postgres redis

# 等待数据库就绪（约 5 秒）
# Windows PowerShell:
Start-Sleep -Seconds 5
# macOS/Linux:
sleep 5

# 进入 musheet_server 目录
cd .\server\musheet_server\

# 重新生成代码
serverpod generate

# 先删除 migrations 目录下的所有旧迁移文件
serverpod create-migration

# 应用迁移（创建数据库和表）
dart run bin/main.dart --apply-migrations
```

## 下一步

- 查看 [server/README.md](../server/README.md) 了解完整的 API 文档
- 查看 [backend_architecture.md](./backend_architecture.md) 了解后端架构设计
