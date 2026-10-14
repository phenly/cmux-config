# cmux-config

Versioned copies of the terminal-environment config for Claude Code + cmux. Local only (no remote).

| File in repo | Live location | How linked |
|---|---|---|
| `claude/statusline.sh` | `~/.claude/statusline.sh` | **symlink** to this file (`~/.claude/settings.json` already points at the live path, so it is unchanged) |
| `cmux/cmux.json.snapshot` | `~/.config/cmux/cmux.json` | reference snapshot only, not linked |
| `cmux/settings.json.snapshot` | `~/.config/cmux/settings.json` | reference snapshot only, not linked |

cmux files are snapshots because cmux creates/manages them (it writes a template on launch and edits them from its Settings UI), so a symlink could be replaced or written through. Both are currently the unedited default template. If you customize cmux, back up the file, edit, run `cmux reload-config`, then copy it here.

## Status line

Reads Claude Code's status-line JSON on stdin (needs `jq`). Line 1: model, effort, context %, 5h/7d limits, cost. Line 2: dir + git branch, repo. Line 3: `[nm]` session name (`session_name`: `/rename` or `--name`, else the AI title; omitted when neither exists) and `[id]` full `session_id`. Missing fields are omitted. Exit code is always 0.

Test: `echo '{"session_id":"abc","session_name":"Demo"}' | bash claude/statusline.sh`

## Install / restore links

```
REPO=~/Code/phenly/cmux-config
ln -s "$REPO/claude/statusline.sh" ~/.claude/statusline.sh.new && mv -f ~/.claude/statusline.sh.new ~/.claude/statusline.sh   # atomic swap
# cmux (only if restoring defaults): cp "$REPO/cmux/cmux.json.snapshot" ~/.config/cmux/cmux.json && cmux reload-config
```

`~/.claude/settings.json` needs `"statusLine": {"type":"command","command":"bash /Users/<you>/.claude/statusline.sh","padding":0}`.
Pre-change originals: `~/Code/phenly/cmux-config.backup-20261014/` (outside the repo).
