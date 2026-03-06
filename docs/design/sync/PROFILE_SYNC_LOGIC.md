# MuSheet Profile（用户信息）同步逻辑（文字版）

> 本文档描述 MuSheet **Profile**（用户名、展示名、个人简介、偏好的 instrument、头像等）的同步逻辑。

---

## 1. Profile 的范围与字段

Profile 指与"用户账号"绑定、**跨设备一致**的用户信息（由服务器保存），典型字段：

- `displayName`：展示名
- `username`：登录名（通常不可随意更改，作为账号标识的一部分）
- `preferredInstrument`：偏好的 instrument（跨设备一致的用户偏好）
- `avatarUrl`：头像 URL（由服务器存储 avatar 文件并生成 URL）
- 其他只读字段：`createdAt`、`lastLoginAt`、`storageUsedBytes`、`teams`

服务器端 Profile 数据由 [`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12) 组装返回；更新由 [`ProfileEndpoint.updateProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:59) 处理。

---

## 2. 与"曲库同步"的关系：独立通道

Profile 同步 **不属于 libraryVersion 同步通道**，原因：

- Profile 不参与曲库/曲单的依赖关系与版本号推进
- Profile 变更频率低、字段简单，直接用 Profile API 拉取/推送即可
- Profile 的冲突处理可以采用更简单的"字段级 Last-Write-Wins（最终以服务器保存的值为准）"

因此，Profile 同步可以理解为：

- "Profile 通道"：按需的 `getProfile / updateProfile / uploadAvatar`
- "Library 通道"：按 [`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 的 `library/push` 与 `library/pull` 机制

---

## 3. 数据源（Source of Truth）与本地缓存

### 3.1 服务器是 Profile 的最终权威

- `username / displayName / bio / preferredInstrument / avatarUrl` 的最终权威来源为服务器。
- 客户端采用**本地优先**策略：用户修改立即生效，后台非阻塞同步到服务器。

### 3.2 本地存储策略

**统一使用 `UserProfile` 作为唯一缓存**：

- `SessionService` 持久化完整的 `UserProfile` 到 `SharedPreferences`（key: `user_profile`）
- `UserProfile` 包含 `preferredInstrument` 字段，无需单独缓存
- 启动时从 `SessionService` 恢复，在线时后台刷新

**不再单独缓存 `preferredInstrument`**：

- 移除 `PreferencesService.getPreferredInstrument()` / `setPreferredInstrument()` 的独立存储
- 所有 `preferredInstrument` 读写统一通过 `UserProfile` 进行

---

## 4. 同步触发点（何时 Pull / Push）

### 4.1 登录后（或恢复会话后）Pull Profile

客户端会在恢复会话时尝试从服务器校验 token，并在成功后拉取 Profile：

- 会话恢复逻辑在 [`AuthStateNotifier.restoreSession()`](lib/providers/auth_state_provider.dart:148)
- Profile 拉取在其内部调用 [`AuthRepository.fetchProfile()`](lib/core/repositories/auth_repository.dart:216)

效果：

- 在线：刷新 UI 显示的 `displayName / username / preferredInstrument` 等
- 离线：保持"已登录但离线"的状态（token 仍在本地），使用本地缓存的 `UserProfile`

### 4.2 用户更新 Profile：本地优先 + 后台 Push

当用户在 UI 中修改 Profile 字段（例如展示名、偏好的 instrument），客户端采用**本地优先**策略：

1. **立即更新本地状态**（乐观 UI）
2. **后台非阻塞同步**：
   - 已登录且在线：调用 `updateProfile` Push 到服务器
   - 已登录但离线：跳过同步，本地修改保留（下次在线时通过 Pull 可能被服务器值覆盖）
   - 未登录：仅更新本地状态，不同步

实现入口：

- UI Provider: [`PreferredInstrumentNotifier.setPreferredInstrument()`](lib/providers/preferred_instrument_provider.dart)
- Auth Provider: [`AuthStateNotifier.updateProfile()`](lib/providers/auth_state_provider.dart:327)
- Repository: [`AuthRepository.updateProfile()`](lib/core/repositories/auth_repository.dart:241)

### 4.3 头像更新：Push（uploadAvatar）

头像属于"文件 + 元数据"的组合，但它不走 PDF 文件通道：

- avatar 文件通过 [`ProfileEndpoint.uploadAvatar()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:83) 上传并落盘
- 服务器生成可访问 URL（见 [`ProfileEndpoint._getAvatarUrl()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:281)）
- 上传成功后，客户端应以返回的 `avatarUrl` 更新 UI

头像更新的特点：

- 体积小（服务器侧限制 2MB）
- 不需要 hash 去重/引用计数
- 不参与 libraryVersion

---

## 5. preferredInstrument 统一管理

### 5.1 Provider 架构

**唯一入口**：[`preferredInstrumentProvider`](lib/providers/preferred_instrument_provider.dart)

```dart
class PreferredInstrumentNotifier extends Notifier<String?> {
  @override
  String? build() {
    // 从 authStateProvider 获取初始值
    final authState = ref.watch(authStateProvider);
    return authState.user?.preferredInstrument;
  }

  Future<void> setPreferredInstrument(String? instrumentKey) async {
    // 1. 立即更新本地状态（乐观 UI）
    state = instrumentKey;

    // 2. 清除 lastOpenedInstrument 缓存
    ref.read(lastOpenedInstrumentInScoreProvider.notifier).clearAll();

    // 3. 后台非阻塞同步到服务器（已登录且在线时）
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      // 不 await，后台执行
      ref.read(authStateProvider.notifier).updateProfile(
        preferredInstrument: instrumentKey,
      );
    }
  }
}
```

### 5.2 数据流

```
┌─────────────────┐     watch      ┌──────────────────────────┐
│ authStateProvider│ ─────────────▶ │ preferredInstrumentProvider│
│ (UserProfile)    │               │ (String?)                  │
└─────────────────┘               └──────────────────────────┘
        ▲                                    │
        │ updateProfile()                    │ setPreferredInstrument()
        │                                    ▼
        │                          ┌──────────────────────────┐
        └────────────────────────── │ UI (InstrumentPreference │
                                   │      Screen)             │
                                   └──────────────────────────┘
```

### 5.3 已移除的重复实现

- ~~`lib/providers/ui_state_providers.dart` 中的 `PreferredInstrumentNotifier`~~
- ~~`lib/providers/core_providers.dart` 中的 `AppPreferences.preferredInstrument`~~
- ~~`lib/screens/library_screen.dart` 中的 `PreferredInstrumentNotifier`~~（移动到独立文件）

---

## 6. 冲突策略（多端同时修改）

Profile 字段较少、依赖简单，推荐使用"服务器最终值为准"的策略：

- 同时修改同一字段：后一次到达服务器的写入覆盖前一次（Last-Write-Wins）
- 修改不同字段：服务器按"只更新传入字段"方式合并（见 [`ProfileEndpoint.updateProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:59) 的"仅提供字段才更新"语义）

客户端层面无需像 libraryVersion 那样处理 412 冲突（Profile API 不走 `libraryVersion` 的乐观锁冲突检测）。

**本地优先的冲突处理**：

- 用户离线修改 → 本地生效
- 恢复在线后 Pull Profile → 服务器值可能覆盖本地修改
- 这是可接受的，因为 `preferredInstrument` 是低冲突字段

---

## 7. 与登出/清理的关系

登出会清除本地登录态与本地数据（曲库数据库与本地 PDF 等），参考登出实现：

- [`AuthStateNotifier.logout()`](lib/providers/auth_state_provider.dart:269)

Profile 数据本身存储在服务器，不会因客户端登出而被删除；登出后再次登录会重新 Pull Profile。

---

## 8. 典型流程总结

### 8.1 新设备登录

1. 用户登录成功（获得 token）
2. 服务器返回完整 `UserProfile`（包含 `preferredInstrument`）
3. `SessionService` 持久化 `UserProfile`
4. `preferredInstrumentProvider` 自动从 `authStateProvider.user` 获取值
5. 客户端按 [`APP_SYNC_LOGIC.md`](docs/sync_logic/APP_SYNC_LOGIC.md) 进入 Library 同步

### 8.2 修改偏好 instrument

1. 用户在设置页选择新的 instrument
2. `PreferredInstrumentNotifier.setPreferredInstrument()` 被调用
3. UI 即时更新（乐观）
4. 后台非阻塞调用 `authStateProvider.updateProfile()`
5. 服务器返回最新 Profile，`SessionService` 更新持久化

### 8.3 离线使用

- 用户修改 `preferredInstrument` 立即生效（本地优先）
- 离线时跳过服务器同步
- 恢复在线后，Pull Profile 可能覆盖本地值（Last-Write-Wins）

### 8.4 App 重启

1. `SessionService` 从 `SharedPreferences` 恢复 `UserProfile`
2. `authStateProvider` 立即可用（包含 `preferredInstrument`）
3. `preferredInstrumentProvider` watch `authStateProvider`，自动获取值
4. 后台验证 token 并刷新 Profile（如果在线）

