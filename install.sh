#!/usr/bin/env bash
# Developed by Mohammad Rameez Imdad (Rameez Scripts)
# WhatsApp: https://wa.me/923435347417 (For Custom Projects)
# YouTube: https://www.youtube.com/@rameezimdad (Subscribe for more!)
# install: curl -fsSL https://raw.githubusercontent.com/rameezimdad/claude-auto-switch/main/install.sh | bash
set -e
REPO="https://github.com/rameezimdad/claude-auto-switch"
DEST="${CLAUDE_AUTO_HOME:-$HOME/.local/share/claude-auto}"
BIN="$HOME/.local/bin"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/claude-auto/accounts"

for c in python3 curl tar; do command -v $c >/dev/null || { echo "Needs $c installed." >&2; exit 1; }; done
command -v claude >/dev/null || echo "Note: Claude Code (claude) is not on PATH yet. Install it first: https://docs.claude.com/en/docs/claude-code"

# local checkout or download
src="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [ ! -f "$src/bin/claude-auto" ]; then
  src=$(mktemp -d)
  curl -fsSL "$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$src" --strip-components=1
fi
mkdir -p "$DEST" "$BIN"
cp -R "$src/bin" "$src/hooks" "$src/lib" "$DEST/"
cp "$src/uninstall.sh" "$DEST/" 2>/dev/null || true
chmod +x "$DEST/bin/claude-auto" "$DEST/hooks/auto_switch.sh"
ln -sf "$DEST/bin/claude-auto" "$BIN/claude-auto"

# accounts list: ~/.claude + any ~/.claude-<n> already on this machine
if [ ! -f "$CONF" ]; then
  mkdir -p "$(dirname "$CONF")"
  { echo "# one Claude Code config folder per line, tried in this order"; echo "$HOME/.claude"
    for d in "$HOME"/.claude-[0-9]*; do [ -d "$d" ] && echo "$d"; done; } > "$CONF"
fi

# StopFailure(rate_limit) hook in every account's settings.json
HOOK="$DEST/hooks/auto_switch.sh" SL="$DEST/lib/statusline.py" CONF="$CONF" python3 - <<'EOF'
import json, os
hook, seen = os.environ['HOOK'], set()
dirs = [l.strip() for l in open(os.environ['CONF']) if l.strip() and not l.startswith('#')]
for d in dirs:
    p = os.path.realpath(os.path.join(os.path.expanduser(d), 'settings.json'))
    if p in seen: continue
    seen.add(p)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    try: s = json.load(open(p))
    except FileNotFoundError: s = {}
    except Exception: print('  skipped (not valid JSON):', p); continue
    changed = False
    lst = s.setdefault('hooks', {}).setdefault('StopFailure', [])
    if not any('auto_switch.sh' in h.get('command', '') for e in lst for h in e.get('hooks', [])):
        lst.append({'matcher': 'rate_limit', 'hooks': [{'type': 'command', 'command': hook, 'timeout': 30}]})
        changed = True; print('  hook added:', p)
    # account status line, only when none is set (an existing one is kept)
    if not s.get('statusLine'):
        s['statusLine'] = {'type': 'command', 'command': 'python3 ' + os.environ['SL']}
        changed = True; print('  status line added:', p)
    if changed:
        json.dump(s, open(p, 'w'), indent=2); open(p, 'a').write('\n')
EOF

echo
echo "claude-auto installed."
case ":$PATH:" in *":$BIN:"*) ;; *) echo "Add to your shell profile:  export PATH=\"\$HOME/.local/bin:\$PATH\"";; esac
echo "Accounts file: $CONF"
echo
echo "Next:"
echo "  claude-auto add        # add your next Claude subscription (2, 3, 4 ...)"
echo "  claude-auto status     # usage of every account"
echo "  claude-auto            # start Claude Code with auto switching"
