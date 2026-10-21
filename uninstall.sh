#!/usr/bin/env bash
# Developed by Mohammad Rameez Imdad (Rameez Scripts)
# WhatsApp: https://wa.me/923435347417 (For Custom Projects)
# YouTube: https://www.youtube.com/@rameezimdad (Subscribe for more!)
# removes claude-auto + its hook. Account folders and logins stay.
DEST="${CLAUDE_AUTO_HOME:-$HOME/.local/share/claude-auto}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/claude-auto/accounts"
[ -f "$CONF" ] && CONF="$CONF" python3 - <<'EOF'
import json, os
seen = set()
for d in [l.strip() for l in open(os.environ['CONF']) if l.strip() and not l.startswith('#')]:
    p = os.path.realpath(os.path.join(os.path.expanduser(d), 'settings.json'))
    if p in seen or not os.path.exists(p): continue
    seen.add(p)
    s = json.load(open(p)); h = s.get('hooks', {})
    lst = [e for e in h.get('StopFailure', []) if not any('auto_switch.sh' in x.get('command', '') for x in e.get('hooks', []))]
    if lst: h['StopFailure'] = lst
    else: h.pop('StopFailure', None)
    if not h: s.pop('hooks', None)
    if 'claude-auto/lib/statusline.py' in (s.get('statusLine') or {}).get('command', ''): s.pop('statusLine')
    json.dump(s, open(p, 'w'), indent=2); open(p, 'a').write('\n')
    print('  hook removed:', p)
EOF
rm -f "$HOME/.local/bin/claude-auto"
rm -rf "$DEST"
echo "claude-auto removed. Accounts file kept: $CONF"
