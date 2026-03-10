#!/bin/bash
# Meal to Intervals v2.1 - Unified Fitness Assistant Edition (with custom storage path)
set -euo pipefail

# Exit codes convention
EXIT_SUCCESS=0
EXIT_CONFIG_ERROR=1
EXIT_INPUT_ERROR=2
EXIT_API_ERROR=3

BASE_URL="https://intervals.icu/api/v1"

# Default storage path
DEFAULT_STORAGE_PATH="$HOME/.openclaw/workspace/body-management-data"
STORAGE_PATH="${BODY_MANAGEMENT_DATA:-$DEFAULT_STORAGE_PATH}"
CONFIG_DIR="$STORAGE_PATH/config"
DATA_DIR="$STORAGE_PATH/data"
CONFIG_FILE=""

show_help() {
    cat << EOF
用法：$(basename "$0") [选项]

用自动营养计算将餐食记录到 intervals.icu

选项:
  -s, --storage-path PATH    数据存储根目录 (默认：$DEFAULT_STORAGE_PATH)
                             在此目录下自动创建 config/ 和 data/ 子目录
  -i, --input FILE           输入包含餐食数据的 JSON 文件
  -t, --text TEXT            直接文本输入（自然语言）
  -n, --dry-run              仅计算但不上传到 API
  -c, --health-check         检查所有依赖项是否正常工作
  -h, --help                 显示此帮助信息

示例:
  $(basename "$0") --input meal.json
  $(basename "$0") --text "300g 牛肉和 200 克米饭"
  $(basename "$0") --storage-path /custom/path --text "早餐两个鸡蛋"
  $(basename "$0") --health-check

环境变量:
  BODY_MANAGEMENT_DATA      覆盖默认存储路径
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit $EXIT_SUCCESS
fi

# Parse arguments
HEALTH_CHECK=false
INPUT="" DRY_RUN=false INPUT_TEXT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --health-check|-c) 
            HEALTH_CHECK=true; shift;;
        --storage-path|-s) 
            STORAGE_PATH="$2"; CONFIG_DIR="$STORAGE_PATH/config"; DATA_DIR="$STORAGE_PATH/data"; 
            # Resolve config file path
            if [[ -f "$STORAGE_PATH/config.json" ]]; then
                CONFIG_FILE="$STORAGE_PATH/config.json"
            elif [[ -f "$CONFIG_DIR/config.json" ]]; then
                CONFIG_FILE="$CONFIG_DIR/config.json"
            else
                CONFIG_FILE="$CONFIG_DIR/config.json"
            fi; mkdir -p "$CONFIG_DIR" "$DATA_DIR" 2>/dev/null || true; shift 2;;
        --input|-i) INPUT="$2"; shift 2;;
        --text|-t) INPUT_TEXT="$2"; shift 2;;
        --dry-run|-n) DRY_RUN=true; shift;;
        *) echo "Usage: $0 [--storage-path PATH] [--input FILE | --text TEXT] [--dry-run]" >&2; exit $EXIT_INPUT_ERROR;;
    esac
done

# If no config specified yet, use default resolution
if [[ -z "$CONFIG_FILE" ]]; then
    if [[ -f "$STORAGE_PATH/config.json" ]]; then
        CONFIG_FILE="$STORAGE_PATH/config.json"
    elif [[ -f "$CONFIG_DIR/config.json" ]]; then
        CONFIG_FILE="$CONFIG_DIR/config.json"
    else
        CONFIG_FILE="$CONFIG_DIR/config.json"
    fi
fi

if [[ "$HEALTH_CHECK" == "true" ]]; then
    echo "🏥 健康检查开始..."
    curl -sf "https://world.openfoodfacts.org/" >/dev/null && echo "✅ OpenFoodFacts OK" || echo "❌ OpenFoodFacts DOWN"
    jq --version >/dev/null && echo "✅ jq installed" || echo "❌ jq missing"
    [[ -f "$CONFIG_FILE" ]] && echo "✅ Config exists at: $CONFIG_FILE" || echo "❌ Config missing at $CONFIG_FILE"
    [[ -r "$CONFIG_FILE" ]] && echo "✅ Config readable" || echo "⚠️ Config not readable"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        ATHLETE_ID=$(jq -r '.intervals_icu.athlete_id // empty' "$CONFIG_FILE")
        API_KEY=$(jq -r '.intervals_icu.api_key // empty' "$CONFIG_FILE")
        
        if [[ -n "$ATHLETE_ID" && -n "$API_KEY" ]]; then
            echo "✅ Intervals credentials configured"
            RESP=$(curl -s -m 5 -X GET "${BASE_URL}/athlete/${ATHLETE_ID}" -H "Authorization: Basic $(echo -n "API_KEY:${API_KEY}" | base64)")
            if echo "$RESP" | jq -e '.id' >/dev/null 2>&1; then
                echo "✅ Intervals API connection successful (${ATHLETE_ID})"
            else
                echo "❌ Intervals API authentication failed"
            fi
        else
            echo "⚠️  Missing athlete_id or api_key in config"
        fi
    fi
    exit $EXIT_SUCCESS
fi

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR" "$DATA_DIR" 2>/dev/null || true

[[ -f "$CONFIG_FILE" ]] || { echo "❌ 配置文件未找到：$CONFIG_FILE" >&2; exit $EXIT_CONFIG_ERROR; }

ATHLETE_ID=$(jq -r '.intervals_icu.athlete_id' "$CONFIG_FILE")
API_KEY=$(jq -r '.intervals_icu.api_key' "$CONFIG_FILE")

detect_meal_type() {
    local text="$1"
    local lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    if echo "$lower_text" | grep -qE "(早餐|早饭|早点|早歺|早點)"; then
        echo "早餐"
    elif echo "$lower_text" | grep -qE "(午餐 | 午饭 | 中饭)"; then
        echo "午餐"
    elif echo "$lower_text" | grep -qE "(晚餐 | 晚饭 | 夜宵 | 深夜)"; then
        echo "晚餐"
    elif echo "$lower_text" | grep -qE "(加餐 | 零食 | 点心)"; then
        echo "加餐"
    else
        echo "餐食"
    fi
}

estimate_nutrition_item() {
    local name="$1"
    local grams="${2:-100}"
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    
    # Meat/Protein category
    if echo "$name_lower" | grep -qE "(牛 | 羊 | 猪 | 鸡 | 鸭 | 鱼 | 肉 | 虾 | 蟹 | 蛋)"; then
        if echo "$name_lower" | grep -qiE "(瘦 | 腱子 | 胸肉)"; then
            printf "%.2f %.2f %.2f %.2f\n" 150 25 5 0
            return
        elif echo "$name_lower" | grep -qiE "(肥 | 五花肉 | 肋排)"; then
            printf "%.2f %.2f %.2f %.2f\n" 350 18 30 0
            return
        else
            printf "%.2f %.2f %.2f %.2f\n" 200 22 12 0
            return
        fi
    fi
    
    # Grain/Starch category
    if echo "$name_lower" | grep -qE "(米 | 面 | 面包 | 饼 | 馒头 | 面条 | 饺子 | 包子 | 粉)"; then
        if echo "$name_lower" | grep -qiE "(饭 | 大米)"; then
            printf "%.2f %.2f %.2f %.2f\n" 130 2.7 0.3 28
            return
        elif echo "$name_lower" | grep -qiE "(饺子 | 包子 | 馅饼)"; then
            printf "%.2f %.2f %.2f %.2f\n" 220 9 7 30
            return
        elif echo "$name_lower" | grep -qiE "(面包)"; then
            if echo "$name_lower" | grep -qiE "(全麦)"; then
                printf "%.2f %.2f %.2f %.2f\n" 250 10.7 3.6 43
            else
                printf "%.2f %.2f %.2f %.2f\n" 270 9 3 55
            fi
            return
        elif echo "$name_lower" | grep -qiE "(面)"; then
            printf "%.2f %.2f %.2f %.2f\n" 110 4 1 25
            return
        else
            printf "%.2f %.2f %.2f %.2f\n" 350 8 15 55
            return
        fi
    fi
    
    # Vegetable category
    if echo "$name_lower" | grep -qE "(菜 | 瓜 | 椒 | 茄 | 豆 | 葱 | 蒜 | 姜)"; then
        printf "%.2f %.2f %.2f %.2f\n" 30 2 0.5 6
        return
    fi
    
    # Fruit category
    if echo "$name_lower" | grep -qE "(果 | 蕉 | 柑 | 橘 | 梨 | 橙)"; then
        printf "%.2f %.2f %.2f %.2f\n" 60 0.5 0.2 15
        return
    fi
    
    # Dairy category
    if echo "$name_lower" | grep -qE "(奶 | 酪 | 酸奶 | 乳)"; then
        printf "%.2f %.2f %.2f %.2f\n" 50 3 2.5 5
        return
    fi
    
    # Oil/Fat category
    if echo "$name_lower" | grep -qE "(油 | 脂 | 黄油)"; then
        printf "%.2f %.2f %.2f %.2f\n" 900 0 100 0
        return
    fi
    
    # Default estimate
    printf "%.2f %.2f %.2f %.2f\n" 150 15 8 10
}

parse_text_to_items() {
    local text="$1"
    local items_json="[]"
    
    local parsed=$(echo "$text" | perl -pe 's/\s+(?=\d+[g 克]?\s*[a-zA-Z\u4e00-\u9fa5]+)/\n/g')
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        local grams=100 name="$line"
        
        if [[ "$line" =~ ([0-9]+)[g 克]?[,\s]?([^\，,]+) ]]; then
            grams="${BASH_REMATCH[1]}"
            name="${BASH_REMATCH[2]}"
            
            name=$(echo "$name" | sed 's/[个片碗杯两条袋包]/ /g')
            name=$(echo "$name" | xargs)
        elif [[ "$line" =~ ([0-9]+) ]]; then
            grams="${BASH_REMATCH[1]}"
        fi
        
        [[ ${#name} -lt 2 ]] && continue
        
        read cal prot fat carbs <<< $(estimate_nutrition_item "$name" "$grams")
        
        items_json=$(echo "$items_json" | jq --arg name "$name" \
            --argjson grams "$grams" \
            --argjson cal "$cal" \
            --argjson prot "$prot" \
            --argjson fat "$fat" \
            --argjson carbs "$carbs" \
            '. + [{"name": $name, "grams": $grams, "caloriesKcal": $cal, "proteinG": $prot, "fatG": $fat, "carbsG": $carbs, "source": "SmartEstimate"}]')
    done <<< "$parsed"
    
    echo "$items_json"
}

process_text_input() {
    local text="$1"
    local current_time=$(date "+%Y-%m-%dT%H:%M")
    local meal_name=$(detect_meal_type "$text")
    
    local items_json=$(parse_text_to_items "$text")
    
    jq -n \
        --arg name "$meal_name" \
        --arg time "$current_time" \
        --argjson items "$items_json" \
        '{mealName: $name, mealTime: $time, items: $items}'
}

# Main processing
if [[ -n "$INPUT" && -f "$INPUT" ]]; then
    echo "ℹ️  处理餐食文件：$INPUT"
    for field in "meal_name" "meal_time" "items"; do
        if ! jq -e ".$field" "$INPUT" >/dev/null 2>&1; then
            echo "❌ 缺少必需字段：$field" >&2
            exit $EXIT_INPUT_ERROR
        fi
    done
    RESULT="$(<"$INPUT")"
elif [[ -n "$INPUT_TEXT" ]]; then
    echo "ℹ️  处理文本输入：$INPUT_TEXT"
    RESULT=$(process_text_input "$INPUT_TEXT")
else
    echo "❌ 请提供 --input 文件或 --text 文本" >&2
    exit $EXIT_INPUT_ERROR
fi

TOTAL_CAL=$(echo "$RESULT" | jq '[.items[].caloriesKcal] | add // 0')
TOTAL_PROT=$(echo "$RESULT" | jq '[.items[].proteinG] | add // 0')  
TOTAL_FAT=$(echo "$RESULT" | jq '[.items[].fatG] | add // 0')
TOTAL_CARBS=$(echo "$RESULT" | jq '[.items[].carbsG] | add // 0')
MEAL_NAME=$(echo "$RESULT" | jq -r '.mealName // .meal_name // "餐食"')
MEAL_TIME=$(echo "$RESULT" | jq -r '.mealTime // .meal_time // ""')
ITEMS_JSON=$(echo "$RESULT" | jq -c '.items')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🍽️  餐食汇总：$MEAL_NAME"
echo "时间：$MEAL_TIME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 营养素总计:"
echo "   🔥 热量：${TOTAL_CAL} kcal"
echo "   💪 蛋白质：${TOTAL_PROT} g"
echo "   🥑 脂肪：${TOTAL_FAT} g"
echo "   🍞 碳水：${TOTAL_CARBS} g"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "✅ 干跑完成！未上传到 intervals.icu"
    exit $EXIT_SUCCESS
fi

echo ""
echo "📝 写入 intervals.icu..."

EVENT_DESC="🍽 $MEAL_NAME\n热量：$TOTAL_CAL kcal\n蛋白质：$TOTAL_PROT g\n脂肪：$TOTAL_FAT g\n碳水：$TOTAL_CARBS g"
AUTH_B64=$(echo -n "API_KEY:$API_KEY" | base64)

EVENT_RESP_RAW=$(curl -s -X POST \
    -H "Authorization: Basic $AUTH_B64" \
    -H "Content-Type: application/json" \
    -d "{\"category\":\"NOTE\",\"start_date_local\":\"$MEAL_TIME\",\"name\":\"🍽 $MEAL_NAME\",\"description\":\"${EVENT_DESC}\"}" \
    "${BASE_URL}/athlete/${ATHLETE_ID}/events")

if echo "$EVENT_RESP_RAW" | jq -e '.id' >/dev/null 2>&1; then
    echo "✅ 事件记录成功！（ID: $(echo "$EVENT_RESP_RAW" | jq -r '.id')）"
elif echo "$EVENT_RESP_RAW" | jq -e '.error // .errors' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$EVENT_RESP_RAW" | jq -r '.error // .errors // "Unknown error"')
    echo "❌ 事件创建失败：$ERROR_MSG" >&2
    exit $EXIT_API_ERROR
else
    echo "✅ 事件记录成功！"
fi

DATE_KEY="${MEAL_TIME%%T*}"
echo "💪 更新健康数据 ($DATE_KEY)..."
WELLNESS_RESP=$(curl -s -X PUT \
    -H "Authorization: Basic $AUTH_B64" \
    -H "Content-Type: application/json" \
    -d "{\"kcalConsumed\":$TOTAL_CAL,\"protein\":$TOTAL_PROT,\"fatTotal\":$TOTAL_FAT,\"carbohydrates\":$TOTAL_CARBS}" \
    "${BASE_URL}/athlete/${ATHLETE_ID}/wellness/${DATE_KEY}")

if echo "$WELLNESS_RESP" | jq -e 'has("error") or has("errors") or (.status != "success")' >/dev/null 2>&1; then
    echo "⚠️  健康数据更新：$(echo "$WELLNESS_RESP" | jq -r '.error // .errors // "unknown"')"
else
    echo "✅ 健康数据同步成功！"
fi

exit $EXIT_SUCCESS
