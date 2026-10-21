"""
Developed by Mohammad Rameez Imdad (Rameez Scripts)
WhatsApp: https://wa.me/923435347417 (For Custom Projects)
YouTube: https://www.youtube.com/@rameezimdad (Subscribe for more!)
"""
# Claude Code status line: account n · email · % used · model
import json, os, sys, time, subprocess

here = os.path.dirname(os.path.abspath(__file__))
home = os.path.expanduser('~')
main = os.path.join(home, '.claude')
cfg = os.environ.get('CLAUDE_CONFIG_DIR', '').rstrip('/') or main
try:
    inp = json.load(sys.stdin)
except Exception:
    inp = {}


def email_of(d):
    # default dir keeps its login in ~/.claude.json
    f = os.path.join(home, '.claude.json') if d == main and not os.environ.get('CLAUDE_CONFIG_DIR') else os.path.join(d, '.claude.json')
    try:
        return json.load(open(f)).get('oauthAccount', {}).get('emailAddress') or ''
    except Exception:
        return ''


def slot(d):
    conf = os.path.join(os.environ.get('XDG_CONFIG_HOME', os.path.join(home, '.config')), 'claude-auto', 'accounts')
    try:
        dirs = [os.path.expanduser(l.split('#')[0].strip()).rstrip('/') for l in open(conf) if l.split('#')[0].strip()]
        return dirs.index(d) + 1
    except Exception:
        return 1 if d == main else None


def usage(d):
    # cached 60 s so the bar stays fast
    cache = os.path.join(os.environ.get('TMPDIR', '/tmp'), 'claude-auto-usage-%d-%s' % (os.getuid(), d.replace('/', '_')))
    try:
        if time.time() - os.path.getmtime(cache) < 60:
            return open(cache).read().strip()
    except OSError:
        pass
    try:
        out = subprocess.run([sys.executable, os.path.join(here, 'usage.py'), d], capture_output=True, text=True, timeout=8).stdout.split()
        val = out[0] if out else ''
    except Exception:
        val = ''
    try:
        open(cache, 'w').write(val)
    except OSError:
        pass
    return val


n, mail, pct = slot(cfg), email_of(cfg), usage(cfg)
parts = ['account %s' % n if n else os.path.basename(cfg)]
if mail:
    parts.append(mail)
if pct.isdigit():
    parts.append('%s%% used' % pct)
model = (inp.get('model') or {}).get('display_name')
if model:
    parts.append(model)
print(' · '.join(parts))
