---
name: fitness-personal-assistant
description: 一体化健身追踪系统。自动同步饮食记录和身体状态到 intervals.icu。支持配置引导和错误处理。
allowed-tools:
  - Bash
  - Python
---

# 🏋️ Fitness Personal Assistant（Python 重构版）

一体化健身追踪系统，集成**饮食记录 + 身体状态报告 + 训练分析**。数据自动同步到 intervals.icu，隐私优先，本地处理。

---

## 🎯 功能概览

### 🍽️ 智能饮食记录
- **自然语言输入**: 直接说中文即可，如"早餐吃了两个鸡蛋和全麦面包"
- **自动营养计算**: 中文食物规则库 + 智能估算
- **多餐次识别**: 自动判断早餐/午餐/晚餐/加餐
- **实时同步**: 写入 intervals.icu wellness 数据
- **累计更新**: 自动累加同一天的多餐数据

### 💪 身体状态监控
- **训练负荷**: CTL/ATL/TSB 疲劳度监测
- **恢复指标**: HRV、静息心率、睡眠评分
- **AI 建议**: 根据 TSB 值给出训练/休息指导
- **详细训练记录**: 显示最近 5 次训练的时长/距离/卡路里

### 📊 可视化报告
- Markdown 格式自动生成
- 趋势分析
- Apple Notes / Obsidian 导出支持

---

## 🚀 快速开始

### 1️⃣ 准备 intervals.icu 账号

注册地址：https://intervals.icu/register  
免费版即可，付费版解锁更多高级功能。

### 2️⃣ 获取 API 凭证

1. 登录 intervals.icu
2. 进入 Settings → API Keys
3. 复制你的 `Athlete ID` 和 `API Key`

示例（**注意替换为你的真实凭证**）：
```
Athlete ID: iXXXXXXXXX
API Key: YOUR_INTERVALS_ICU_API_KEY_HERE
```

⚠️ **安全提示**: 
- 永远不要将真实 API Key 提交到 Git
- 使用 `.env` 文件或环境变量管理密钥
- 示例中的 `iXXXXXXXXX` 和 `YOUR_INTERVALS_ICU_API_KEY_HERE` 为占位符

### 3️⃣ 配置凭证（可选）

工具会在首次运行时**自动引导你创建配置文件**。

**默认存储路径:** `~/.openclaw/workspace/body-management-data`  
**可自定义:** 通过环境变量 `BODY_MANAGEMENT_DATA`

如果脚本检测到配置文件不存在或读取失败，会提示你输入:
- Athlete ID (例如：`iXXXXXXXXX`)
- API Key

凭证会自动保存到 `config.json`,权限设置为 `600`。

**手动配置方式:**
```bash
mkdir -p ~/.openclaw/workspace/body-management-data
```

编辑 `~/.openclaw/workspace/body-management-data/config.json`:
```json
{
  "intervals_icu": {
    "api_key": "YOUR_API_KEY",
    "athlete_id": "iYOUR_ID"
  }
}
```

**注意:** 使用 `.env` 文件或环境变量管理密钥更安全，不要将 `config.json` 提交到 Git。

### 4️⃣ 验证安装

运行健康检查：
```bash
cd ~/.openclaw/workspace/skills/fitness-personal-assistant/scripts
python3 intervals_api_client.py
```

预期输出：
```
✅ API 连接成功
📊 获取运动员摘要...
  体能 (fitness): 19.74
  疲劳 (fatigue): 30.43
  形态 (form/TSB): -10.69
```

---

## 📝 使用示例

### 方法 A：自然语言输入（推荐）

群里直接发消息或使用命令行：

```bash
# 单条记录
python3 meal-to-intervals.py --text "300g 牛肉和 200 克米饭"

# 混合多种食物
python3 meal-to-intervals.py --text "早餐两个鸡蛋一片全麦面包，一杯牛奶"

# 指定日期
python3 meal-to-intervals.py --text "午餐吃了沙拉" --date 2026-03-09

# 干跑模式（测试，不上传）
python3 meal-to-intervals.py --text "300g 牛肉" --dry-run
```

系统自动识别：
- **时间**: 当前时刻（可用 `--date` 覆盖）
- **餐次**: 根据关键词判断（早餐/午餐/晚餐/加餐）
- **营养**: 自动计算

### 方法 B：JSON 文件输入

创建 `meal.json`:
```json
{
  "meal_name": "午餐",
  "meal_time": "2026-03-10T12:30:00+08:00",
  "notes": "公司食堂",
  "items": [
    {"name": "鸡胸肉", "grams": 200, "calories": 220, "protein_g": 46, "carbs_g": 0, "fat_g": 3},
    {"name": "西兰花", "grams": 150, "calories": 52, "protein_g": 4.5, "carbs_g": 10.5, "fat_g": 0.75},
    {"name": "米饭", "grams": 250, "calories": 325, "protein_g": 6.25, "carbs_g": 70, "fat_g": 1.25}
  ]
}
```

执行：
```bash
python3 meal-to-intervals.py --input meal.json
```

### 方法 C：查询身体状态

#### 方式 1: 群里发消息
```
查看我的身体状态
今天的训练负荷怎么样？
我适合高强度训练吗？
```

#### 方式 2: 命令行
```bash
cd ~/.openclaw/workspace/skills/fitness-personal-assistant/scripts
python3 body-status-reporter.py
```

---

## 🔧 高级选项

### 干跑模式（测试）

不上传数据，只计算营养：
```bash
python3 meal-to-intervals.py --text "300g 牛肉" --dry-run
```

### 批量导入

编写脚本循环处理多个 JSON 文件：
```bash
for file in meals/*.json; do
    python3 meal-to-intervals.py --input "$file"
done
```

### 自定义存储路径

```bash
export BODY_MANAGEMENT_DATA=/path/to/your/data
python3 meal-to-intervals.py --text "早餐"
```

---

## 🛠️ 技术细节

### 营养计算引擎

**三层策略**：

1. **第一层：中文食物规则库**
   ```python
   肉类分类：
   - 鸡胸：110kcal/100g, 23g 蛋白质
   - 牛肉：200kcal/100g, 22g 蛋白质
   - 猪肉：250kcal/100g, 20g 蛋白质
   - 鱼：120kcal/100g, 20g 蛋白质
   
   主食分类：
   - 米饭：130kcal/100g, 28g 碳水
   - 面条：110kcal/100g, 25g 碳水
   - 面包：270kcal/100g, 50g 碳水
   - 方便面：450kcal/100g, 55g 碳水
   
   蛋奶：
   - 鸡蛋：155kcal/100g, 13g 蛋白质
   - 牛奶：50kcal/100ml, 3.5g 蛋白质
   
   蔬果类:
   - 蔬菜：30kcal/100g
   - 水果：60kcal/100g
   ```

2. **第二层：智能解析**
   - 支持"250ml 牛奶"、"200 克鸡胸"、"两个鸡蛋"、"一碗米饭"
   - 自动按"和"、"、"分割多种食物
   - 优先匹配更长关键词（"方便面"优先于"面"）

3. **第三层：默认估算**
   - 未知食物使用通用值：150kcal/100g

### API 客户端特性

- **自动重试**: 最多 3 次，指数退避（2s, 4s, 8s）
- **错误处理**: 403/404/500 等状态码优雅降级
- **Basic Auth**: 使用 `API_KEY:<key>` 格式
- **连接测试**: `client.test_connection()`
- **配置引导**: 配置文件不存在时自动引导用户输入凭证
- **格式验证**: 验证 Athlete ID 格式 (必须是以 `i` 开头)

### Wellness 数据字段

| 字段 | 说明 | 单位 |
|------|------|------|
| `calories` | 饮食热量（累计） | kcal |
| `protein` | 蛋白质（累计） | g |
| `carbs` | 碳水（累计） | g |
| `fat` | 脂肪（累计） | g |
| `note_breakfast` | 早餐备注 | text |
| `note_lunch` | 午餐备注 | text |
| `note_dinner` | 晚餐备注 | text |
| `hrv` | 心率变异性 | ms |
| `restingHR` | 静息心率 | bpm |
| `sleepSecs` | 睡眠时长 | seconds |
| `steps` | 步数 | count |
| `weight` | 体重 | kg |
| `locked` | 锁定数据（防止同步覆盖） | bool |

---

## 📁 目录结构

```
~/.openclaw/workspace/
├── skills/
│   └── fitness-personal-assistant/
│       ├── SKILL.md              # 本文档
│       └── scripts/
│           ├── intervals_api_client.py    # API 客户端（核心）
│           ├── body-status-reporter.py    # 身体状态报告
│           └── meal-to-intervals.py       # 饮食记录
│
└── body-management-data/          # 用户数据目录
    └── config.json                # API 凭证（gitignore）
```

### Git Ignore 建议

在 `.gitignore` 中添加：
```
body-management-data/config.json
*.log
data/meals/
```

---

## ❓ FAQ

**Q: 如何修改运动员 ID？**  
A: 编辑 `~/.openclaw/workspace/body-management-data/config.json`，无需重启，下次运行自动读取新配置。

**Q: 如何备份我的数据？**  
A: 所有原始数据存储在 intervals.icu 云端，本地仅缓存配置。定期 export intervals.icu 数据即可。

**Q: 不支持某些中国食材怎么办？**  
A: 编辑 `meal-to-intervals.py` 中的 `FOOD_RULES` 字典，添加更多中文食物的精确数值。

**Q: 如何提高营养估算精度？**  
A: 可以扩展 `FOOD_RULES` 字典，或手动创建 JSON 文件输入精确营养数据。

**Q: 数据为什么没有同步？**  
A: 检查：
1. API key 是否有效（运行 `intervals_api_client.py` 测试）
2. 网络连接是否正常
3. 配置文件路径是否正确

**Q: 如何解锁被锁定的 wellness 数据？**  
A: 在 intervals.icu 网页端手动解锁，或使用 API 设置 `"locked": false`。

**Q: 配置文件损坏了怎么办？**  
A: 删除 `config.json`,重新运行任意脚本会自动引导你重新配置。

---

## 🔄 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v3.3.0 | 2026-03-10 | 新增配置引导功能：配置文件不存在/损坏时自动提示用户输入凭证 |
| v3.2.0 | 2026-03-10 | 默认输出详细分析报告，含竞技状态准备度 + 深度解读表格 |
| v3.1.0 | 2026-03-10 | Python 完整重构，基于官方 API 文档，支持完整 wellness 字段 |
| v2.1 | 2026-03-10 | 支持自定义存储路径，自动创建子目录 |
| v2.0 | 2026-03-09 | 合并 body-management-system，新增自然语言输入 |
| v1.3.2 | 2026-03-09 | bug fix，field names 修正 |
| v1.3.1 | 2026-03-08 | API 响应检查修复，限流保护 |
| v1.3.0 | 2026-03-08 | 纯云营养计算 + 智能估算 |
| v1.2.0 | 2026-03-08 | Zero dependency migration（纯 Bash） |
| v1.0.0 | 2026-03-06 | 初始版本 |

---

## 📚 引用资源

- [Intervals.icu API Integration Cookbook](https://forum.intervals.icu/t/intervals-icu-api-integration-cookbook/80090)
- [API access to Intervals.icu](https://forum.intervals.icu/t/api-access-to-intervals-icu/609)
- [Intervals.icu 官方文档](https://intervals.icu/api-docs.html)

---

## ⚠️ 注意事项

1. **API Key 安全**: 不要将 `config.json` 上传到公开仓库
2. **网络依赖**: 需要能访问 intervals.icu API
3. **数据准确性**: 营养估算是近似值，精确数据请使用 JSON 输入
4. **锁定机制**: 使用 `"locked": true` 可防止外部同步覆盖手动数据

---

**MIT License** © 2026 leozvc (modded by OpenClaw community)
