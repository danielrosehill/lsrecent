#!/usr/bin/env bash
# Install lsrecent from the source tree into ~/.local — no root, no packaging.
# For a system-wide install, build the .deb instead: ./build-deb.sh
set -e
cd "$(dirname "$0")"

mkdir -p ~/.local/bin ~/.local/share/applications
install -m 755 lsrecent ~/.local/bin/lsrecent
install -m 755 lsrecent-gui ~/.local/bin/lsrecent-gui
install -m 644 packaging/lsrecent.desktop ~/.local/share/applications/lsrecent.desktop
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database -q ~/.local/share/applications || true

# The binary owns this logic (`shell-install`), so the .deb, which has no
# install.sh to call, and this script cannot drift apart. Run through the freshly
# installed copy rather than ./lsrecent: an older one on PATH would be the thing
# actually executed afterwards, and that is worth finding out now.
~/.local/bin/lsrecent shell-install

echo
echo "Installed. Open a new terminal (or 'source ~/.bashrc'), then:"
echo "  lsrecent            # grouped view of the current directory"
echo "  lsrecent add        # make plain 'ls' use the grouped view here"
echo "  lsrecent list       # see where the override is enabled"
echo "  lsrecent gui        # add/remove those directories in a window"
echo "  lstoday             # repos opened today; type a number to cd into one"
echo "  lsyesterday         # repos whose last visit was yesterday"
echo "  lsreg               # plain 'ls' where the grouped view is the default"
