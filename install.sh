#!/usr/bin/env bash
# Install lsrecent: script to ~/.local/bin, config dir, and shell integration.
set -e
cd "$(dirname "$0")"

mkdir -p ~/.local/bin ~/.config/lsrecent
install -m 755 lsrecent ~/.local/bin/lsrecent

if [[ ! -f ~/.config/lsrecent/dirs ]]; then
    cat > ~/.config/lsrecent/dirs <<'EOF'
# Directories where plain `ls` (no arguments) shows the lsrecent grouped view.
# One absolute path per line; ~ is expanded. Manage with lsr-add / lsr-remove.
EOF
fi

marker="# lsrecent shell integration"
if ! grep -qF "$marker" ~/.bashrc 2>/dev/null && ! grep -qF "$marker" ~/.bash_aliases 2>/dev/null; then
    {
        echo ""
        echo "$marker"
        echo "source \"$(pwd)/shell-integration.sh\""
    } >> ~/.bashrc
    echo "Added shell integration to ~/.bashrc"
else
    echo "Shell integration already present — skipped"
fi

echo "Installed. Open a new terminal (or 'source ~/.bashrc'), then:"
echo "  lsr            # grouped view of the current directory"
echo "  lsr-add        # make plain 'ls' use the grouped view here"
