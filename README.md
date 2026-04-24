# claude-code-usage-status-bar-iterm

iTerm2 status bar component that shows your Claude Code usage limits in real time.

```
session: 6% (Resets Apr 24 at 1:30am) | week: 16% (Resets Apr 25 at 3:00am) | extra: 66% (9.97/15.00 EUR)
```

Displays:
- **session** — 5-hour rolling usage (%)
- **week** — 7-day rolling usage (%)
- **extra** — paid extra usage credits (only shown when enabled)

Data is fetched from the Claude API using the OAuth token stored by Claude Code in macOS Keychain. Results are cached for 60 seconds.

---

## Requirements

- macOS
- [iTerm2](https://iterm2.com) with Python API enabled
- [Claude Code](https://claude.ai/code) installed and signed in
- `jq` and `bc` installed (`brew install jq bc`)

---

## Installation

**1. Copy the shell script**

Place `claude-code-usage-status-bar-iterm.sh` anywhere on your machine. The default location expected by the Python script is `~/Desktop/claude-code-usage-status-bar-iterm.sh`.

If you place it elsewhere, update the `SCRIPT` path in `claude-code-usage-status-bar-iterm.py`:

```python
SCRIPT = os.path.expanduser("~/path/to/claude-code-usage-status-bar-iterm.sh")
```

Make the script executable:

```bash
chmod +x ~/Desktop/claude-code-usage-status-bar-iterm.sh
```

**2. Enable the iTerm2 Python API**

Open iTerm2 → **Scripts → Manage → Install Python Runtime** and follow the prompts.

**3. Install the Python script**

Copy `claude-code-usage-status-bar-iterm.py` to the iTerm2 AutoLaunch folder:

```bash
cp claude-code-usage-status-bar-iterm.py \
  ~/Library/Application\ Support/iTerm2/Scripts/AutoLaunch/
```

**4. Run the script**

In iTerm2: **Scripts → AutoLaunch → claude-code-usage-status-bar-iterm.py**

**5. Add the component to the status bar**

iTerm2 → **Preferences → Profiles → Session → Configure Status Bar**

Drag **Claude Usage** into the active components.

---

## Configuration

At the top of `claude-code-usage-status-bar-iterm.sh`:

| Variable | Default | Description |
|---|---|---|
| `SHOW_TIMEZONE` | `false` | Append timezone name to reset times |
| `TTL` | `60` | Cache lifetime in seconds (override with `CC_CACHE_TTL` env var) |
| `LOCK_TTL` | `30` | Minimum seconds between API calls |
| `API_TIMEOUT` | `5` | curl timeout in seconds |
