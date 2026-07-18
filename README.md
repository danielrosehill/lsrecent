# lsrecent

A directory listing grouped by **recency** — with a mechanism for making plain `ls` use it automatically in directories you choose.

Instead of one undifferentiated wall of names, entries are bucketed under conspicuous, color-coded headers by when they were last modified:

```
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (bright green)
Laptop-Configs  Incoterms_Poster

━━ PAST WEEK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (cyan)
Hardware-Purchase-0726   thinkpad-e15-upgrades   android-unroot
Wheres-My-Stuff-Deploy   palgate-multigate       mqtt-mcp

━━ PAST MONTH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (yellow)
My-Weird-Prompts   UniFi-OS-Server-Migration   laptop-nvme-upgrade

━━ PAST 3 MONTHS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (magenta)
...

━━ OLDER ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (gray)
...
```

The motivating use case: a `~/repos/github` directory with 100+ project folders, where "what was I working on recently?" matters far more than alphabetical order.

## What's in the box

| File | Purpose |
|------|---------|
| `lsrecent` | The standalone command. Groups and prints a directory's entries. |
| `shell-integration.sh` | Bash `ls()` wrapper + `lsr*` helper commands. |
| `install.sh` | Copies the script to `~/.local/bin`, creates the config, wires up `~/.bashrc`. |

## Install

```bash
git clone https://github.com/danielrosehill/lsrecent.git
cd lsrecent
./install.sh
```

Or manually: put `lsrecent` on your `PATH` and `source shell-integration.sh` from your `~/.bashrc`.

Requires bash and GNU coreutils (`stat -c`, `date -d`, `ls -w`) — i.e. any normal Linux. On macOS, install coreutils and adjust the `stat`/`date` calls.

## Usage

```bash
lsrecent [dir]    # grouped view of dir (default: current directory)
lsr [dir]         # short alias for the same
```

## The inclusion mechanism (automatic `ls` override)

The point of the system is that in *chosen* directories, bare `ls` shows the grouped view without you having to remember a special command — while behaving completely normally everywhere else.

### How it works

`shell-integration.sh` defines an `ls()` shell function. On each call it:

1. Checks that you passed **no arguments** and that stdout is a **terminal**. If either is false — `ls -la`, `ls somedir`, `ls | grep foo`, `ls` inside a script — it falls straight through to `command ls --color=auto "$@"`. Scripts, pipelines, and muscle memory are never affected.
2. Reads `~/.config/lsrecent/dirs` — a plain text file, one absolute path per line (`~` is expanded, `#` lines and blanks are ignored).
3. If `$PWD` exactly matches a listed directory, runs `lsrecent` instead. Otherwise, normal `ls`.

The config file is the single source of truth. Example:

```
# Directories where plain `ls` shows the lsrecent grouped view.
~/repos/github
~/Documents/projects
/mnt/archive/clients
```

Matching is exact (no subdirectory inheritance) — enabling `~/repos/github` does **not** change `ls` inside `~/repos/github/some-project`. This is deliberate: inside a project you usually want a conventional listing.

### Adding, removing, and editing overrides

| Command | Effect |
|---------|--------|
| `lsr-add` | Enable the grouped view for the **current** directory |
| `lsr-add /some/path` | Enable it for another directory |
| `lsr-remove` | Disable it for the current directory |
| `lsr-remove /some/path` | Disable it for another directory |
| `lsr-edit` | Open the config file in `$EDITOR` for manual editing |

`lsr-add` deduplicates (adding the same directory twice is a no-op), and both helpers resolve paths with `realpath`, so relative paths and symlinks work.

Changes take effect immediately in every shell — the config is re-read on each `ls`, so there's nothing to reload.

## Design notes

- **Buckets:** *Today* is calendar-today (not "last 24 h"), then ≤ 7 days, ≤ 30 days, ≤ 90 days, older. Empty buckets are omitted.
- **Recency source is mtime.** Access time (atime) would literally mean "last opened", but on modern Linux `relatime`/`noatime` mounts make it unreliable, and merely listing or backing up a tree can touch it. Modification time is stable and, for project directories, tracks real activity.
- **Ordering within a bucket** is most-recent-first (`ls -t`).
- **Layout and coloring are delegated to `ls` itself** (`ls -dtC --color=always`), so you get the exact column packing and file-type colors you're used to — the script only does the bucketing and headers.
- **Headers** are full-width `━` rules with bold bright ANSI colors (green / cyan / yellow / magenta / gray), sized to the terminal width.
- **The override lives in a function, not an alias**, because it needs per-invocation logic (argument count, tty check, `$PWD` lookup).

## License

MIT
