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

The motivating use case: a `~/repos/github` directory with 250+ repositories filed under topic folders, where "what was I working on recently?" matters far more than alphabetical order. There, entries are numbered in recency order and a bare number `cd`s into the repo — see [Jumping by number](#jumping-by-number).

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
lsrecent [dir]        # grouped view of dir (default: current directory)
lsr [dir]             # short alias for the same

lsrecent repos [root] # grouped view at repository level, across the whole tree
lsrecent today [root] # only the repos you opened today
lsrp                  # fzf picker over every repo, then cd into it
lsrt                  # same, restricted to today's

lsreg [args]          # plain ls, even where the grouped view is the default
<number>              # cd into that entry of the last listing
```

## Repository level

Listing a directory's immediate children stops being the right unit once repos
are filed under topic folders: it buckets *topics*, and topic folders are always
"recent" because any repo inside one keeps touching them. A topic folder is also
never the thing you want to open — it is filing, not work — and loose notes
sitting beside them are pure noise.

So **`lsrecent [dir]` picks the unit for you**:

- the directory contains repos below it → it lists **repositories**, wherever
  they sit in the tree, and nothing else (no topic folders, no stray files);
- the directory is itself a repo (`.git` present) → it lists **children**, files
  included, because there the files *are* the content.

`lsrecent repos` forces the repository view explicitly:

```
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 lsrecent            2 HVAC_Repair_0726     3 Driving-Checklists
  4 MCPJungle-Gateway   5 Cloud-Mounts         6 Twilio-Manager

━━ PAST WEEK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 31 DSR-Holdings-Cloud  32 dsrholdings-accounting-plugin   ...
```

A repo is any directory containing `.git`, found strictly *below* the root — a
root that is itself a repo is not listed among the repos under it. The root
defaults to `$LSRECENT_REPO_ROOT`, else `~/repos/github`, else `~/repos`; search
depth is `$LSRECENT_REPO_DEPTH` (4). Names are shown as bare basenames because
they are normally unique; `--full` shows `topic/repo` instead.

## Jumping by number

Repository listings are numbered in recency order across the whole listing — `1`
is the most recently touched repo, and the count keeps running through *PAST
WEEK*, *PAST MONTH* and the rest rather than restarting per bucket. Type a number,
press enter, and you are in that repo:

```
$ ls
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 lsrecent            2 HVAC_Repair_0726     3 Driving-Checklists
$ 2
$ pwd
/home/you/repos/github/home-and-property/HVAC_Repair_0726
```

Each listing writes its numbering to
`${XDG_DATA_HOME:-~/.local/share}/lsrecent/last-list` as `<n>\t<path>` lines, and
`lsrecent path N` resolves a number against it (erroring if the path has since
been deleted). The numbers themselves are shell *functions* named `1`, `2`, … —
bash permits that — defined by `shell-init`'s `__lsrecent_bind_numbers`, which is
re-run after every listing so stale numbers are unbound rather than left pointing
somewhere wrong.

The obvious-looking alternative, `command_not_found_handle`, cannot work:
bash runs that handler in a forked subshell, so any `cd` it performs dies with the
fork. Numbers are only bound by listings run through the shell integration (bare
`ls`, `lsrepos`, `lstoday`); `lsrecent repos` invoked directly still writes the
map, but a subprocess cannot define functions in your shell.

## Getting a plain listing anyway

`lsreg` is the escape hatch — plain `ls` with normal colors, taking the same
arguments, in a directory where the grouped view is the default:

```bash
lsreg          # conventional listing here
lsreg -la      # any ls flags
```

`ls` with any argument already falls through to real `ls`, so `lsreg` is for the
case where you want the *no-argument* listing unmodified.

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

`shell-init` also defines the `lsr-add`, `lsr-remove` and `lsr-edit` aliases,
`lsreg`, the `lsrp` / `lsrt` picker functions, and `lsrepos` / `lstoday`. The last
two are functions rather than aliases because they have to bind the numbers they
printed in your shell afterwards.

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
        lsrecent && __lsrecent_bind_numbers
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

- **Buckets:** *Today* is calendar-today (not "last 24 h"), then ≤ 7 days, ≤ 30 days, ≤ 90 days, older. Empty buckets are omitted. Membership is decided by comparing against today's local midnight epoch, not by formatting each timestamp.
- **Forks are the entire performance story.** A fork costs ~7 ms here, and everything else this tool does is free by comparison. So there is exactly one rule: *no subprocess inside a per-entry loop.* Timestamps come from a single `find -printf`, not a `stat` per entry; the clock comes from bash's `printf '%(%s)T'`, not `date`; `check` compares the raw `$PWD` before paying for `realpath`; `COLUMNS` is passed in by the shell wrapper so the binary never forks `tput`. Measured on a 3000-entry directory: **27.9 s before, 0.15 s after.** The old code was linear in fork count, so it was fine on a 30-entry directory and unusable on a large one — if a change here makes a big directory feel slow again, count the forks first.
- **Recency source is mtime, except where it can't be.** Access time (atime) would literally mean "last opened", but on modern Linux `relatime`/`noatime` mounts make it unreliable, and merely listing or backing up a tree can touch it. Modification time is stable and, for project directories, tracks real activity — but it cannot express "I opened this", which is why repo-level views also consult the visit log.
- **Ordering within a bucket** is most-recent-first.
- **Directory-level layout is delegated to `ls`** (`ls -dtC --color=always`), so you get the exact column packing and file-type colors you're used to. Repo-level layout can't be: `ls` re-sorts its operands, and repos resolve from many different parents, so that view does its own column packing against the computed order. It fills **row-major**, unlike `ls -C` — once entries are numbered, column-major would run 1, 2, 3 down the page instead of across it.
- **A bash function returns the status of its last command**, which bit this tool hard: `collect_repos` ended with an `(( a > b ))` test, so whenever a recorded visit was merely *not newer* than the repo's mtime it returned 1, and every caller's `|| die "no git repositories under $root"` fired with 255 repos sitting in the array. Any function here whose result is "did it work" ends with an explicit `return 0`.
- **Headers** are full-width `━` rules with bold bright ANSI colors (green / cyan / yellow / magenta / gray), sized to the terminal width.
- **The override lives in a shell function**, because changing what bare `ls` does mid-session requires shell-level logic — but the function is deliberately minimal and generated by the binary, so all real behavior stays in one place.

## License

MIT
