#!/bin/bash

set -euo pipefail

# config ──────────────────────────────────────────────────────────────────────
SHOW_TIMEZONE=false
TTL="${CC_CACHE_TTL:-60}"
LOCK_TTL=30
API_TIMEOUT=5
# ──────────────────────────────────────────────────────────────────────────────

CACHE_DIR="$HOME/.cache"
CACHE="$CACHE_DIR/cc-usage.txt"
LOCK="$CACHE_DIR/cc-usage.lock"
TZ_NAME=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || echo "UTC")

mkdir -p "$CACHE_DIR"

fallback() {
    if [[ -f "$CACHE" ]]; then cat "$CACHE"; else printf '%s' "$1"; fi
    exit 0
}

if [[ -f "$CACHE" ]]; then
    age=$(( $(date +%s) - $(stat -f '%m' "$CACHE" 2>/dev/null || echo 0) ))
    (( age < TTL )) && cat "$CACHE" && exit 0
fi

if [[ -f "$LOCK" && -f "$CACHE" ]]; then
    age=$(( $(date +%s) - $(stat -f '%m' "$LOCK" 2>/dev/null || echo 0) ))
    (( age < LOCK_TTL )) && fallback ""
fi
touch "$LOCK"

# credentials ─────────────────────────────────────────────────────────────────
creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) \
    || { echo "[No creds]"; exit 1; }
token=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.accessToken // empty') \
    || { echo "[Bad token]"; exit 1; }
[[ -z "$token" ]] && echo "[Bad token]" && exit 1

# fetch ───────────────────────────────────────────────────────────────────────
resp=$(curl -sf --max-time "$API_TIMEOUT" \
    "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null) || true

[[ -z "$resp" ]] && fallback "[Timeout]"

# parse ───────────────────────────────────────────────────────────────────────
read -r session session_reset weekly weekly_reset \
         extra_enabled extra_used extra_limit extra_pct extra_currency \
    < <(printf '%s' "$resp" | jq -r '[
        .five_hour.utilization,
        .five_hour.resets_at,
        .seven_day.utilization,
        .seven_day.resets_at,
        (.extra_usage.is_enabled // false),
        (.extra_usage.used_credits // ""),
        (.extra_usage.monthly_limit // ""),
        (.extra_usage.utilization // ""),
        (.extra_usage.currency // "")
    ] | @tsv')

[[ -z "$session" || -z "$weekly" ]] && fallback "[Error]"

# helpers ─────────────────────────────────────────────────────────────────────
fmt_reset() {
    local raw="$1"
    local ts="${raw%%.*}"; ts="${ts%+*}"

    local epoch
    epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$ts" "+%s" 2>/dev/null) \
        || { echo "Resets ?"; return; }

    local time_str today reset_day
    time_str=$(TZ="$TZ_NAME" date -r "$epoch" "+%l:%M%p" | tr 'A-Z' 'a-z' | sed 's/^ //')
    today=$(date "+%Y-%m-%d")
    reset_day=$(TZ="$TZ_NAME" date -r "$epoch" "+%Y-%m-%d")

    local tz_suffix=""
    [[ "$SHOW_TIMEZONE" == "true" ]] && tz_suffix=" - $TZ_NAME"

    if [[ "$reset_day" == "$today" ]]; then
        printf "Resets %s%s" "$time_str" "$tz_suffix"
    else
        local date_str
        date_str=$(TZ="$TZ_NAME" date -r "$epoch" "+%b %-d")
        printf "Resets %s at %s%s" "$date_str" "$time_str" "$tz_suffix"
    fi
}

cents_to_decimal() { printf "%.2f" "$(bc -l <<< "$1 / 100")"; }

# output ──────────────────────────────────────────────────────────────────────
session_pct=$(printf "%.0f" "$session")
weekly_pct=$(printf "%.0f" "$weekly")
session_fmt=$(fmt_reset "$session_reset")
weekly_fmt=$(fmt_reset "$weekly_reset")

extra_str=""
if [[ "$extra_enabled" == "true" && -n "$extra_pct" ]]; then
    extra_str=" | extra: $(printf "%.0f" "$extra_pct")% ($(cents_to_decimal "$extra_used")/$(cents_to_decimal "$extra_limit") $extra_currency)"
fi

tmp=$(mktemp "$CACHE_DIR/.cc-usage.XXXXXX")

if [[ "${1:-}" == "--bold" ]]; then
    B=$'\033[1m'; R=$'\033[0m'
    printf "session: %s%s%%%s (%s) | week: %s%s%%%s (%s)%s\n" \
        "$B" "$session_pct" "$R" "$session_fmt" \
        "$B" "$weekly_pct" "$R" "$weekly_fmt" \
        "$extra_str" | tee "$tmp"
else
    printf "session: %s%% (%s) | week: %s%% (%s)%s\n" \
        "$session_pct" "$session_fmt" \
        "$weekly_pct" "$weekly_fmt" \
        "$extra_str" | tee "$tmp"
fi

mv "$tmp" "$CACHE"
