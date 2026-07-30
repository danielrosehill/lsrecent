# lsrecent

A directory listing grouped by **recency** — with a built-in mechanism for making plain `ls` use it automatically in directories you choose.

Instead of one undifferentiated wall of names, entries are bucketed under conspicuous, color-coded headers by when they were last modified:

```
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (bright green)
Laptop-Configs  Incoterms_Poster

━━ YESTERDAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (green)
mqtt-mcp   palgate-multigate

━━ PAST WEEK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (cyan)
Hardware-Purchase-0726   thinkpad-e15-upgrades   android-unroot
Wheres-My-Stuff-Deploy   Israel-Cable-Sourcing   Hebrew-Tech-Vocab

━━ PAST MONTH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (yellow)
My-Weird-Prompts   UniFi-OS-Server-Migration   laptop-nvme-upgrade

━━ PAST 3 MONTHS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (magenta)
...

━━ OLDER ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (gray)
...
```

The motivating use case: a `~/repos/github` directory with 250+ repositories filed under topic folders, where "what was I working on recently?" matters far more than alphabetical order. There, entries are numbered in recency order and the listing ends by asking which one you want — type the number and you are in it. See [Choosing an entry](#choosing-an-entry).

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
ls                    # grouped view, in directories you have opted in
lsr [dir]             # grouped view of dir (default: current directory)

lsrepos               # grouped view at repository level, across the whole tree
lstoday               # only the repos you opened today
lsyesterday           # only the repos whose last visit was yesterday
lsrepos --all         # the whole listing, past one screenful (-a works too)

lsrp                  # fzf picker over every repo, then cd into it
lsrt / lsry           # same, restricted to today's / yesterday's
lsreg [args]          # plain ls, even where the grouped view is the default
```

Every repository listing ends with a prompt — type a number, press enter, and you
are in that repo. See [Choosing an entry](#choosing-an-entry).

Those are the shell functions `shell-init` defines, and they are what you want
interactively, because only a function running in your shell can `cd` it. Each
wraps the corresponding subcommand of the binary — `lsrecent`, `lsrecent repos`,
`lsrecent today`, `lsrecent yesterday`, `lsrecent pick` — which are what to call
from scripts: they list, and print, but never prompt.

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

## Choosing an entry

Repository listings are numbered in recency order across the whole listing — `1`
is the most recently touched repo, and the count keeps running through *YESTERDAY*,
*PAST WEEK* and the rest rather than restarting per bucket.

**A listing is a question, so it ends by asking it.** Type a number, press enter,
and the program has done its job — you are standing where you wanted to be:

```
$ ls
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 lsrecent            2 HVAC_Repair_0726     3 Driving-Checklists
→ number to cd, enter to stay: 2
/home/you/repos/github/home-and-property/HVAC_Repair_0726
$ pwd
/home/you/repos/github/home-and-property/HVAC_Repair_0726
```

Enter on its own — or `q`, or ctrl-d — stays put. A number outside the ranking, or
a repo deleted since it was printed, re-asks rather than failing.
`LSRECENT_PROMPT=0` turns the prompt off and gives you the listing alone.

The prompt appears only where something can act on the answer: a listing on a
terminal, run through the shell integration. Piped, redirected, or with the binary
called directly, it lists and exits, so `lsrecent repos | wc -l` and scripts behave
exactly as before.

### Why the answer travels through a file

A process cannot `cd` its parent shell — the working directory is per-process, and
a child changing its own is lost when it exits. So the work is split: the binary
prints the listing and reads the reply from `/dev/tty`, then writes the chosen
absolute path to the file named in `$LSRECENT_CD_FILE`; the shell function that set
that variable reads the file and does the `cd` itself, in your shell.

Three separate channels, deliberately. Stdout is the listing and may be a pipe;
stdin may be anything at all; so the prompt gets `/dev/tty` and the answer gets a
file of its own. The file is named for the shell's PID (`…/lsrecent/cd.$$`) so two
terminals listing at once cannot read each other's answer, and it is a fixed name
rather than `mktemp` to keep the bare-`ls` path fork-free. It is removed as soon as
it is read; `lsrecent prune` sweeps any left by a shell that died mid-prompt.

### The numbers also stay bound

After the prompt is gone the numbers still work, for the case where you glance at a
listing, do something else, and then decide:

```
$ lstoday
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 lsrecent   2 HVAC_Repair_0726
→ number to cd, enter to stay:
$ git -C ~/notes pull
$ 2                       # still goes where 2 pointed
```

Each listing writes its numbering to
`${XDG_DATA_HOME:-~/.local/share}/lsrecent/last-list` as `<n>\t<path>` lines, and
`lsrecent path N` resolves a number against it (erroring if the path has since
been deleted). The map covers the whole ranking, not just the printed screenful.
The numbers themselves are shell *functions* named `1`, `2`, … — bash permits that
— defined by `shell-init`'s `__lsrecent_bind_numbers`, which is re-run after every
listing so stale numbers are unbound rather than left pointing somewhere wrong. It
defines them in a single `eval` because a full listing here is a couple of hundred
of them, not twenty.

The obvious-looking alternative, `command_not_found_handle`, cannot work:
bash runs that handler in a forked subshell, so any `cd` it performs dies with the
fork. Numbers are only bound by listings run through the shell integration (bare
`ls`, `lsrepos`, `lstoday`, `lsyesterday`); `lsrecent repos` invoked directly still
writes the map, but a subprocess cannot define functions in your shell.

## One screenful by default

250 repositories is 130 rows of output, which scrolls the answer off the screen
and takes your scrollback with it. Repository listings therefore stop when the
screen is full and tell you what they left out:

```
━━ PAST WEEK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 31 DSR-Holdings-Cloud   32 dsrholdings-accounting-plugin
 33 Israel-Cable-Sourcing   34 Hebrew-Tech-Vocab
… 219 more, numbered 35-253 · lsrepos --all to see them
```

**Cutting the listing does not cut the numbering.** Every repo in the ranking gets
a number whether or not it fit on the screen, which is why the footer gives the
range it elided: `35` at the prompt cds into the thirty-fifth repo even though you
never saw its name, and the path is echoed so you can see where you landed. `--all`
is for when you want to read the names, not a precondition for reaching them.

Truncation is only sound here because of the ordering: groups run newest-first
and so do their contents, so cutting from the end drops precisely the repos you
are least likely to want. Once anything has been cut the remaining groups are
only counted, never partially shown — printing *OLDER* after eliding half of
*PAST MONTH* would misrepresent the recency order the whole view is built on.

The budget is the terminal height less three rows, so the listing, the footer and
your prompt all land on one screen. To change or defeat it:

```bash
lsrepos --all              # or -a: no limit
LSRECENT_MAX_ROWS=60 ls    # explicit budget; 0 means unlimited
lsrepos --all | less -R    # if you want a real pager
```

A **redirected or piped** listing is never truncated — `lsrecent | wc -l` sees all
255, the same way `ls` drops its columns when it is not talking to a terminal.
The numbering covers exactly what was printed, so a number you cannot see is
never bound to something: in a truncated listing `37` is simply not a command.

A pager is deliberately not the default. It would take over the screen and demand
a `q` for a listing you wanted to glance at, and the numbers are only useful while
they are still visible in front of your prompt.

Note that the **directory-level** view (inside a repo) is not budgeted; it still
prints in full, because it delegates its layout to `ls -C`, which packs
column-major — cutting rows off the bottom there would drop a scattered subset
rather than the oldest entries.

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

`repos` and `today` / `yesterday` mean different things by recency, deliberately.

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

### Today and yesterday do not overlap

`lsyesterday` is `lstoday` for the previous calendar day, and the two lists are
disjoint: **a repo you opened yesterday and again today is today's, and appears in
no other list.** Every repo has exactly one timestamp — its *newest* visit — and
that timestamp falls in exactly one day. So the question the pair answers is "when
did I last have this open?", and each repo answers it once. If it were "was this
open at any point yesterday?", most of yesterday's list would be a duplicate of
today's, which is precisely the noise these views exist to remove.

The same logic makes *YESTERDAY* a bucket of its own in the ordinary `lsrepos`
listing, rather than being folded into *PAST WEEK* — "today or yesterday?" is the
distinction you actually reach for, and one timestamp per repo means the buckets
stay mutually exclusive.

Day boundaries are local midnights, computed with bash's own `printf '%(%H)T'`
rather than by forking `date`, since bare `ls` goes through this path. Yesterday's
midnight is *snapped to* rather than reached by subtracting 86400, so a day that a
DST change made 23 or 25 hours long still gives the right boundary — verified
against every day of 2026 in eight zones, including 30-minute DST (Lord Howe) and
the southern hemisphere. Zones that transition *at* midnight, such as
America/Santiago, land within the hour twice a year; nothing here cares.

## The picker

`lsrp` lists every repo newest-first in `fzf` and `cd`s into what you choose;
`lsrt` restricts the list to today's and `lsry` to yesterday's. The preview pane
shows the last 8 commits and `git status -sb`. All three are shell functions from
`shell-init`, because `cd` has to happen in your shell — `lsrecent pick` itself
just prints the chosen absolute path, so it composes with anything else.

The picker is for searching by name when you know what you are after. The numbered
prompt is for the far commoner case of picking off a short recency-ordered list, and
needs no dependency and no fuzzy-matching in your head.

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

`shell-init` passes `COLUMNS` and `LINES` through explicitly — interactive bash
sets both but exports neither, and without them the binary cannot size its columns
or its row budget without forking `tput`.

`shell-init` also defines the `lsr-add`, `lsr-remove` and `lsr-edit` aliases,
`lsreg`, the `lsrp` / `lsrt` / `lsry` picker functions, and `lsrepos` / `lstoday` /
`lsyesterday`. Those last three, and the `ls` wrapper, all go through one
`__lsrecent_list` helper: they have to `cd` to wherever the prompt was answered and
bind the numbers they printed, and both of those must happen in your shell, which
rules out aliases.

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
        __lsrecent_list          # lists, prompts, cds where you said
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

- **Buckets:** *Today* and *Yesterday* are calendar days (not "last 24 h" / "24–48 h ago"), then ≤ 7 days, ≤ 30 days, ≤ 90 days, older. Empty buckets are omitted. Membership is decided by comparing against local midnight epochs, not by formatting each timestamp. One timestamp per entry means the buckets are mutually exclusive, which is what lets *Today* and *Yesterday* be answers rather than overlapping windows.
- **A listing is a question.** Anything that numbers its output should be willing to take a number back, so the prompt is the default rather than a flag: the alternative is a tool that shows you the answer and then makes you retype part of it. The non-interactive path still exists for pipes and scripts, where it is the only sensible behaviour — and it is chosen by detecting that situation, not by asking the user to declare it.
- **Forks are the entire performance story.** A fork costs ~7 ms here, and everything else this tool does is free by comparison. So there is exactly one rule: *no subprocess inside a per-entry loop.* Timestamps come from a single `find -printf`, not a `stat` per entry; the clock comes from bash's `printf '%(%s)T'`, not `date`; `check` compares the raw `$PWD` before paying for `realpath`; `COLUMNS` is passed in by the shell wrapper so the binary never forks `tput`. Measured on a 3000-entry directory: **27.9 s before, 0.15 s after.** The old code was linear in fork count, so it was fine on a 30-entry directory and unusable on a large one — if a change here makes a big directory feel slow again, count the forks first.
- **Recency source is mtime, except where it can't be.** Access time (atime) would literally mean "last opened", but on modern Linux `relatime`/`noatime` mounts make it unreliable, and merely listing or backing up a tree can touch it. Modification time is stable and, for project directories, tracks real activity — but it cannot express "I opened this", which is why repo-level views also consult the visit log.
- **Ordering within a bucket** is most-recent-first.
- **Directory-level layout is delegated to `ls`** (`ls -dtC --color=always`), so you get the exact column packing and file-type colors you're used to. Repo-level layout can't be: `ls` re-sorts its operands, and repos resolve from many different parents, so that view does its own column packing against the computed order. It fills **row-major**, unlike `ls -C` — once entries are numbered, column-major would run 1, 2, 3 down the page instead of across it.
- **`[[ -t 1 ]]` is always false inside `$(...)`** — stdout there is the pipe bash created to capture the substitution, not the terminal. A helper called as `budget=$(row_budget)` therefore cannot ask whether it is talking to a terminal; the answer is sampled once at the top level into `stdout_tty`. `tput lines` has the same problem from a different angle: it sizes the terminal from an ioctl on *its* stdout, so inside a substitution it reports terminfo's static default rather than the real height. Hence `LINES` from `shell-init`, falling back to `stty size < /dev/tty`.
- **A bash function returns the status of its last command**, which bit this tool hard: `collect_repos` ended with an `(( a > b ))` test, so whenever a recorded visit was merely *not newer* than the repo's mtime it returned 1, and every caller's `|| die "no git repositories under $root"` fired with 255 repos sitting in the array. Any function here whose result is "did it work" ends with an explicit `return 0`.
- **Headers** are full-width `━` rules with bold bright ANSI colors (green / cyan / yellow / magenta / gray), sized to the terminal width.
- **The override lives in a shell function**, because changing what bare `ls` does mid-session requires shell-level logic — but the function is deliberately minimal and generated by the binary, so all real behavior stays in one place.

## License

MIT
