#!/bin/bash
# Body Status Reporter v1.3.0 - with custom storage path support
set -euo pipefail

BASE_URL="https://intervals.icu/api/v1"

# Default storage path
DEFAULT_STORAGE_PATH="$HOME/.openclaw/workspace/body-management-data"
STORAGE_PATH="${BODY_MANAGEMENT_DATA:-$DEFAULT_STORAGE_PATH}"
CONFIG_DIR="$STORAGE_PATH/config"
# Check if config exists in legacy location (root of storage) or new location (config subdirectory)
if [[ -f "$STORAGE_PATH/config.json" ]]; then
    CONFIG_FILE="$STORAGE_PATH/config.json"
elif [[ -f "$CONFIG_DIR/config.json" ]]; then
    CONFIG_FILE="$CONFIG_DIR/config.json"
else
    CONFIG_FILE="$CONFIG_DIR/config.json"
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
用法：\$(basename "\$0") [选项]

查询并显示 body management 数据状态报告

选项:
  -s, --storage-path PATH    数据存储根目录 (默认：\$DEFAULT_STORAGE_PATH)
  -h, --help                 显示此帮助信息

环境变量:
  BODY_MANAGEMENT_DATA      覆盖默认存储路径
EOF
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --storage-path|-s) STORAGE_PATH="$2"; CONFIG_DIR="$STORAGE_PATH/config"; CONFIG_FILE="$CONFIG_DIR/config.json"; shift 2;;
        *) echo "Usage: $0 [--storage-path PATH]" >&2; exit 1;;
    esac
done

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR" 2>/dev/null || true

[[ -f "$CONFIG_FILE" ]] || { echo "❌ 配置文件未找到：$CONFIG_FILE" >&2; exit 1; }

ATHLETE_ID=$(jq -r '.intervals_icu.athlete_id' "$CONFIG_FILE")
API_KEY=$(jq -r '.intervals_icu.api_key' "$CONFIG_FILE")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "💪 身体状态报告 - %s\n" "$(date +%Y-%m-%d)"
printf "生成时间：%s\n" "$(date +%H:%M)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "ℹ️  从 intervals.icu 获取数据..."

# Use Basic Auth
AUTH_STR="API_KEY:$API_KEY"
AUTH_B64=$(echo -n "$AUTH_STR" | base64)

SUMMARY_RAW=$(curl -s -H "Authorization: Basic $AUTH_B64" "${BASE_URL}/athlete/${ATHLETE_ID}/athlete-summary")

# The API returns an array, get first element
if [[ $(echo "$SUMMARY_RAW" | jq 'type') == '"array"' ]]; then
    SUMMARY=$(echo "$SUMMARY_RAW" | jq '.[0] // .[] | select(.athlete_id == "'"$ATHLETE_ID"'")' 2>/dev/null || echo "{}")
else
    SUMMARY="$SUMMARY_RAW"
fi

WELLNESS_DATE=$(date +%Y-%m-%d)
WELLNESS_RAW=$(curl -s -H "Authorization: Basic $AUTH_B64" "${BASE_URL}/athlete/${ATHLETE_ID}/wellness/${WELLNESS_DATE}" 2>/dev/null || echo "{}")
if [[ $(echo "$WELLNESS_RAW" | jq 'type') == '"array"' ]]; then
    WELLNESS=$(echo "$WELLNESS_RAW" | jq '.[0] // {}' 2>/dev/null || echo "{}")
else
    WELLNESS="$WELLNESS_RAW"
fi

END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "-7 days" +%Y-%m-%d)
ACTIVITIES_RAW=$(curl -s -H "Authorization: Basic $AUTH_B64" "${BASE_URL}/athlete/${ATHLETE_ID}/activities?oldest=${START_DATE}&newest=${END_DATE}" 2>/dev/null || echo "[]")

# Extract metrics (using new field names)
FORM=$(echo "$SUMMARY" | jq -r 'if .form != null then .form | round else "N/A" end')
FITNESS=$(echo "$SUMMARY" | jq -r 'if .fitness then .fitness | round else "N/A" end')
FATIGUE=$(echo "$SUMMARY" | jq -r 'if .fatigue then .fatigue | round else "N/A" end')
RAMP_RATE=$(echo "$SUMMARY" | jq -r 'if .rampRate then .rampRate | tostring else "N/A" end')

# For TSB, calculate form score based on fitness/fatigue difference
if [[ "$FITNESS" != "N/A" && "$FATIGUE" != "N/A" && -n "$FITNESS" && -n "$FATIGUE" ]]; then
    TSB=$(awk "BEGIN {printf \"%.1f\", $FITNESS - $FATIGUE}")
else
    TSB="N/A"
fi

# Wellness fields: hrv (not avg_hrv), restingHR (not avg_resting_heart_rate_bpm), sleepSecs (not total_sleep_time_s)
SLEEP_SEC=$(echo "$WELLNESS" | jq -r 'if .sleepSecs then .sleepSecs else null end')
if [[ -n "$SLEEP_SEC" && "$SLEEP_SEC" != "null" ]]; then
    SLEEP_MINS=$(awk "BEGIN {printf \"%.0f\", $SLEEP_SEC / 60}")
else
    SLEEP_MINS="N/A"
fi
HRV_AVG=$(echo "$WELLNESS" | jq -r 'if .hrv then .hrv else "N/A" end')
RHR=$(echo "$WELLNESS" | jq -r 'if .restingHR then .restingHR else "N/A" end')

WORKOUT_COUNT=$(echo "$ACTIVITIES_RAW" | jq 'length' 2>/dev/null || echo "0")
WORKOUT_COUNT=${WORKOUT_COUNT:-0}

# Training Load Section
echo ""
echo "═══════ 📊 训练负荷 ═══"
if [[ "$FORM" != "N/A" ]]; then
    FORM_INT=${FORM%.*}
    if [[ "$FORM_INT" -gt 5 ]]; then
        echo "形态评分：🟢 充沛 (${FORM})"
    elif [[ "$FORM_INT" -gt 2 ]]; then
        echo "形态评分：🟡 良好 (${FORM})"
    elif [[ "$FORM_INT" -gt -5 ]]; then
        echo "形态评分：🟠 疲劳 (${FORM})"
    else
        echo "形态评分：🔴 力竭 (${FORM})"
    fi
else
    echo "形态评分：N/A"
fi

echo "体能 (CTL 类似): ${FITNESS} 小时  🐢 长期训练状态"
echo "疲劳 (ATL 类似):  ${FATIGUE} 小时  🐇 当前疲劳水平"
echo "TSB (平衡):      ${TSB}         🎯 恢复与负荷平衡"
echo "RAMP 速率:       ${RAMP_RATE}    📈 功率可持续性"

# Recovery Section
echo ""
echo "══════___ 💤 恢复指标 ═══"
echo "心率变异性 (HRV): ${HRV_AVG} ms  💓 自主神经系统平衡"
echo "静息心率：${RHR} bpm  ❤️ 越低越好"
if [[ "$SLEEP_MINS" != "N/A" && -n "$SLEEP_MINS" ]]; then
    SLEEP_HRS=$(awk "BEGIN {printf \"%.1f\", $SLEEP_MINS / 60}")
    echo "睡眠时长：${SLEEP_HRS}小时 (${SLEEP_MINS}分钟)"
fi

# Recent Activities Section
echo ""
echo "══════___ 🏃 近期活动 ___"
echo "近 7 天训练次数：${WORKOUT_COUNT}"

if [[ "$WORKOUT_COUNT" -gt 0 ]] 2>/dev/null; then
    ACT_LIST="$ACTIVITIES_RAW"
    ACT_TOTAL=$(echo "$ACT_LIST" | jq 'length')
    
    # Show up to 5 activities
    SHOW_LIMIT=5
    if [[ "$ACT_TOTAL" -lt 5 ]]; then
        SHOW_LIMIT=$ACT_TOTAL
    fi
    
    echo ""
    echo "最近 5 次训练:"
    
    for i in $(seq 0 $((SHOW_LIMIT - 1))); do
        idx=$((ACT_TOTAL - SHOW_LIMIT + i))
        ACT_START=$(echo "$ACT_LIST" | jq -r ".[$idx].start_date_local // empty" 2>/dev/null)
        ACT_NAME=$(echo "$ACT_LIST" | jq -r ".[$idx].name // empty" 2>/dev/null)
        ACT_TYPE=$(echo "$ACT_LIST" | jq -r ".[$idx].category // ''" 2>/dev/null)
        if [[ -n "$ACT_START" && -n "$ACT_NAME" ]]; then
            ACT_DATE="${ACT_START%%T*}"
            TYPE_ICON=""
            case "$ACT_TYPE" in
                RIDE) TYPE_ICON="🚴‍♂️" ;;
                RUN) TYPE_ICON="🏃‍♂️" ;;
                SWIM) TYPE_ICON="🏊‍♂️" ;;
                WORKOUT) TYPE_ICON="💪" ;;
                *) TYPE_ICON="📅" ;;
            esac
            echo "  [$ACT_DATE] ${TYPE_ICON} $ACT_NAME"
        fi
    done
    
    echo ""
    echo "统计：近 7 天共 ${ACT_TOTAL} 次训练"
fi

# Recommendation Section
echo ""
echo "══════___ 🎯 训练建议 ═══"
if [[ "$TSB" == "N/A" || -z "$TSB" ]]; then
    echo "⚠️ 数据不足，无法提供建议"
elif awk "BEGIN {exit !($TSB > 5)}" 2>/dev/null; then
    echo "🔥 感觉很棒！是时候提升强度了！🎉"
elif awk "BEGIN {exit !($TSB > 0)}" 2>/dev/null; then
    echo "🙂 恢复良好 - 保持当前训练量💪"
elif awk "BEGIN {exit !($TSB > -10)}" 2>/dev/null; then
    echo "⚠️ 略有疲劳 - 考虑适度强度或主动恢复🤔"
else
    echo "😴 极度疲劳 - 强烈建议休息日😴"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 报告生成成功！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
