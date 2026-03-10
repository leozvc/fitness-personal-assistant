---
name: fitness-personal-assistant
description: 一体化健身追踪系统，管理饮食记录和身体状态，自动同步到 intervals.icu。
---

# 🏋️ Fitness Personal Assistant（统一版）

一体化健身追踪系统，集成**饮食记录 + 身体状态报告 + 训练分析**。数据自动同步到 intervals.icu，隐私优先，本地处理。

---

## 🎯 功能概览

### 🍽️ 智能饮食记录
- **自然语言输入**: 直接说中文即可，如"早餐吃了两个鸡蛋和全麦面包"
- **自动营养计算**: OpenFoodFacts API + 中文食物类别 AI 估算法
- **多餐次识别**: 自动判断早餐/午餐/晚餐/加餐
- **实时同步**: 写入 intervals.icu wellness 数据

### 💪 身体状态监控
- **训练负荷**: CTL/ATL/TSB 疲劳度监测
- **恢复指标**: HRV、静息心率、睡眠评分
- **AI 建议**: 根据 TSB 值给出训练/休息指导

### 📊 可视化报告
- Markdown 格式自动生成
- 趋势分析图表（Python/Matplotlib）
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

示例：
```
Athlete ID: i206099
API Key: 6v48pzlyu6jv48m7ndjjiqq0p
```

### 3️⃣ 配置凭证

**默认存储路径：** `~/.openclaw/workspace/body-management-data`  
**可自定义：** 通过环境变量 `BODY_MANAGEMENT_DATA` 或在命令行使用 `-s/--storage-path` 参数

创建配置文件（未配置则自动创建）：
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

**注意:** 脚本会在指定存储路径下自动创建 `config/` 和 `data/` 子目录。如果旧位置 (`body-management-data/config.json`) 有配置文件，会自动兼容使用。

> ⚠️ 安全提示：文件权限设置为 `chmod 600 config.json`，避免泄露凭证。

### 4️⃣ 验证安装

运行健康检查：
```bash
cd ~/.openclaw/workspace/skills/fitness-personal-assistant/scripts
./meal-to-intervals.sh --health-check
```

预期输出：
```
🏥 健康检查开始...
✅ OpenFoodFacts OK
✅ jq installed
✅ Config exists
✅ Intervals API connection successful (i206099)
```

---

## 📝 使用示例

### 方法 A：自然语言输入（推荐）

群里直接发消息或使用命令行：

```bash
# 单条记录
./meal-to-intervals.sh --text "300g 牛肉和 200 克米饭"

# 混合多种食物
./meal-to-intervals.sh --text "早餐两个鸡蛋一片全麦面包，一杯牛奶"
```

系统自动识别：
- **时间**: 当前时刻（可后续扩展自定义时间）
- **餐次**: 根据关键词判断（早餐/午餐/晚餐/加餐）
- **营养**: 自动调用 API 或 AI 估算

### 方法 B：JSON 文件输入

创建 `meal.json`:
```json
{
  "meal_name": "午餐",
  "meal_time": "2026-03-10T12:30:00+08:00",
  "items": [
    {"name": "鸡胸肉", "grams": 200},
    {"name": "西兰花", "grams": 150},
    {"name": "米饭", "grams": 250}
  ]
}
```

执行：
```bash
./meal-to-intervals.sh --input meal.json
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
cd ~/.openclaw/workspace/skills/body-management-system/scripts
./intervals-status-reporter.sh
```

---

## 🔧 高级选项

### 干跑模式（测试）

不上传数据，只计算营养：
```bash
./meal-to-intervals.sh --dry-run --text "300g 牛肉"
```

### 自定义输出格式

未来扩展支持：`--format json|markdown|text`

### 批量导入

编写脚本循环处理多个 meal.json 文件：
```bash
for file in meals/*.json; do
    ./meal-to-intervals.sh --input "$file"
done
```

---

## 🛠️ 技术细节

### 营养计算引擎

**三层策略**：

1. **第一层：OpenFoodFacts API**
   - 全球食品数据库，覆盖欧美主流食品
   - 每秒最多请求限制（指数退避重试）
   
2. **第二层：中文食物规则匹配**
   ```
   肉类分类：
   - 瘦蛋白（胸肉/腱子）: 150kcal/100g, 25g 蛋白质
   - 正常肉类: 200kcal/100g, 22g 蛋白质
   - 高脂肪（五花肉/肋排）: 350kcal/100g, 30g 脂肪
   
   主食分类：
   - 米饭: 130kcal/100g, 28g 碳水
   - 面条: 110kcal/100g, 25g 碳水
   - 全麦面包: 250kcal/100g, 43g 碳水
   - 普通面包: 270kcal/100g, 55g 碳水
   
   蔬果类:
   - 蔬菜: 30kcal/100g
   - 水果: 60kcal/100g
   
   乳制品:
   - 牛奶: 50kcal/100g, 3g 蛋白质
   
   油脂类:
   - 油/黄油: 900kcal/100g, 100g 脂肪
   ```

3. **第三层：默认估算**
   - 未知食物使用通用值：150kcal/100g

### 错误处理机制

- **API 失败降级**: 如果 OpenFoodFacts 不可用，自动切换到 AI 估算
- **重试逻辑**: 最多 3 次，指数退避（2s, 4s, 8s）
- **详细日志**: 每条记录的来源（API/Estimate）都标记清楚

---

## 📁 目录结构

```
~/.openclaw/workspace/
├── skills/
│   └── fitness-personal-assistant/
│       ├── SKILL.md              # 本文档
│       └── scripts/
│           ├── meal-to-intervals.sh   # 饮食记录脚本
│           └── intervals-status-reporter.sh  # 状态报告脚本
│
└── body-management-data/          # 用户数据目录（不在版本控制中）
    └── config.json                # API 凭证（gitignore）
```

### Git Ignore 建议

在 `.gitignore` 中添加：
```
body-management-data/config.json
*.log
```

---

## ❓ FAQ

**Q: 如何修改运动员 ID？**  
A: 编辑 `~/.openclaw/workspace/body-management-data/config.json`，重启服务或直接运行命令读取新配置。

**Q: 如何备份我的数据？**  
A: 所有原始数据存储在 intervals.icu 云端，本地仅缓存配置。定期 export intervals.icu 数据即可。

**Q: 不支持某些中国食材怎么办？**  
A: 使用 OpenFoodFacts 无法找到时会自动降级为 AI 估算。欢迎贡献更精确的食谱数据库！

**Q: 能否连接其他平台（如 MyFitnessPal）？**  
A: 目前专注 intervals.icu，后续可扩展到其他平台。开源代码欢迎 PR。

**Q: 如何提高营养估算精度？**  
A: 可以扩展 `estimate_nutrition_item()` 函数，添加更多中文食物的精确数值。

---

## 🔄 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v2.1 | 2026-03-10 | 支持自定义存储路径参数 (`--storage-path`)，自动创建 config/ 和 data/子目录;兼容旧配置位置 |
| v2.0 | 2026-03-09 | 合并 body-management-system，新增自然语言输入 |
| v1.3.2 | 2026-03-09 | bug fix，field names 修正 |
| v1.3.1 | 2026-03-08 | API 响应检查修复，限流保护 |
| v1.3.0 | 2026-03-08 | 纯云营养计算 + 智能估算 |
| v1.2.0 | 2026-03-08 | Zero dependency migration（纯 Bash） |
| v1.1.0 | 2026-03-08 | 配置验证，错误处理增强 |
| v1.0.0 | 2026-03-06 | 初始版本 |

---

## 📚 引用资源

- [Intervals.icu 官方文档](https://github.com/peterattia/IntervalsTrainingApp)
- [OpenFoodFacts API](https://world.openfoodfacts.org/api-factsearch-en)
- [Peloton Analytics（ATS/TSS原理）](https://peaktactics.com/blog/training-stress-scores-explained/)

---

**MIT License** © 2026 leozvc (modded by OpenClaw community)
