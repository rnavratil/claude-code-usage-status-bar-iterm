# claude-code-usage-status-bar-iterm

iTerm2 status bar component that shows your Claude Code usage limits in real time.

<img width="636" height="21" alt="image" src="https://github.com/user-attachments/assets/aacd4a69-4815-42fc-91fa-e02b9cb24752" />
<br>
<img width="1512" height="982" alt="image" src="https://github.com/user-attachments/assets/550b9a8c-15c1-488a-aab3-3a55d436a2f7" />
<br>
Displays:
- **session** — 5-hour rolling usage (%)
- **week** — 7-day rolling usage (%)
- **extra** — paid extra usage credits (only shown when enabled)

Data is fetched from the Claude API using the OAuth token stored by Claude Code in macOS Keychain. Results are cached in `~/.cache/cc-usage.txt` for 60 seconds, so the API is never called more than once per minute regardless of how often the status bar refreshes.

---

## Requirements

- macOS
- [iTerm2](https://iterm2.com) with Python API enabled
- [Claude Code](https://claude.ai/code) installed and signed in

---

## Installation

### Option A — Homebrew (recommended)

```bash
brew tap rnavratil/claude-code-usage-status-bar-iterm
brew install claude-code-usage-status-bar-iterm
```

`jq` and `bc` are installed automatically as dependencies. The Python script is symlinked into iTerm2's AutoLaunch folder for you.

Then finish setup in iTerm2:

**1. Enable the iTerm2 Python API**

Open iTerm2 → **Scripts → Manage → Install Python Runtime** and follow the prompts.

**2. Run the script**

In iTerm2: **Scripts → AutoLaunch → claude-code-usage-status-bar-iterm.py**

**3. Add the component to the status bar**

iTerm2 → **Preferences → Profiles → Session → Configure Status Bar**

Drag **Claude Usage** into the active components (if it's not visible, scroll down in the component list).

---

### Option B — Manual

**1. Install dependencies**

```bash
brew install jq bc
```

**2. Clone the repository**

```bash
git clone https://github.com/rnavratil/claude-code-usage-status-bar-iterm.git ~/claude-code-usage-status-bar-iterm
chmod +x ~/claude-code-usage-status-bar-iterm/claude-code-usage-status-bar-iterm.sh
```

If you clone to a different location, update the `SCRIPT` path in `claude-code-usage-status-bar-iterm.py`:

```python
SCRIPT = os.path.expanduser("~/path/to/claude-code-usage-status-bar-iterm.sh")
```

**3. Enable the iTerm2 Python API**

Open iTerm2 → **Scripts → Manage → Install Python Runtime** and follow the prompts.

**4. Install the Python script**

```bash
cp ~/claude-code-usage-status-bar-iterm/claude-code-usage-status-bar-iterm.py \
  ~/Library/Application\ Support/iTerm2/Scripts/AutoLaunch/
```

**5. Run the script**

In iTerm2: **Scripts → AutoLaunch → claude-code-usage-status-bar-iterm.py**

**6. Add the component to the status bar**

iTerm2 → **Preferences → Profiles → Session → Configure Status Bar**

Drag **Claude Usage** into the active components (if it's not visible, scroll down in the component list).

---

## Configuration

At the top of `claude-code-usage-status-bar-iterm.sh`:

| Variable | Default | Description |
|---|---|---|
| `SHOW_TIMEZONE` | `false` | Append timezone name to reset times |
| `TTL` | `60` | Cache lifetime in seconds (override with `CC_CACHE_TTL` env var) |
| `LOCK_TTL` | `30` | Minimum seconds between API calls |
| `API_TIMEOUT` | `5` | curl timeout in seconds |
