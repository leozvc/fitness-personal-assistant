# 🏋️ Fitness Personal Assistant

> ⚡ **OpenClaw 一键安装** | ⚠️ **需配置 API Key** | [Intervals.icu 注册](https://intervals.icu/register)

一体化健身追踪系统，基于 Python 实现，帮你管理饮食记录和身体状态，自动同步到 [intervals.icu](https://intervals.icu)。

![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Language](https://img.shields.io/badge/language-Python-blue.svg)

---

## ⚡ OpenClaw 超级简洁安装

如果你使用 [OpenClaw](https://openclaw.ai)，只需一条命令：

```bash
# 安装技能
openclaw skills install fitness-personal-assistant

# 启用技能
openclaw skills enable fitness-personal-assistant

# 配置 API Key（只需一次）
mkdir -p ~/.openclaw/workspace/body-management-data
cat > ~/.openclaw/workspace/body-management-data/config.json << EOF
{
  "intervals_icu": {
    "api_key": "YOUR_API_KEY",
    "athlete_id": "iYOUR_ID"
  }
}
EOF
chmod 600 ~/.openclaw/workspace/body-management-data/config.json
```

### 🎯 在 OpenClaw 中使用

安装后，直接在聊天中使用：

```
# 查询身体状态（自动显示职业级完整报告）
查看我的身体状态

# 记录饮食
早餐：250ml 牛奶和两个鸡蛋
午餐：300g 牛肉和 200 克米饭

# 查看完整分析
查看职业级分析报告
```

---

## 🚀 独立使用（不使用 OpenClaw）

### 环境要求

- ✅ macOS / Linux
- ✅ Python 3.8+
- ✅ `requests` 库
- ✅ intervals.icu API Key

### ⚙️ 配置步骤

#### 第一步：准备 intervals.icu 账号

如果没有账号，先注册：[https://intervals.icu/register](https://intervals.icu/register)

#### 第二步：获取 API 凭证

1. 登录 [intervals.icu](https://intervals.icu)
2. 进入 **Settings → API Keys**
3. 复制你的 `Athlete ID` (格式如 `i206099`) 和 `API Key`

#### 第三步：本地配置

```bash
# 创建数据目录
mkdir -p ~/.openclaw/workspace/body-management-data

# 创建配置文件
cat > ~/.openclaw/workspace/body-management-data/config.json << EOF
{
  "intervals_icu": {
    "api_key": "YOUR_API_KEY",
    "athlete_id": "iYOUR_ID"
  }
}
EOF

# 设置文件权限
chmod 600 ~/.openclaw/workspace/body-management-data/config.json
```

#### 第四步：验证安装

```bash
cd ~/.openclaw/workspace/skills/fitness-personal-assistant/scripts
python3 intervals_api_client.py
```

预期输出:
```
✅ API 连接成功
📊 获取运动员摘要...
  体能 (fitness): 19.74
  疲劳 (fatigue): 30.43
  形态 (form/TSB): -10.69
```

---

## 🎯 核心功能

### 🍽️ 智能饮食记录

用自然语言记录餐食，系统自动计算营养并同步到 intervals.icu:

```bash
# 最简单的用法
python3 meal-to-intervals.py --text "早餐两个鸡蛋一片全麦面包"

# 混合多种食物
python3 meal-to-intervals.py --text "午餐鸡胸肉 200g 配西兰花"

# 禁用 OpenFoodFacts API（国内网络慢）
python3 meal-to-intervals.py --text "晚餐一碗米饭" --no-off

# 交互式询问（无法识别的食物）
python3 meal-to-intervals.py --text "吃了些螺蛳粉" --interactive
```

**支持的食物识别:**
- 中文自然语言："250ml 牛奶"、"300g 牛肉"、"两个鸡蛋"
- 自动营养估算：基于中文食物规则库 + OpenFoodFacts API
- 多餐次识别：自动判断早餐/午餐/晚餐

### 💪 身体状态查询

查看你的训练负荷和恢复情况:

```bash
# 基础报告（快速查看）
python3 body-status-reporter.py

# 职业级完整分析（默认）
python3 body-status-reporter.py --pro
```

**输出包含:**
- 训练负荷：CTL/ATL/TSB
- 恢复指标：HRV、静息心率、睡眠
- 近期训练：详细记录
- 训练建议：基于 TSB 的强度建议

### 🏆 职业级分析

完整的职业运动员级别分析报告：

```bash
python3 pro_athlete_analytics.py
```

**报告包含:**
- 📊 竞技状态准备度评分（0-100 分）
- 📈 运动表现预测（基于运动类型）
- 📋 推荐训练计划（7 天详细安排）
- 🍽️ 营养摄入目标（减脂/增肌自动计算）

---

## 📊 使用场景

### 减脂期饮食追踪

```bash
# 记录三餐
python3 meal-to-intervals.py --text "早餐一杯牛奶两个鸡蛋" --no-off
python3 meal-to-intervals.py --text "午餐鸡胸肉 200g 配大量蔬菜" --no-off
python3 meal-to-intervals.py --text "晚餐一份烤鱼肉" --no-off

# 查看营养摄入是否达标
python3 pro_athlete_analytics.py | grep -A 20 "营养摄入目标"
```

### 训练状态监控

```bash
# 每天查看身体状态
python3 body-status-reporter.py

# 根据 TSB 决定训练强度
# TSB > 10: 高强度训练
# TSB 0-10: 中等强度
# TSB < 0: 恢复训练
```

### 比赛/测试准备

```bash
# 查看最佳表现窗口
python3 pro_athlete_analytics.py | grep "最佳表现窗口"

# 根据训练计划执行
python3 pro_athlete_analytics.py | grep -A 10 "推荐训练计划"
```

---

## 🔧 高级用法

### JSON 格式输入

创建 `meal.json`:

```json
{
  "meal_name": "午餐",
  "meal_time": "2026-03-10T12:30:00+08:00",
  "notes": "公司食堂",
  "items": [
    {"name": "鸡胸肉", "grams": 200, "calories": 220, "protein_g": 46},
    {"name": "西兰花", "grams": 150, "calories": 52, "protein_g": 4.5}
  ]
}
```

执行：

```bash
python3 meal-to-intervals.py --input meal.json
```

### 干跑模式（测试）

不上传数据，只计算营养：

```bash
python3 meal-to-intervals.py --text "300g 牛肉" --dry-run
```

### 自定义存储路径

```bash
export BODY_MANAGEMENT_DATA=/custom/data/path
python3 meal-to-intervals.py --text "早餐"
```

---

## 🛠️ 技术细节

### 架构设计

```
scripts/
├── intervals_api_client.py    # Intervals.icu API 客户端
├── nutrition_estimator.py     # 营养估算引擎
│   ├── OpenFoodFacts API
│   └── 中文食物规则库 (150+ 种)
├── meal-to-intervals.py       # 饮食记录 + 同步
├── body-status-reporter.py    # 身体状态报告
└── pro_athlete_analytics.py   # 职业级分析
    ├── 竞技状态评分
    ├── 运动表现预测
    ├── 训练计划生成
    └── 营养目标计算
```

### 依赖清单

| 依赖 | 用途 | 来源 |
|------|------|------|
| `requests` | HTTP 请求 | pip install requests |
| Python 3.8+ | 运行环境 | 系统自带 |

### 外部 API

- **OpenFoodFacts**: [world.openfoodfacts.org/api](https://world.openfoodfacts.org/api-factsearch-en)
- **Intervals.icu**: [api.intervals.icu](https://intervals.icu/api-docs)

---

## ⚠️ 注意事项

1. **数据隐私**: 所有健康数据存储在 intervals.icu 云端，本地仅保存配置文件
2. **API 限流**: OpenFoodFacts 有速率限制，国内访问可能超时（可用 `--no-off` 禁用）
3. **中文支持**: 内置 150+ 种常见中餐食物规则
4. **错误降级**: API 失败时自动切换到规则估算

---

## 📚 方法论来源

- **TrainingPeaks TSS 系统** - CTL/ATL/TSB 计算
- **TRIMP 训练负荷理论** - Banister 模型
- **心率区间训练** - 5 区功率/心率模型
- **HRV 恢复监测** - 自主神经系统评估

---

## 🔄 版本历史

### v3.0.0 (2026-03-10)
- 🎉 Python 完整重构
- ✨ 职业级分析系统上线
- ✨ 运动表现预测
- ✨ 训练计划生成
- ✨ 营养目标计算

### v2.1.0 (2026-03-09)
- 合并 body-management-system
- 新增自然语言输入

### v2.0.0 (2026-03-08)
- 纯云营养计算 + 智能估算

---

## 📄 License

MIT License

---

## 🙏 Credits

- 概念灵感：[Peloton Analytics - TSS/ATS](https://peaktactics.com/blog/training-stress-scores-explained/)
- 数据源：[OpenFoodFacts Community](https://world.openfoodfacts.org/)
- 平台：[intervals.icu](https://intervals.icu)

---

**Made with ❤️ by OpenClaw Community**
