# lsrecent

A directory listing grouped by **recency** — with a built-in mechanism for making plain `ls` use it automatically in directories you choose.

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

## Install

```bash
git clone https://github.com/danielrosehill/lsrecent.git
cd lsrecent
./install.sh
```

That copies the `lsrecent` binary to `~/.local/bin` and adds one line to your `~/.bashrc`:

```bash
eval "$(lsrecent shell-init)"
```

Nothing else is sourced from the repo — after install, the binary is self-contained and the clone can be deleted.

Requires bash and GNU coreutils (`stat -c`, `date -d`, `ls -w`, `realpath`) — i.e. any normal Linux. On macOS, install coreutils and adjust the `stat`/`date` calls.

## Usage

```bash
lsrecent [dir]        # grouped view of dir (default: current directory)
lsr [dir]             # short alias for the same
```

## The override mechanism

The point of the system: in *chosen* directories, bare `ls` shows the grouped view without you remembering a special command — while behaving completely normally everywhere else.

The binary is its own backend. It manages an include-list and answers membership queries; the shell wrapper is a four-line function that asks it.

### Managing the include-list

| Command | Effect |
|---------|--------|
| `lsrecent add` | Enable the grouped view for the **current** directory |
| `lsrecent add /some/path` | Enable it for another directory |
| `lsrecent remove` (or `rm`) | Disable it for the current directory |
| `lsrecent remove /some/path` | Disable it for another directory |
| `lsrecent list` | Print every directory with the override enabled |
| `lsrecent edit` | Open the include-list in `$EDITOR` |
| `lsrecent check [dir]` | Exit 0/1 depending on whether the override is enabled (for scripting) |

`shell-init` also defines short aliases: `lsr-add`, `lsr-remove`, `lsr-edit`.

`add` validates that the path exists, resolves it with `realpath` (so relative paths and symlinks work), and deduplicates. Changes take effect immediately in every open shell — the list is consulted on each `ls`, so there is nothing to reload.

### Where state lives

`${XDG_CONFIG_HOME:-~/.config}/lsrecent/dirs` — created on first `add`. Deliberately a plain-text file, one absolute path per line (`#` comments and blank lines ignored, leading `~` expanded):

```
# lsrecent include-list
/home/you/repos/github
/home/you/Documents/projects
/mnt/archive/clients
```

Plain text rather than JSON because a pure-bash tool shouldn't need `jq` or Python to read its own state, and the file stays trivially hand-editable, greppable, and dotfile-manager-friendly. The CLI is the intended interface; manual edits are equally valid.

### How the `ls` override works

`eval "$(lsrecent shell-init)"` installs this wrapper:

```bash
ls() {
    if (( $# == 0 )) && [[ -t 1 ]] && lsrecent check 2>/dev/null; then
        lsrecent
    else
        command ls --color=auto "$@"
    fi
}
```

- **Any arguments → real `ls`.** `ls -la`, `ls somedir` are untouched.
- **Non-terminal stdout → real `ls`.** Pipes and scripts (`ls | grep foo`) never see the grouped view or its ANSI codes.
- **Otherwise** the binary is asked whether `$PWD` is on the include-list.

Matching is exact — no subdirectory inheritance. Enabling `~/repos/github` does **not** change `ls` inside `~/repos/github/some-project`; inside a project you usually want a conventional listing.

Because the wrapper's logic lives in the binary (`shell-init`, `check`), updating the binary updates the behavior everywhere — the repo/binary is the single source of truth, and your `.bashrc` never needs to change again.

## Design notes

- **Buckets:** *Today* is calendar-today (not "last 24 h"), then ≤ 7 days, ≤ 30 days, ≤ 90 days, older. Empty buckets are omitted.
- **Recency source is mtime.** Access time (atime) would literally mean "last opened", but on modern Linux `relatime`/`noatime` mounts make it unreliable, and merely listing or backing up a tree can touch it. Modification time is stable and, for project directories, tracks real activity.
- **Ordering within a bucket** is most-recent-first (`ls -t`).
- **Layout and coloring are delegated to `ls` itself** (`ls -dtC --color=always`), so you get the exact column packing and file-type colors you're used to — the script only does the bucketing and headers.
- **Headers** are full-width `━` rules with bold bright ANSI colors (green / cyan / yellow / magenta / gray), sized to the terminal width.
- **The override lives in a shell function**, because changing what bare `ls` does mid-session requires shell-level logic — but the function is deliberately minimal and generated by the binary, so all real behavior stays in one place.

## License

MIT
