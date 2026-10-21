"""
Developed by Mohammad Rameez Imdad (Rameez Scripts)
WhatsApp: https://wa.me/923435347417 (For Custom Projects)
YouTube: https://www.youtube.com/@rameezimdad (Subscribe for more!)
"""
# usage.py <config_dir>  ->  "<max % used> <reset epoch>" | "NOLOGIN" | "UNKNOWN"
import json, os, sys, hashlib, subprocess, urllib.request
from datetime import datetime

d = os.path.expanduser(sys.argv[1]).rstrip('/')
default = os.path.expanduser('~/.claude')


def token():
    # linux / wsl: plain file
    try:
        return json.load(open(os.path.join(d, '.credentials.json')))['claudeAiOauth']['accessToken']
    except Exception:
        pass
    if sys.platform != 'darwin':
        return None
    # macos keychain, suffix = sha256(config dir)[:8] for non-default dirs
    svc = 'Claude Code-credentials' + ('' if d == default else '-' + hashlib.sha256(d.encode()).hexdigest()[:8])
    try:
        raw = subprocess.run(['security', 'find-generic-password', '-a', os.environ.get('USER', ''), '-s', svc, '-w'],
                             capture_output=True, text=True, timeout=10).stdout.strip()
        return json.loads(raw)['claudeAiOauth']['accessToken']
    except Exception:
        return None


tok = token()
if not tok:
    print('NOLOGIN'); sys.exit()
req = urllib.request.Request('https://api.anthropic.com/api/oauth/usage', headers={
    'Authorization': 'Bearer ' + tok, 'anthropic-beta': 'oauth-2025-04-20'})
try:
    data = json.load(urllib.request.urlopen(req, timeout=10))
except Exception:
    print('UNKNOWN'); sys.exit()  # expired token / offline

# plan windows only, skip paid extra-usage buckets
wins = [v for v in data.values() if isinstance(v, dict) and v.get('utilization') is not None and v.get('limit_dollars') is None]
if not wins:
    print('0 0'); sys.exit()
top = max(wins, key=lambda w: w['utilization'])
try:
    reset = int(datetime.fromisoformat(top['resets_at']).timestamp())
except Exception:
    reset = 0
print(int(top['utilization']), reset)
