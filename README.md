# lsrecent

A directory listing grouped by **recency** — with a built-in mechanism for making plain `ls` use it automatically in directories you choose.

Instead of one undifferentiated wall of names, entries are bucketed under conspicuous, color-coded headers by when they were last modified:

```
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (bright green)
Laptop-Configs  Incoterms_Poster

━━ YESTERDAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (green)
mqtt-mcp   palgate-multigate

━━ 2 DAYS AGO ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (cyan)
Hardware-Purchase-0726   thinkpad-e15-upgrades   android-unroot

━━ 3 DAYS AGO ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (cyan)
Wheres-My-Stuff-Deploy   Israel-Cable-Sourcing   Hebrew-Tech-Vocab

...                                                       (through 7 DAYS AGO)

━━ PAST MONTH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (yellow)
My-Weird-Prompts   UniFi-OS-Server-Migration   laptop-nvme-upgrade

━━ PAST 3 MONTHS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (magenta)
...

━━ OLDER ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (gray)
...
```

The top of a real listing — plain `ls` in `~/repos/github`, with the shell integration loaded:

![lsrecent in a terminal](docs/screenshot-terminal.png)

The motivating use case: a `~/repos/github` directory with 250+ repositories filed under topic folders, where "what was I working on recently?" is the question a flat alphabetical listing cannot answer. The buckets answer it; inside a bucket the repos are alphabetical, so you can also just find the one you came for. Entries are numbered straight down the listing and it ends by asking which one you want — type the number and you are in it. See [Choosing an entry](#choosing-an-entry).

## Install

### Debian package

```bash
git clone https://github.com/danielrosehill/lsrecent.git
cd lsrecent
./build-deb.sh
sudo apt install ./dist/lsrecent_*_all.deb
lsrecent shell-install      # once per user account; see below
```

Installs `/usr/bin/lsrecent`, `/usr/bin/lsrecent-gui`, man pages and a launcher entry. `python3-pyqt6` is a Recommends rather than a Depends, so the package still installs on a headless box without dragging Qt in; on a desktop, apt pulls it by default.

The package deliberately does not edit anyone's `~/.bashrc`. A root `postinst` has no business writing to user dotfiles and cannot know which accounts want the override, so `lsrecent shell-install` is a separate, per-user step — it appends the `eval` line, and does nothing if it is already there.

### From the source tree, no root

```bash
./install.sh
```

Copies `lsrecent` and `lsrecent-gui` to `~/.local/bin`, adds a launcher entry under `~/.local/share/applications`, and runs `shell-install` for you.

Pick one or the other. `~/.local/bin` usually precedes `/usr/bin` on `PATH`, so doing both leaves the from-source copy shadowing the package, and two installs that can drift is precisely the failure the [version handshake](#if-the-numbers-appear-but-nothing-asks-for-one) exists to catch.

### Either way

One line goes into your `~/.bashrc`:

```bash
eval "$(lsrecent shell-init)"
```

Nothing else is sourced from the repo — after install, the binary is self-contained and the clone can be deleted.

Requires bash 4.2+ and GNU coreutils (`stat -c`, `date -d`, `find -printf`, `realpath`) — i.e. any normal Linux. `fzf` is optional, needed only for the picker; `python3-pyqt6` only for the window. On macOS, install coreutils and adjust the `stat`/`date`/`find` calls.

## Usage

```bash
ls                    # grouped view, in directories you have opted in
lsr [dir]             # grouped view of dir (default: current directory)

lsrepos               # grouped view at repository level, across the whole tree
lstoday               # only the repos you opened today
lsyesterday           # only the repos whose last visit was yesterday
lsrepos --all         # the whole listing, past one screenful (-a works too)
lsrepos -t            # newest-first within each bucket, not alphabetical

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
  1 Cloud-Mounts        2 Driving-Checklists   3 HVAC_Repair_0726
  4 lsrecent            5 MCPJungle-Gateway    6 Twilio-Manager

━━ 3 DAYS AGO ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 31 DSR-Holdings-Cloud  32 dsrholdings-accounting-plugin   ...
```

A repo is any directory containing `.git`, found strictly *below* the root — a
root that is itself a repo is not listed among the repos under it. The root
defaults to `$LSRECENT_REPO_ROOT`, else `~/repos/github`, else `~/repos`; search
depth is `$LSRECENT_REPO_DEPTH` (4). Names are shown as bare basenames because
they are normally unique; `--full` shows `topic/repo` instead.

### A bucket per day for the last week

The recent end of the listing is bucketed by **calendar day**, not by span:

| | |
| --- | --- |
| *TODAY* | since local midnight |
| *YESTERDAY* | the previous calendar day |
| *2 DAYS AGO* … *7 DAYS AGO* | one bucket each |
| *PAST MONTH*, *PAST 3 MONTHS*, *OLDER* | everything beyond a week |

"Today or yesterday?" was always the question these views answer, and it does not
stop being the question at 48 hours — *four days ago* is a place in your week, and
you can generally say what you were doing there. A single *PAST WEEK* bucket threw
that away and handed back the undifferentiated heap the grouping exists to break
up: on a tree of 250 repos it was routinely the largest group on the screen.

Empty days are simply not printed, so a quiet week costs nothing; a busy one is
longer than the old listing, which is the trade — [the fold](#one-screenful-by-default)
still cuts it to a screenful and everything below it is still numbered. All six
day buckets share the one cyan header colour: the colour says *how* recent,
coarsely, and the label says which day.

Boundaries are local midnights, computed without forking `date` — see
[Today and yesterday do not overlap](#today-and-yesterday-do-not-overlap) for how
that survives a DST week.

### Ordering: buckets by recency, names inside them

The **buckets** run newest-first, and that is where the recency lives: *TODAY*
before *YESTERDAY* before *2 DAYS AGO*, and a repo sits in exactly one of them.
**Inside** a bucket the repos are listed **alphabetically** (case-insensitively).

Sorting a bucket by recency too was the original behaviour and it sorted by a
distinction that is not worth much: everything in a day bucket is that day's, and
which of two of them was touched at 14:02 and which at 11:40 is not something you
know or can predict. So the position of a name in its bucket kept moving between
listings for reasons invisible on screen, and the only way to find a repo you
already had in mind was to read the group top to bottom. Alphabetical, the
position is stable and you can jump to it.

`--time` (`-t`) sorts within a bucket newest-first, `--name` (`-n`) is the
default, and `LSRECENT_SORT=time` makes `--time` the default for every listing:

```bash
lsrepos -t            # newest-first inside each bucket
lstoday -t
export LSRECENT_SORT=time    # ... or make that the default
```

One consequence is worth knowing: when a listing is cut to one screenful, the
bucket at the fold is now cut alphabetically rather than by age, so what is
missing from it is *M–Z*, not *the oldest*. Whole buckets are still dropped
oldest-first, and everything cut is still numbered and reachable from the prompt
by search or `+` — see [One screenful by default](#one-screenful-by-default).

## Choosing an entry

Repository listings are numbered straight down the listing — `1` is the first repo
of *TODAY*, and the count keeps running through *YESTERDAY*, *2 DAYS AGO* and the
rest rather than restarting per bucket.

**A listing is a question, so it ends by asking it.** Type a number, press enter,
and the program has done its job — you are standing where you wanted to be:

```
$ ls
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 Driving-Checklists  2 HVAC_Repair_0726     3 lsrecent
→ number, text to search, n next, p back, ? help, enter stays: 2
/home/you/repos/github/home-and-property/HVAC_Repair_0726
$ pwd
/home/you/repos/github/home-and-property/HVAC_Repair_0726
```

Enter on its own — or `q`, or ctrl-d — stays put. A number outside the ranking, or
a repo deleted since it was printed, re-asks rather than failing.
`LSRECENT_PROMPT=0` turns the prompt off and gives you the listing alone.

### The prompt is also a browser

One screenful is twenty-odd repositories and the ranking behind it is often
hundreds long, so a prompt that only accepted a number could not reach most of
what it had just numbered. It accepts more than a number:

| Reply | Does |
| --- | --- |
| `23` | cd into entry 23 — **numbers are the ranking, not the page** |
| `text` | search labels and paths for `text`, case-insensitive |
| `/` | clear the search, back to the full ranking |
| `n` or `+` | next page |
| `p` or `-` | previous page |
| `t` | back to the top of the current view |
| `a` | everything in the current view, unpaged |
| `?` | the same summary |
| enter, `q`, ctrl-d | stay put |

A bare word searches. Nothing else a selection could be is anything but digits, so
typing a repository name at a prompt that has just listed repository names does
what you meant:

```
$ ls
━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 Driving-Checklists  2 HVAC_Repair_0726     3 lsrecent
 …
… 238 more, numbered 21-258 · n pages to them, lsrepos --all prints them
→ number, text to search, n next, p back, ? help, enter stays: noisy
 79 noisycity-api-blueprint
… 1-1 of 1 matching "noisy" · end
→ number, text to search, n next, p back, ? help, enter stays: 79
/home/you/repos/github/smart-home/noisycity-api-blueprint
```

`79` was never on screen. The search matches the path as well as the label, so a
topic name (`smart-home`) collects everything filed under it even though the topic
is not part of a bare basename.

Numbers survive all of it. Filtering and paging move a window over the ranking
rather than renumbering it, so `79` means the same repository on the first screen,
inside a search, on page four, and via `lsrecent path 79` tomorrow.

It stays line-oriented rather than becoming a full-screen application, which is a
deliberate trade. The premise of the tool is that the listing lands in your
scrollback and stays useful there — an alternate-screen TUI would wipe it on exit,
taking the numbers with it. So each page prints and scrolls like any other command
output — including `p`, which prints the previous page again below rather than
scrolling up to where it already is. That is not the duplication it would be in a
pager: a number *is* the ranking, so an entry printed twice is the same repository
with the same number both times, and walking back down the list should leave the
same trail in the scrollback that walking up it did.

Pages are a fixed length within a view, measured over the whole view rather than
over the slice about to be printed. That is what makes `n` and `p` inverses of each
other — sized off the visible slice, a page's length depended on the longest label
still ahead of it, so its boundaries moved with the direction of travel — and it
also keeps the columns lined up from one page to the next.

The prompt appears only where something can act on the answer: a listing on a
terminal, run through the shell integration. Piped or redirected it lists and exits,
so `lsrecent repos | wc -l` and scripts behave exactly as before. On a terminal but
without the integration it says so instead of prompting — see below.

### If the numbers appear but nothing asks for one

```
→ cd-by-number needs the shell integration reloaded (shell has 1.5.0, binary is 1.5.1)
```

The binary is upgraded in place; a shell keeps whatever `shell-init` defined when it
started. Upgrade while a terminal is open and that terminal is left holding the old
functions — which, if they predate the prompt, never set `$LSRECENT_CD_FILE`, so the
listing prints its numbers and simply ends. Nothing is broken and nothing is wrong on
screen, which is what makes it worth an explicit message.

`shell-init` therefore exports `LSRECENT_SHELL` with its own version, and the binary
compares it. `source ~/.bashrc`, or open a new terminal, and it is gone. To ask
directly:

```
$ lsrecent --version
lsrecent 1.5.1 (shell integration: 1.5.0 — stale, run `source ~/.bashrc`)
```

which also reports `loaded` or `not loaded in this shell`.

Re-sourcing into an old shell used to fail outright rather than merely lag. Up to
1.1.1 the grouped views were aliases; from 1.2.0 they are functions. An interactive
shell expands aliases before the parser sees `lsrepos()`, so with the 1.1.1 alias
still resident, `source ~/.bashrc` died on

```
bash: eval: line NNN: syntax error near unexpected token `('
bash: eval: line NNN: `lsrepos()     { __lsrecent_list repos "$@"; }'
```

and — the part that matters — `eval` abandons the rest of the string, so every
function after that line silently never got defined. Since 1.7.1 `shell-init`
begins by unaliasing the names it is about to define, so it can always land on top
of any earlier vintage. In a shell that predates 1.7.1, `unalias lsrepos lstoday`
first, or just open a new terminal.

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
  1 HVAC_Repair_0726   2 lsrecent
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
━━ 4 DAYS AGO ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 31 DSR-Holdings-Cloud   32 dsrholdings-accounting-plugin
 33 Israel-Cable-Sourcing   34 Hebrew-Tech-Vocab
… 219 more, numbered 35-253 · lsrepos --all to see them
```

**Cutting the listing does not cut the numbering.** Every repo in the ranking gets
a number whether or not it fit on the screen, which is why the footer gives the
range it elided: `35` at the prompt cds into the thirty-fifth repo even though you
never saw its name, and the path is echoed so you can see where you landed. `--all`
is for when you want to read the names, not a precondition for reaching them.

Truncation is sound because the groups run newest-first: cutting from the end
drops the buckets you are least likely to want, whole. Only the bucket at the
fold is cut part-way, and there the cut lands wherever the
[within-group order](#ordering-buckets-by-recency-names-inside-them) puts it —
by name, unless `--time`. Everything in that bucket is the same age anyway, and
nothing cut is unreachable: it is numbered, and the prompt searches and pages.
Once anything has been cut the remaining groups are only counted, never partially
shown — printing *OLDER* after eliding half of *PAST MONTH* would misrepresent
the recency order the whole view is built on.

The budget is the terminal height less three rows, so the listing, the footer and
your prompt all land on one screen. To change or defeat it:

```bash
n                          # at the prompt: next page, no re-run (p goes back)
a                          # at the prompt: the rest of the view, unpaged
lsrepos --all              # or -a: no limit
LSRECENT_MAX_ROWS=60 ls    # explicit budget; 0 means unlimited
lsrepos --all | less -R    # if you want a real pager
```

A **redirected or piped** listing is never truncated — `lsrecent | wc -l` sees all
255, the same way `ls` drops its columns when it is not talking to a terminal.

None of this is the only way past the fold, and usually not the best one: the
prompt itself pages with `n` and `p` and searches by name, so the elided repos are
reachable without re-running anything. See [the browser](#the-prompt-is-also-a-browser).

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

The same logic is what lets the ordinary `lsrepos` listing carry
[a bucket per day](#a-bucket-per-day-for-the-last-week): one timestamp per repo
means the days are mutually exclusive by construction, so no repo is ever printed
twice and the numbering can run straight down them.

Day boundaries are local midnights, computed with bash's own `printf '%(%H)T'`
rather than by forking `date`, since bare `ls` goes through this path. Each is
*snapped to* rather than reached by subtracting 86400, and the eight boundaries a
listing needs are walked one day at a time rather than multiplied out, so a week
containing a DST change still has seven days in it instead of drifting an hour
further out with each one. Verified against all 365 days of 2026 in eight zones —
23,360 boundaries, no mismatches — including 30-minute DST (Lord Howe) and the
southern hemisphere. `scripts/verify-day-boundaries.sh` is that check; re-run it
if you touch `snap_midnight` or `day_midnights`. Zones that transition *at*
midnight, such as America/Santiago, land within the hour twice a year; nothing
here cares.

## The picker

`lsrp` lists every repo newest-first in `fzf` and `cd`s into what you choose;
`lsrt` restricts the list to today's and `lsry` to yesterday's. The preview pane
shows the last 8 commits and `git status -sb`. All three are shell functions from
`shell-init`, because `cd` has to happen in your shell — `lsrecent pick` itself
just prints the chosen absolute path, so it composes with anything else.

The picker is for searching by name when you know what you are after. The numbered
prompt is for the far commoner case of picking off a short recency-ordered list, and
needs no dependency and no fuzzy-matching in your head.

Since the prompt [searches too](#the-prompt-is-also-a-browser), the two overlap more
than they used to, and reaching for `lsrp` is no longer the answer to "it wasn't on
the screen". What the picker still has is fuzzy matching, the commit/status preview
pane, and a scrolling result list you can arrow through — worth it when you are
hunting rather than returning. The prompt's search is a plain case-insensitive
substring, which is what you want when you already know the name.

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
| `lsrecent gui` | Manage the same list in a window |
| `lsrecent check [dir]` | Exit 0/1 depending on whether the override is enabled (for scripting) |
| `lsrecent shell-install` | Append the `eval` line to `~/.bashrc` (idempotent) |

Changes take effect at once — the include-list is consulted on every `ls`, so there is nothing to reload in shells that are already open.

### The window

```bash
lsrecent gui
```

Also in the application launcher as **lsrecent Directories**. A list of the opted-in directories, an *Add directory…* chooser, and *Remove* — that is the whole surface, because that is the whole of the mapping.

![lsrecent-gui](docs/screenshot-gui.png)

Two things it does that the CLI does not: entries whose directory has since been deleted or renamed are flagged `(missing)`, which is otherwise invisible — `ls` simply never triggers there and the include-list still looks right — and the status line quotes the binary's own reply, so *"already enabled for …"* reads the same in both places.

It is a front end and nothing more: rows come from `lsrecent list`, changes go out through `lsrecent add` / `lsrecent remove`, and the list is re-read after each. The file format, tilde expansion, `realpath` resolution and deduplication stay in the binary, since a second implementation in another language is how the two come to disagree. It needs `python3-pyqt6`; the CLI does not.

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

Because the wrapper's logic lives in the binary (`shell-init`, `check`), updating the binary updates the behavior everywhere — the repo/binary is the single source of truth, and your `.bashrc` never needs to change again. The one thing that does not update itself is the wrapper *already loaded* into a shell that is open at the time; it is replaced at the next `source ~/.bashrc`, and until then the binary says so rather than behaving oddly ([above](#if-the-numbers-appear-but-nothing-asks-for-one)).

## Design notes

- **Buckets:** *Today* and *Yesterday* are calendar days (not "last 24 h" / "24–48 h ago"), then ≤ 7 days, ≤ 30 days, ≤ 90 days, older. Empty buckets are omitted. Membership is decided by comparing against local midnight epochs, not by formatting each timestamp. One timestamp per entry means the buckets are mutually exclusive, which is what lets *Today* and *Yesterday* be answers rather than overlapping windows.
- **A listing is a question.** Anything that numbers its output should be willing to take a number back, so the prompt is the default rather than a flag: the alternative is a tool that shows you the answer and then makes you retype part of it. The non-interactive path still exists for pipes and scripts, where it is the only sensible behaviour — and it is chosen by detecting that situation, not by asking the user to declare it.
- **Forks are the entire performance story.** A fork costs ~7 ms here, and everything else this tool does is free by comparison. So there is exactly one rule: *no subprocess inside a per-entry loop.* Timestamps come from a single `find -printf`, not a `stat` per entry; the clock comes from bash's `printf '%(%s)T'`, not `date`; `check` compares the raw `$PWD` before paying for `realpath`; `COLUMNS` is passed in by the shell wrapper so the binary never forks `tput`. Measured on a 3000-entry directory: **27.9 s before, 0.15 s after.** The old code was linear in fork count, so it was fine on a 30-entry directory and unusable on a large one — if a change here makes a big directory feel slow again, count the forks first.
- **Recency source is mtime, except where it can't be.** Access time (atime) would literally mean "last opened", but on modern Linux `relatime`/`noatime` mounts make it unreliable, and merely listing or backing up a tree can touch it. Modification time is stable and, for project directories, tracks real activity — but it cannot express "I opened this", which is why repo-level views also consult the visit log.
- **Ordering within a bucket** is alphabetical, case-folded, on the displayed label (`--time` restores the older most-recent-first). The bucket already carries the recency; ranking its members against each other splits hairs the timestamps cannot really support and moves a name around between listings for reasons nothing on screen explains. Directory-level listings keep `ls -t` ordering, because there the bucket contents are files rather than repositories and `ls` owns that layout.
- **Directory-level layout is delegated to `ls`** (`ls -dtC --color=always`), so you get the exact column packing and file-type colors you're used to. Repo-level layout can't be: `ls` re-sorts its operands, and repos resolve from many different parents, so that view does its own column packing against the computed order. It fills **row-major**, unlike `ls -C` — once entries are numbered, column-major would run 1, 2, 3 down the page instead of across it.
- **`[[ -t 1 ]]` is always false inside `$(...)`** — stdout there is the pipe bash created to capture the substitution, not the terminal. A helper called as `budget=$(row_budget)` therefore cannot ask whether it is talking to a terminal; the answer is sampled once at the top level into `stdout_tty`. `tput lines` has the same problem from a different angle: it sizes the terminal from an ioctl on *its* stdout, so inside a substitution it reports terminfo's static default rather than the real height. Hence `LINES` from `shell-init`, falling back to `stty size < /dev/tty`.
- **A bash function returns the status of its last command**, which bit this tool hard: `collect_repos` ended with an `(( a > b ))` test, so whenever a recorded visit was merely *not newer* than the repo's mtime it returned 1, and every caller's `|| die "no git repositories under $root"` fired with 255 repos sitting in the array. Any function here whose result is "did it work" ends with an explicit `return 0`.
- **Headers** are full-width `━` rules with bold bright ANSI colors (green / cyan / yellow / magenta / gray), sized to the terminal width.
- **The tool speaks in orange.** The footer, the prompt, the help and every message the browser prints used to be ANSI 90 — "bright black" — which on a dark terminal is the ink a theme reserves for what you are meant to skim past. The line saying how to reach the 229 repositories that did not fit is the last line that should read as decoration. Orange (256-colour 214, falling back to plain yellow where `TERM`/`COLORTERM` do not claim 256 colours) is legible on a black or a white background and collides with nothing else on screen. Entry **numbers** stay grey: there, de-emphasis is the point — they sit beside the name they belong to and only have to be readable once you are looking for one.
- **The override lives in a shell function**, because changing what bare `ls` does mid-session requires shell-level logic — but the function is deliberately minimal and generated by the binary, so all real behavior stays in one place.

## License

MIT
