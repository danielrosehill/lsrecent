#!/usr/bin/env bash
# Install lsrecent: binary to ~/.local/bin, shell integration into ~/.bashrc.
set -e
cd "$(dirname "$0")"

mkdir -p ~/.local/bin
install -m 755 lsrecent ~/.local/bin/lsrecent

marker="# lsrecent shell integration"
if ! grep -qF "$marker" ~/.bashrc 2>/dev/null; then
    {
        echo ""
        echo "$marker"
        echo 'eval "$(lsrecent shell-init)"'
    } >> ~/.bashrc
    echo "Added shell integration to ~/.bashrc"
else
    echo "Shell integration already present — skipped"
fi

echo "Installed. Open a new terminal (or 'source ~/.bashrc'), then:"
echo "  lsrecent            # grouped view of the current directory"
echo "  lsrecent add        # make plain 'ls' use the grouped view here"
echo "  lsrecent list       # see where the override is enabled"
