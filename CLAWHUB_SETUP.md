# ClawHub 发布配置指南

## 📦 已完成的配置

### 1️⃣ `_meta.json` - 元数据文件

```json
{
  "ownerId": "kn757zdd92w3qkc3vnc5wzddds803vxk",
  "slug": "fitness-personal-assistant",
  "version": "2.1.0",
  "publishedAt": 1741665600000
}
```

### 2️⃣ `.clawhub/origin.json` - 原始仓库信息

```json
{
  "version": 1,
  "registry": "https://clawhub.ai",
  "slug": "fitness-personal-assistant",
  "installedVersion": "2.1.0",
  "installedAt": 1741665600000
}
```

### 3️⃣ SKILL.md Frontmatter

在文件开头添加了:

```yaml
---
name: fitness-personal-assistant
description: 一体化健身追踪系统，管理饮食记录和身体状态，自动同步到 intervals.icu。
---
```

---

## 🚀 提交到 ClawHub

目前需要手动操作：

1. **访问 ClawHub**: https://clawhub.com
2. **连接你的 GitHub 账号**
3. **导入这个仓库**: `leozvc/fitness-personal-assistant`
4. **等待审核和上线**

---

## 📋 检查清单

- [x] LICENSE (MIT)
- [x] README.md (详细文档)
- [x] SKILL.md (含 Frontmatter)
- [x] _meta.json (元数据)
- [x] .clawhub/origin.json (来源信息)
- [x] config.example.json (配置模板)
- [x] .gitignore (保护敏感文件)
- [x] 脚本可执行权限
- [x] GitHub 仓库公开

---

## 🎯 下一步

上传完成后，用户可以使用以下命令安装：

```bash
openclaw skills install leozvc/fitness-personal-assistant
```

或使用版本标签：

```bash
openclaw skills install leozvc/fitness-personal-assistant@2.1.0
```

---

**状态**: ✅ 准备就绪，待提交到 ClawHub 审核
