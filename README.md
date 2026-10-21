# Claude Code Auto Account Switch - Never Stop at the Usage Limit

<!--
Developed by Mohammad Rameez Imdad (Rameez Scripts)
WhatsApp: https://wa.me/923435347417 (For Custom Projects)
YouTube: https://www.youtube.com/@rameezimdad (Subscribe for more!)
-->

**claude-auto** runs Claude Code across several Claude accounts (Pro / Max). When the account you are on hits its usage limit, it checks which of your other accounts still has usage left, moves **the same session** to that account and tells Claude to continue where it stopped. You don't need to copy context or start a new chat.

![Shell](https://img.shields.io/badge/shell-bash-blue) ![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20WSL%20%7C%20macOS-lightgrey) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- Automatic account switching when the Claude Code usage limit is reached
- Checks each account's real usage (5-hour and weekly windows) **before** switching to it
- Resumes the same conversation (`--resume`) on the new account and keeps working
- Ignores short 429 bursts while your plan still has room
- Waits for the earliest reset when every account is full, then continues on its own
- `claude-auto status` shows the usage and reset time of every account
- `claude-auto add <n>` creates a new account folder that shares history, settings, skills, plugins and CLAUDE.md
- Uses the official `StopFailure` hook. It does not patch Claude Code.
- Works on Linux, WSL and macOS

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/rameezimdad/claude-auto-switch/main/install.sh | bash
```

Requirements: Claude Code, `bash`, `python3`, `curl`.

The installer:
1. copies the scripts to `~/.local/share/claude-auto` and links `claude-auto` into `~/.local/bin`
2. writes the accounts list to `~/.config/claude-auto/accounts` (`~/.claude` plus any `~/.claude-<n>` folders it finds)
3. adds a `StopFailure` hook (matcher `rate_limit`) to each account's `settings.json`

## Set up your accounts

Your normal Claude Code login (`~/.claude`) is account 1. Add more:

```bash
claude-auto add 2
CLAUDE_CONFIG_DIR=~/.claude-2 claude      # type /login, sign in with your second account, then /exit

claude-auto add 3
CLAUDE_CONFIG_DIR=~/.claude-3 claude      # /login with the third account
```

`add` links the new folder's `projects`, `settings.json`, `CLAUDE.md`, `skills`, `plugins`, `agents` and `commands` to `~/.claude`, so each account sees the same history and setup. Only the login is separate.

Check them:

```bash
claude-auto status
```
```
account 1 (~/.claude)             97% used, resets Thu 05:00
~/.claude-2                        12% used, resets Thu 09:00
~/.claude-3                        not logged in
```

## Use

Start Claude Code with `claude-auto` instead of `claude`. Every `claude` flag still works:

```bash
claude-auto
claude-auto -c                 # continue the last session
claude-auto --resume <id>
```

To switch earlier, for example at 90% used:

```bash
CLAUDE_AUTO_MAX=90 claude-auto
```

Tip: `alias claude=claude-auto` in your shell profile makes it the default.

## How it works

```
claude-auto ── picks the first account under the limit ──> claude (account 1)
                                                               │
                                     usage limit error (rate_limit)
                                                               │
                         StopFailure hook: checks account 1's usage
                         full? save session id, close claude
                                                               │
claude-auto ── checks accounts 2, 3 ... ── first one with room ─┘
            └─> claude --resume <same session> "continue where you left off"
```

- The usage check reads each account's OAuth token, from `.credentials.json` on Linux/WSL or the Keychain on macOS, and asks the same usage endpoint that `/usage` uses.
- An account that is not logged in is skipped. If the token has expired, the account is tried last, because Claude Code refreshes the token when it starts.
- If an account does not share `projects/`, the session transcript is copied to it before resuming.
- The hook does nothing unless Claude Code was started by `claude-auto`, so plain `claude` sessions behave as before.

## Uninstall

```bash
bash ~/.local/share/claude-auto/uninstall.sh
```

This removes the scripts and the hook. Your account folders and logins stay.

## FAQ

**How do I use multiple Claude accounts in Claude Code?**
Each account needs its own config folder (`CLAUDE_CONFIG_DIR`). `claude-auto add <n>` creates one, and `claude-auto` picks between them.

**What happens when the Claude Code usage limit is reached?**
Normally the session stops until the limit resets. With claude-auto, the session closes, reopens on another account with usage left and continues the same task.

**Does it lose my conversation or context?**
No. It resumes the same session ID, so the new account loads the full conversation.

**What if all my accounts are out of usage?**
It shows when the earliest account resets, waits until then and continues on that account.

**Does it work with Claude Pro and Claude Max?**
Yes. It works with any subscription login. Accounts that use an API key have no plan usage to check, so they are skipped.

**Is this allowed?**
It only uses accounts you own and log into yourself. Check the Claude terms that apply to your plans.

## Author

Developed by **Mohammad Rameez Imdad (Rameez Scripts)**

- YouTube: https://www.youtube.com/@rameezimdad
- WhatsApp: https://wa.me/923435347417 (custom projects)
- Email: Contact@rameezscripts.com
- Website: https://rameezscripts.com

## License

MIT
