# MuSheet 网络层架构规范

> 版本: 3.0 | 状态: Draft

---

## 设计原则

| 原则 | 说明 |
|------|------|
| **无感 (Invisible)** | Token 刷新、断网重连对用户透明，业务层不写重试逻辑 |
| **集中 (Centralized)** | Header 注入、错误处理、重试逻辑集中在网络层，业务层无 try-catch |
| **可观测 (Observable)** | 连接状态全局可订阅，UI 状态指示器自动响应 |

---

## 1. 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  只关心：调用方法、处理数据、显示状态指示器            │  │
│  │  不关心：Token、重试、网络状态                         │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                     Repository Layer                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  数据源抽象：Local-first，Network 作为同步源           │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                     Network Layer                           │
│  ┌─────────────────────┐  ┌─────────────────────────────┐  │
│  │   ConnectionManager │  │       ApiClient             │  │
│  │   (状态机 + 心跳)    │  │   (拦截器 + 重试)           │  │
│  └─────────────────────┘  └─────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                     Foundation Layer                        │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │ NetworkService│  │ SessionService│  │  TokenStore   │   │
│  │ (设备连接监听) │  │ (会话持久化)  │  │ (Token 存取)  │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 核心组件

### 2.1 ConnectionManager（连接管理器）

**职责：** 维护服务可用性状态，提供全局可订阅的状态流

```
┌────────────────────────────────────────────────────────────┐
│                    ConnectionManager                        │
├────────────────────────────────────────────────────────────┤
│  输入:                                                      │
│    - NetworkService.onConnectivityChanged                  │
│    - ApiClient.onRequestFailed                             │
│                                                            │
│  输出:                                                      │
│    - Stream<ServiceStatus> statusStream  ← UI 订阅         │
│    - ServiceStatus currentStatus         ← 同步读取        │
│                                                            │
│  内部:                                                      │
│    - 健康检查定时器（10s 轮询）                              │
└────────────────────────────────────────────────────────────┘
```

**状态定义：**

```
enum ServiceStatus {
  connected,    // 服务可用
  disconnected, // 服务不可用（有网但服务器不可达）
  offline,      // 设备无网络
}
```

**状态机：**

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   connected ◄────────────────────────────┐              │
│       │                                  │              │
│       │ 请求失败 / 健康检查失败           │ 健康检查成功  │
│       ▼                                  │              │
│   disconnected ──── 每 10s 检查 ─────────┘              │
│       │                                                 │
│       │ 设备网络断开                                     │
│       ▼                                                 │
│   offline ──── 网络恢复 ──→ 立即检查 ──→ disconnected   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**转换规则：**

| 事件 | 动作 |
|------|------|
| 请求失败（网络/5xx） | 标记 disconnected，启动 10s 轮询 |
| 健康检查成功 | 标记 connected，停止轮询 |
| 健康检查失败 | 保持 disconnected，10s 后重试 |
| 设备网络断开 | 标记 offline，停止轮询 |
| 设备网络恢复 | 立即健康检查 |

### 2.2 ApiClient（请求客户端）

**职责：** 封装 HTTP 请求，通过拦截器处理鉴权和错误

```
┌────────────────────────────────────────────────────────────┐
│                       ApiClient                            │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Request Flow:                                             │
│  ┌──────────┐   ┌──────────────┐   ┌──────────────┐       │
│  │ 业务调用  │ → │ 请求拦截器   │ → │   发送请求   │       │
│  └──────────┘   └──────────────┘   └──────────────┘       │
│                       │                    │               │
│                       ▼                    ▼               │
│              ┌──────────────┐      ┌──────────────┐       │
│              │ 注入 Token   │      │  响应拦截器  │       │
│              │ 检查白名单   │      └──────────────┘       │
│              └──────────────┘             │               │
│                                           ▼               │
│                                  ┌──────────────────┐     │
│                                  │ 成功: 剥离外壳    │     │
│                                  │ 401: 刷新+重试   │     │
│                                  │ 网络错误: 通知CM │     │
│                                  └──────────────────┘     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 3. 拦截器设计

### 3.1 请求拦截器

```
onRequest(config):
  │
  ├─ 接口在白名单? (login, register, health)
  │   └─ 是 → 直接放行
  │
  ├─ 有 Access Token?
  │   ├─ 是 → 注入 Header: Authorization: Bearer {token}
  │   └─ 否 → 检查是否必须认证
  │            ├─ 是 → 抛出 AuthRequiredError
  │            └─ 否 → 放行
  │
  └─ 放行请求
```

### 3.2 响应拦截器

```
onResponse(response):
  │
  ├─ HTTP 2xx
  │   └─ 返回 response.data (剥离外壳)
  │
  ├─ HTTP 401 (Token 过期)
  │   │
  │   ├─ 已在刷新中?
  │   │   └─ 是 → 加入等待队列
  │   │
  │   ├─ 尝试刷新 Token
  │   │   ├─ 成功 → 更新 Token，重试原请求，释放队列
  │   │   └─ 失败 → 触发 onSessionExpired，清空队列
  │   │
  │   └─ 返回结果
  │
  ├─ HTTP 4xx (业务错误)
  │   └─ 返回 BusinessError(code, message)
  │
  └─ HTTP 5xx / 网络错误
      ├─ 通知 ConnectionManager
      └─ 返回 NetworkError
```

### 3.3 Token 刷新（无感刷新）

**关键：并发请求时只刷新一次，其他请求等待**

```
class TokenRefresher {
  _isRefreshing = false
  _waitQueue = []

  async refreshIfNeeded(originalRequest):
    │
    ├─ if (_isRefreshing)
    │   └─ return new Promise → 加入 _waitQueue
    │
    ├─ _isRefreshing = true
    │
    ├─ try:
    │   │ newToken = await api.refreshToken()
    │   │ tokenStore.save(newToken)
    │   │
    │   │ // 释放等待队列
    │   │ _waitQueue.forEach(resolve)
    │   │ _waitQueue = []
    │   │
    │   └─ return retry(originalRequest, newToken)
    │
    └─ catch:
        │ _waitQueue.forEach(reject)
        │ _waitQueue = []
        │ sessionService.logout()
        └─ throw SessionExpiredError
    │
    └─ finally: _isRefreshing = false
```

---

## 4. 重连策略

**核心原则：连不上服务器 = 服务中断，固定 10 秒轮询**

| 参数 | 值 |
|------|-----|
| 端点 | `GET /health` |
| 超时 | 5s |
| 间隔 | 10s（服务中断时） |
| 成功 | HTTP 2xx |

---

## 5. 错误处理

### 5.1 错误分类

```
                    ┌─────────────┐
                    │    Error    │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │ NetworkError│ │ AuthError   │ │BusinessError│
    └─────────────┘ └─────────────┘ └─────────────┘
           │               │               │
           ▼               ▼               ▼
     - Timeout       - 401 Expired    - 400 BadRequest
     - SocketError   - 403 Forbidden  - 404 NotFound
     - DNS Failed                     - 422 Validation
     - SSL Error
```

### 5.2 处理策略

**原则：所有网络错误静默处理，仅记录日志，不弹窗打扰用户。**

| 错误类型 | 处理 | UI 反馈 |
|----------|------|---------|
| NetworkError | 标记服务中断，10s 轮询恢复 | 状态指示器变色（静默） |
| AuthError 401 | 尝试刷新 Token，失败则清除会话 | 状态指示器变色（静默） |
| AuthError 403 | 返回错误，记录日志 | 无（静默） |
| BusinessError | 返回错误，记录日志 | 无（静默） |
| ServerError 5xx | 标记服务中断，10s 轮询恢复 | 状态指示器变色（静默） |

**用户感知：**
- 服务不可用时，UI 状态指示器会变色（红/灰）
- 服务恢复后，自动重试同步，无需用户干预
- 所有网络操作在后台静默运行，不阻塞用户操作

---

## 6. 状态可观测

### 6.1 全局状态流

```dart
// ConnectionManager 提供
final connectionStatusProvider = StreamProvider<ServiceStatus>((ref) {
  return ConnectionManager.instance.statusStream;
});

// 组合状态
final appStatusProvider = Provider<AppStatus>((ref) {
  final connection = ref.watch(connectionStatusProvider);
  final auth = ref.watch(authStateProvider);

  return AppStatus(
    isOnline: connection == ServiceStatus.connected,
    isAuthenticated: auth.isAuthenticated,
    isSyncing: ref.watch(syncStatusProvider).isSyncing,
  );
});
```

### 6.2 UI 状态指示器

```
┌────────────────────────────────────────────────┐
│  状态          │  指示器      │  颜色          │
├────────────────────────────────────────────────┤
│  connected     │  ●           │  绿色          │
│  disconnected  │  ●           │  红色          │
│  offline       │  ○           │  灰色          │
└────────────────────────────────────────────────┘
```

---

## 7. 同步层集成

### 7.1 同步触发条件

| 事件 | 条件 | 动作 |
|------|------|------|
| 登录成功 | - | 立即全量同步 |
| 服务恢复 | connected + authenticated | 立即增量同步 |
| 本地数据变更 | authenticated | 防抖后同步 |
| 应用恢复前台 | connected + authenticated | 延迟增量同步 |

### 7.2 离线队列

```
本地操作 → 写入 SQLite → 标记 pending
                              │
             ┌────────────────┴────────────────┐
             │                                 │
        服务可用                           服务不可用
             │                                 │
             ▼                                 ▼
        推送到服务器                       保持 pending
             │
             ▼
        标记 synced
```

---

## 8. 文件结构

```
lib/core/
├── network/
│   ├── connection_manager.dart    // 连接状态机
│   ├── api_client.dart            // HTTP 客户端
│   ├── interceptors/
│   │   ├── auth_interceptor.dart  // Token 注入
│   │   ├── retry_interceptor.dart // 重试逻辑
│   │   └── error_interceptor.dart // 错误转换
│   ├── token_refresher.dart       // 无感刷新
│   └── errors.dart                // 错误类型定义
│
├── services/
│   ├── network_service.dart       // 设备网络监听
│   ├── session_service.dart       // 会话持久化
│   └── token_store.dart           // Token 存取
│
└── sync/
    ├── sync_coordinator.dart      // 同步协调
    └── offline_queue.dart         // 离线队列
```

---

## 9. 实现检查清单

### P0 - 核心

- [x] ConnectionManager 状态机（3 状态 + 10s 轮询）
- [x] 请求拦截器（Token 注入）
- [x] 响应拦截器（401 处理）
- [x] 无感 Token 刷新（并发安全）

### P1 - 体验

- [x] 全局状态流
- [x] UI 状态指示器
- [x] 健康检查端点
- [x] 静默错误处理（仅日志，无弹窗）

### P2 - 优化

- [ ] 离线队列
- [ ] 请求取消（页面销毁时）
- [ ] 请求去重（防快速点击）

---

## 10. 当前状态

| 模块 | 状态 | 说明 |
|------|------|------|
| ConnectionManager | ✅ 已实现 | 3状态机 + 10s轮询 |
| ApiClient 拦截器 | ✅ 已实现 | Token注入 + 401处理 |
| TokenRefresher | ✅ 已实现 | 并发安全 + 等待队列 |
| 错误处理 | ✅ 已实现 | 静默处理，仅日志 |
| 状态可观测 | ✅ 已实现 | Riverpod Provider |

---

*文档版本: 3.1*
*更新日期: 2025-01-16*
*更新内容: 错误处理改为静默模式，移除Toast弹窗*
