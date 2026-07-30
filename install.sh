#!/usr/bin/env bash
# Install lsrecent: binary to ~/.local/bin, shell integration into ~/.bashrc.
set -e
cd "$(dirname "$0")"

mkdir -p ~/.local/bin
install -m 755 lsrecent ~/.local/bin/lsrecent

# Look for the eval itself, in every file bash might source it from — not just for
# our own marker comment in ~/.bashrc. Someone who put the line in ~/.bash_aliases
# by hand has the integration installed, and a second eval there is redundant
# clutter: everything shell-init defines is a redefinition, so the duplicate is
# harmless but has to be found and removed by hand later.
installed=""
for f in ~/.bashrc ~/.bash_aliases ~/.bash_profile ~/.profile; do
    [[ -f "$f" ]] || continue
    if grep -q 'lsrecent shell-init' "$f" 2>/dev/null; then installed="$f"; break; fi
done

if [[ -n "$installed" ]]; then
    echo "Shell integration already present in $installed — skipped"
else
    {
        echo ""
        echo "# lsrecent shell integration"
        echo 'eval "$(lsrecent shell-init)"'
    } >> ~/.bashrc
    echo "Added shell integration to ~/.bashrc"
fi

echo "Installed. Open a new terminal (or 'source ~/.bashrc'), then:"
echo "  lsrecent            # grouped view of the current directory"
echo "  lsrecent add        # make plain 'ls' use the grouped view here"
echo "  lsrecent list       # see where the override is enabled"
echo "  lstoday             # repos opened today; type a number to cd into one"
echo "  lsyesterday         # repos whose last visit was yesterday"
echo "  lsreg               # plain 'ls' where the grouped view is the default"
