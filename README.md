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

Requires bash 4.2+ and GNU coreutils (`stat -c`, `date -d`, `find -printf`, `realpath`) — i.e. any normal Linux. `fzf` is optional, needed only for the picker. On macOS, install coreutils and adjust the `stat`/`date`/`find` calls.

## Usage

```bash
lsrecent [dir]        # grouped view of dir's children (default: current directory)
lsr [dir]             # short alias for the same

lsrecent repos [root] # grouped view at repository level, across the whole tree
lsrecent today [root] # only the repos you opened today
lsrp                  # fzf picker over every repo, then cd into it
lsrt                  # same, restricted to today's
```

## Repository level

`lsrecent [dir]` lists a directory's immediate children. That stops being the
right unit once repos are filed under topic folders — `lsrecent ~/repos/github`
then buckets *topics*, and topic folders are always "recent" because any repo
inside one keeps touching them.

`lsrecent repos` walks the tree instead and buckets **repositories**, wherever
they sit:

```
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
lsrecent   HVAC_Repair_0726   MCPJungle-Gateway   Twilio-Manager

━━ PAST WEEK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DSR-Holdings-Cloud   dsrholdings-accounting-plugin   ...
```

A repo is any directory containing `.git`. The root defaults to
`$LSRECENT_REPO_ROOT`, else `~/repos/github`, else `~/repos`; search depth is
`$LSRECENT_REPO_DEPTH` (4). Names are shown as bare basenames because they are
normally unique; `--full` shows `topic/repo` instead.

## "Opened today" and the visit log

`repos` and `today` mean different things by recency, deliberately.

**`repos` uses activity**: the newest of the repo directory's mtime, `.git`'s
mtime, and any recorded visit. `.git` is included because commits, checkouts and
fetches leave the worktree directory's own mtime untouched.

**`today` uses only the visit log** — literally the repos you `cd`'d into today.
mtime cannot answer that question: entering a repo touches nothing, and editing
a nested file leaves the repo directory's mtime alone. Backups, indexers and
tree-wide `chmod`s all forge it in the other direction. On this machine, mtime
alone put 24 repos in "today"; the visit log put 3.

The log is `${XDG_DATA_HOME:-~/.local/share}/lsrecent/opened.log`, one
`<epoch>\t<path>` line per visit, appended by a `PROMPT_COMMAND` hook whenever
`$PWD` changes and `$PWD/.git` exists. It is compacted automatically past 5000
lines (last visit per path wins, entries older than 180 days and paths that no
longer exist are dropped); `lsrecent prune` forces it.

The hook is the one piece of real logic that lives in the shell rather than the
binary, because it runs on every prompt and must not fork — it is a `[[ -e ]]`
test and a `printf` append, using bash's `EPOCHSECONDS`. `lsrecent visit [dir]`
does the same thing as a subprocess, for non-bash shells.

**It only records from the moment it is installed.** A fresh install has an
empty log, and `today` will say so rather than silently showing nothing.

## The picker

`lsrp` lists every repo newest-first in `fzf` and `cd`s into what you choose;
`lsrt` restricts the list to today's. The preview pane shows the last 8 commits
and `git status -sb`. Both are shell functions from `shell-init`, because `cd`
has to happen in your shell — `lsrecent pick` itself just prints the chosen
absolute path, so it composes with anything else.

`fzf` is the tool's only optional dependency — the picker needs it, everything
else works without it.

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

`shell-init` also defines short aliases: `lsr-add`, `lsr-remove`, `lsr-edit`,
`lsrepos`, `lstoday`, and the `lsrp` / `lsrt` picker functions.

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

- **Buckets:** *Today* is calendar-today (not "last 24 h"), then ≤ 7 days, ≤ 30 days, ≤ 90 days, older. Empty buckets are omitted. Membership is decided by comparing against today's local midnight epoch, not by formatting each timestamp — the latter cost one `date` fork per entry, which is visible across a few hundred repos.
- **Recency source is mtime, except where it can't be.** Access time (atime) would literally mean "last opened", but on modern Linux `relatime`/`noatime` mounts make it unreliable, and merely listing or backing up a tree can touch it. Modification time is stable and, for project directories, tracks real activity — but it cannot express "I opened this", which is why repo-level views also consult the visit log.
- **Ordering within a bucket** is most-recent-first.
- **Directory-level layout is delegated to `ls`** (`ls -dtC --color=always`), so you get the exact column packing and file-type colors you're used to. Repo-level layout can't be: `ls` re-sorts its operands, and repos resolve from many different parents, so that view does its own column packing against the computed order.
- **Headers** are full-width `━` rules with bold bright ANSI colors (green / cyan / yellow / magenta / gray), sized to the terminal width.
- **The override lives in a shell function**, because changing what bare `ls` does mid-session requires shell-level logic — but the function is deliberately minimal and generated by the binary, so all real behavior stays in one place.

## License

MIT
