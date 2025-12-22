# MuSheet Profile（用户信息）同步逻辑（文字版）

> 本文档描述 MuSheet **Profile**（用户名、展示名、个人简介、偏好的 instrument、头像等）的同步逻辑。

---

## 1. Profile 的范围与字段

Profile 指与“用户账号”绑定、**跨设备一致**的用户信息（由服务器保存），典型字段：

- `displayName`：展示名
- `username`：登录名（通常不可随意更改，作为账号标识的一部分）
- `preferredInstrument`：偏好的 instrument（跨设备一致的用户偏好）
- `avatarUrl`：头像 URL（由服务器存储 avatar 文件并生成 URL）
- 其他只读字段：`createdAt`、`lastLoginAt`、`storageUsedBytes`、`teams`

服务器端 Profile 数据由 [`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12) 组装返回；更新由 [`ProfileEndpoint.updateProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:59) 处理。

---

## 2. 与“曲库同步”的关系：独立通道

[`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 定义的同步主流程（Push→Pull→PDF）针对的是 **Library 元数据**（Score / InstrumentScore / Setlist / SetlistScore）与 PDF 文件。

Profile 同步 **不属于 libraryVersion 同步通道**，原因：

- Profile 不参与曲库/曲单的依赖关系与版本号推进
- Profile 变更频率低、字段简单，直接用 Profile API 拉取/推送即可
- Profile 的冲突处理可以采用更简单的“字段级 Last-Write-Wins（最终以服务器保存的值为准）”

因此，Profile 同步可以理解为：

- “Profile 通道”：按需的 `getProfile / updateProfile / uploadAvatar`
- “Library 通道”：按 [`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 的 `library/push` 与 `library/pull` 机制

---

## 3. 数据源（Source of Truth）与本地缓存

### 3.1 服务器是 Profile 的唯一权威

- `username / displayName / bio / preferredInstrument / avatarUrl` 的权威来源为服务器。
- 客户端本地仅在 UI 状态中短暂缓存（例如登录后保存到内存状态），并通过 API 刷新。

客户端获取 Profile 的入口是 [`BackendService.getProfile()`](lib/services/backend_service.dart:325)。

### 3.2 本地 SharedPreferences：只保存“轻量本地偏好”和“认证信息”

MuSheet 使用 [`PreferencesService`](lib/services/preferences_service.dart:32) 保存：

- 认证相关：`auth_token`（见 [`PreferencesService.getAuthToken()`](lib/services/preferences_service.dart:77) / [`PreferencesService.setAuthToken()`](lib/services/preferences_service.dart:82)）
- 应用级偏好：例如本地的 `preferred_instrument`（见 [`PreferencesService.getPreferredInstrument()`](lib/services/preferences_service.dart:237)）

重要区分：

- **Profile.preferredInstrument（云端字段）**：跨设备一致，属于“账号信息”。
- **preferred_instrument（本地偏好）**：当前实现用于 UI 行为（例如打开曲谱时默认选择某种 instrument），属于“设备偏好”。

当前工程中，这两者**并未自动互相同步**：

- Profile API 的更新入口支持 `preferredInstrument`（见 [`BackendService.updateProfile()`](lib/services/backend_service.dart:337)）。
- 但设置页的“Preferred Instrument”主要写入本地偏好（见 [`PreferencesService.setPreferredInstrument()`](lib/services/preferences_service.dart:243)），用于 UI 选择逻辑，而不是必然写回服务器。

---

## 4. 同步触发点（何时 Pull / Push）

Profile 同步遵循与 [`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 一致的理念：

- UI 先展示本地状态（即使是旧的/空的）
- 网络在后台补齐（Pull）
- 用户修改立即写入“目标存储”并尽快 Push（但 Profile 修改频率低，可直接实时 push）

### 4.1 登录后（或恢复会话后）Pull Profile

客户端会在恢复会话时尝试从服务器校验 token，并在成功后拉取 Profile：

- 会话恢复逻辑在 [`AuthNotifier.restoreSession()`](lib/providers/auth_provider.dart:141)
- Profile 拉取在其内部调用 [`BackendService.getProfile()`](lib/services/backend_service.dart:325)

效果：

- 在线：刷新 UI 显示的 `displayName / username` 等
- 离线：保持“已登录但离线”的状态（token 仍在本地），UI 可继续使用本地曲库（如已存在），Profile 可能不更新

### 4.2 用户更新 Profile：Push（updateProfile）

当用户在 UI 中修改 Profile 字段（例如展示名、偏好的 instrument），客户端应：

1. 立即更新 UI 的本地状态（乐观 UI）
2. 直接调用 Profile 更新接口，将变更 Push 到服务器
3. 以服务器返回的 Profile 覆盖本地状态（确保最终一致）

当前实现的 Profile 更新入口为：

- 服务器端：[`ProfileEndpoint.updateProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:59)
- 客户端：[`BackendService.updateProfile()`](lib/services/backend_service.dart:337)

### 4.3 头像更新：Push（uploadAvatar）

头像属于“文件 + 元数据”的组合，但它不走 PDF 文件通道：

- avatar 文件通过 [`ProfileEndpoint.uploadAvatar()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:83) 上传并落盘
- 服务器生成可访问 URL（见 [`ProfileEndpoint._getAvatarUrl()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:281)）
- 上传成功后，客户端应以返回的 `avatarUrl` 更新 UI

头像更新的特点：

- 体积小（服务器侧限制 2MB）
- 不需要 hash 去重/引用计数
- 不参与 libraryVersion

---

## 5. 冲突策略（多端同时修改）

Profile 字段较少、依赖简单，推荐使用“服务器最终值为准”的策略：

- 同时修改同一字段：后一次到达服务器的写入覆盖前一次（Last-Write-Wins）
- 修改不同字段：服务器按“只更新传入字段”方式合并（见 [`ProfileEndpoint.updateProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:59) 的“仅提供字段才更新”语义）

客户端层面无需像 libraryVersion 那样处理 412 冲突（Profile API 不走 `libraryVersion` 的乐观锁冲突检测）。

---

## 6. 与登出/清理的关系

登出会清除本地登录态与本地数据（曲库数据库与本地 PDF 等），参考登出实现：

- [`AuthNotifier.logout()`](lib/providers/auth_provider.dart:406)

Profile 数据本身存储在服务器，不会因客户端登出而被删除；登出后再次登录会重新 Pull Profile。

---

## 7. 典型流程总结

### 7.1 新设备登录

1. 用户登录成功（获得 token）
2. 客户端初始化鉴权上下文
3. 客户端后台 Pull Profile（显示 username / displayName / avatar 等）
4. 客户端按 [`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 进入 Library 同步（曲库/曲单）

### 7.2 修改展示名 / 偏好 instrument

1. UI 即时更新（乐观）
2. Push：调用 `updateProfile`
3. 服务器返回最新 Profile
4. 客户端以返回值覆盖本地缓存，确保一致

### 7.3 离线使用

- Profile 不阻塞 UI：离线时跳过 Pull/Push
- 资料卡片提示 offline 状态，有网络后自动刷新，而不需要重新登录
- 在线恢复后：先恢复会话并 Pull Profile，再按需同步 Library

---

## 8. 当前实现的“云端 Profile vs 本地偏好”建议（避免混淆）

由于工程同时存在：

- 云端字段 `preferredInstrument`（Profile）
- 本地偏好键 `preferred_instrument`（SharedPreferences）

建议在产品层面明确语义（并在文案上区分）：

- “默认打开哪种分谱（本机）”：继续使用本地偏好
- “个人资料的主乐器（跨设备）”：写入 Profile.preferredInstrument

若未来希望“跨设备同步默认乐器选择”，则需要在登录后：

- Pull Profile 后，将 `preferredInstrument` 写入本地偏好；并在本地修改时同时 Push Profile

这部分属于产品决策与后续增强，不影响 [`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 的曲库同步主流程。
