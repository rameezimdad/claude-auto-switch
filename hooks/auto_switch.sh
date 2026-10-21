#!/usr/bin/env bash
# Developed by Mohammad Rameez Imdad (Rameez Scripts)
# WhatsApp: https://wa.me/923435347417 (For Custom Projects)
# YouTube: https://www.youtube.com/@rameezimdad (Subscribe for more!)
# StopFailure(rate_limit) hook -> hand the session to claude-auto for the next account
[ -n "$CLAUDE_AUTO_FLAG" ] && [ -n "$CLAUDE_AUTO_PID" ] || exit 0   # only under claude-auto
sid=$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("session_id",""))')
[ -n "$sid" ] || exit 0
here="$(cd "$(dirname "$0")/.." && pwd)"
read -r pct _ < <(python3 "$here/lib/usage.py" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")
# short 429 burst while the plan still has room -> stay
[[ "$pct" =~ ^[0-9]+$ ]] && [ "$pct" -lt "${CLAUDE_AUTO_MAX:-95}" ] && exit 0
echo "$sid" > "$CLAUDE_AUTO_FLAG"
# walk up to the claude process started by claude-auto and close it
p=$$
while [ -n "$p" ] && [ "$p" -gt 1 ]; do
  pp=$(ps -o ppid= -p "$p" | tr -d ' ')
  [ "$pp" = "$CLAUDE_AUTO_PID" ] && { kill -TERM "$p"; exit 0; }
  p=$pp
done
