# 数据库查询命令参考

本文档提供常用的 PostgreSQL 数据库查询命令，用于调试和检查同步状态。

## 前提条件

确保 Docker 容器正在运行：
```bash
cd server
docker-compose ps
```

**进入交互式 PostgreSQL 终端**：
```bash
docker exec -it musheet_postgres psql -U musheet -d musheet
# 使用 \q 退出
```

## 基本查询命令

### 查看所有 Scores

```sql
SELECT id, "userId", title, composer, bpm, version, "syncStatus", "createdAt", "updatedAt", "deletedAt"
FROM scores;
```

### 查看所有 InstrumentScores

```sql
-- 不显示 annotationsJson（内容过长）
SELECT id, "scoreId", "instrumentName", "pdfHash", "pdfPath", version, "syncStatus", "createdAt", "updatedAt", "deletedAt"
FROM instrument_scores
ORDER BY id;
```

### 查看所有 Setlists

```sql
SELECT id, "userId", name, description, version, "syncStatus", "createdAt", "updatedAt", "deletedAt"
FROM setlists;
```

### 查看 Setlist-Score 关联

```sql
SELECT "setlistId", "scoreId", "orderIndex", version, "syncStatus", "createdAt", "updatedAt", "deletedAt"
FROM setlist_scores
ORDER BY "setlistId", "orderIndex";
```

### 查看 Annotations（仅元数据）

```sql
-- Annotations 现在嵌入在 InstrumentScore.annotationsJson 中
-- 此查询仅用于查看独立的 annotations 表（如果仍在使用）
SELECT id, "instrumentScoreId", "userId", "pageNumber", type, "createdAt"
FROM annotations
ORDER BY id;
```

### 查看 InstrumentScore 的 Annotations 数量

```sql
-- 统计每个 InstrumentScore 的 annotations 数量（不显示具体内容）
SELECT
  id,
  "instrumentName",
  CASE
    WHEN "annotationsJson" IS NULL OR "annotationsJson" = '[]' THEN 0
    ELSE jsonb_array_length("annotationsJson"::jsonb)
  END as annotations_count
FROM instrument_scores
ORDER BY id;
```

### 查看用户库版本信息

```sql
SELECT "userId", "libraryVersion", "lastSyncedAt"
FROM user_libraries;
```

### 查看用户存储使用情况

```sql
SELECT
  "userId",
  ROUND("usedBytes" / 1024.0 / 1024.0, 2) as "usedMB",        -- 已使用空间（MB）
  ROUND("quotaBytes" / 1024.0 / 1024.0, 2) as "quotaMB",      -- 总配额空间（MB）
  ROUND(("usedBytes"::numeric / "quotaBytes" * 100), 2) as "usagePercent",  -- 使用百分比
  "lastCalculatedAt"
FROM user_storage;
```

## 同步调试查询

### 查看所有待同步的 Scores

```sql
SELECT id, title, "syncStatus", "deletedAt", version
FROM scores
WHERE "syncStatus" = 'pending';
```

### 查看所有已删除的 Scores

```sql
SELECT id, title, composer, "deletedAt", version
FROM scores
WHERE "deletedAt" IS NOT NULL
ORDER BY "deletedAt" DESC;
```

### 查看所有已同步的 Scores

```sql
SELECT id, title, version, "syncStatus"
FROM scores
WHERE "syncStatus" = 'synced' AND "deletedAt" IS NULL;
```

### 统计各状态的 Scores 数量

```sql
SELECT "syncStatus", COUNT(*) as count
FROM scores
GROUP BY "syncStatus";
```

### 查看 Score 及其关联的 InstrumentScores

```sql
-- 不显示 annotationsJson
SELECT
  s.id as score_id,
  s.title,
  s.version as score_version,
  i.id as inst_score_id,
  i."instrumentName",
  i."pdfHash",
  i.version as inst_version
FROM scores s
LEFT JOIN instrument_scores i ON s.id = i."scoreId"
WHERE s."deletedAt" IS NULL
ORDER BY s.id, i.id;
```

## 数据清理命令

### 删除所有已删除的 Scores（物理删除）

⚠️ **警告：这将永久删除数据！**

```sql
DELETE FROM scores WHERE "deletedAt" IS NOT NULL;
```

### 重置特定 Score 的删除状态（恢复）

```sql
UPDATE scores SET "deletedAt" = NULL WHERE id = 5;
```

### 删除特定 Score 及其关联数据

```sql
BEGIN;
DELETE FROM annotations WHERE "instrumentScoreId" IN (SELECT id FROM instrument_scores WHERE "scoreId" = 5);
DELETE FROM instrument_scores WHERE "scoreId" = 5;
DELETE FROM setlist_scores WHERE "scoreId" = 5;
DELETE FROM scores WHERE id = 5;
COMMIT;
```

### 重置整个数据库（清空所有数据）

⚠️ **警告：这将删除所有用户数据！**

```sql
TRUNCATE TABLE annotations CASCADE;
TRUNCATE TABLE instrument_scores CASCADE;
TRUNCATE TABLE setlist_scores CASCADE;
TRUNCATE TABLE setlists CASCADE;
TRUNCATE TABLE scores CASCADE;
TRUNCATE TABLE user_libraries CASCADE;
TRUNCATE TABLE user_storage CASCADE;
```

## PDF 文件管理

### 列出服务器上的 PDF 文件

```bash
docker exec musheet_server ls -lh /app/uploads/users/1/pdfs/
```

### 统计 PDF 文件数量和总大小

```bash
docker exec musheet_server du -sh /app/uploads/users/1/pdfs/
```

### 查看特定 PDF 文件是否存在

```bash
docker exec musheet_server ls -lh /app/uploads/users/1/pdfs/2_約書亞\ 我安然居住.pdf
```

### 删除孤立的 PDF 文件（数据库中不存在引用的文件）

⚠️ **谨慎操作！建议先备份。**

```bash
# 首先列出所有 PDF 文件
docker exec musheet_server find /app/uploads/users/1/pdfs/ -type f
```

**然后查询数据库中的 pdfHash**：
```sql
SELECT id, "instrumentName", "pdfHash" FROM instrument_scores WHERE "pdfHash" IS NOT NULL;
```

## 版本和同步状态查询

### 查看每个 Score 的版本历史趋势

```sql
SELECT
  id,
  title,
  version,
  "syncStatus",
  CASE
    WHEN "deletedAt" IS NULL THEN 'active'
    ELSE 'deleted'
  END as status,
  "updatedAt"
FROM scores
ORDER BY version DESC
LIMIT 20;
```

### 查看同步冲突（有多个同名但不同 ID 的 Scores）

```sql
SELECT
  title,
  COUNT(*) as count,
  STRING_AGG(id::text, ', ') as ids
FROM scores
WHERE "deletedAt" IS NULL
GROUP BY title
HAVING COUNT(*) > 1;
```

## 数据库连接信息

如果需要使用 DBeaver 或其他数据库客户端：

- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `musheet`
- **Username**: `musheet`
- **Password**: `musheet123`

## 故障排查

### 检查数据库连接

```sql
SELECT version();
```

### 检查表是否存在

```sql
\dt
```

### 检查特定表的结构

```sql
\d scores
```

### 查看最近的数据库活动

```sql
SELECT
  datname,
  usename,
  application_name,
  state,
  query
FROM pg_stat_activity
WHERE datname = 'musheet';
```

## 备份和恢复

### 备份整个数据库

```bash
docker exec musheet_postgres pg_dump -U musheet musheet > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 恢复数据库

```bash
cat backup_20251217_120000.sql | docker exec -i musheet_postgres psql -U musheet -d musheet
```

## 实际使用示例

### Windows CMD
在 Windows CMD 中执行时，需要特别注意引号的转义：

```cmd
docker exec musheet_postgres psql -U musheet -d musheet -c "SELECT * FROM scores;"
```

对于包含双引号的列名（如 `"userId"`），需要转义：
```cmd
docker exec musheet_postgres psql -U musheet -d musheet -c "SELECT id, \"userId\", title FROM scores;"
```

### Windows PowerShell
PowerShell 中可以使用单引号包裹整个 SQL 语句：

```powershell
docker exec musheet_postgres psql -U musheet -d musheet -c 'SELECT * FROM scores;'
```

或者使用双引号并转义内部的双引号：
```powershell
docker exec musheet_postgres psql -U musheet -d musheet -c "SELECT id, `"userId`", title FROM scores;"
```

### Linux/Mac Bash
在 Bash 中直接使用即可：

```bash
docker exec musheet_postgres psql -U musheet -d musheet -c "SELECT * FROM scores;"
```

## 注意事项

1. **引号处理**：PostgreSQL 对大小写敏感的列名需要使用双引号（`"columnName"`）
2. **Windows 引号转义**：
   - CMD: 使用反斜杠 `\"`
   - PowerShell: 使用反引号 `` `" ``
3. **多行查询**：使用换行符时要确保整个 SQL 语句在一对引号内
4. **权限**：某些操作需要数据库管理员权限
5. **事务**：重要操作建议在事务中执行（BEGIN/COMMIT）
6. **简化执行**：建议设置命令别名以简化日常使用

## 相关文档

- [后端设置指南](BACKEND_SETUP.md) - 完整的后端部署和配置说明
- [同步逻辑文档](sync_logic.md) - 同步机制的详细说明
- [RPC 同步架构](RPC_SYNC_ARCHITECTURE.md) - RPC 协议和架构设计