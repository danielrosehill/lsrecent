#!/usr/bin/env bash
#
# Build a .deb for lsrecent. Two programs in one package: the bash binary, whose
# only non-Essential dependency is bash itself (coreutils, grep, sed and findutils
# are Essential, and Depends on those is a lintian error), and the PyQt6 window,
# which needs python3-pyqt6. The window is a Recommends rather than a Depends so the package
# is still installable on a headless box, where a Qt dependency chain would be
# absurd — apt installs Recommends by default, so a desktop install gets it
# without asking.
#
# The version comes from the binary itself; VERSION there is the single source of
# truth, and it is also what the shell integration exports for the staleness
# check, so a second copy in a packaging file could make the pair disagree.
#
# Note that the package deliberately does not touch anybody's ~/.bashrc: a root
# postinst editing user dotfiles is wrong on principle and cannot know which
# users want it. The user runs `lsrecent shell-install` once instead; postinst
# says so.
#
set -euo pipefail

# A group-writable umask (002, common on single-user Ubuntu) would otherwise put
# 0775 directories in the package, which dpkg-deb records verbatim.
umask 022

HERE="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(grep -oP '^VERSION="\K[^"]+' "${HERE}/lsrecent")"
ARCH="all"
PKG="lsrecent_${VERSION}_${ARCH}"
BUILD="${HERE}/build/${PKG}"

echo ">> Building lsrecent ${VERSION}"
rm -rf "${HERE}/build"
mkdir -p "${BUILD}/DEBIAN" \
         "${BUILD}/usr/bin" \
         "${BUILD}/usr/share/applications" \
         "${BUILD}/usr/share/doc/lsrecent"

install -m 755 "${HERE}/lsrecent"     "${BUILD}/usr/bin/lsrecent"
install -m 755 "${HERE}/lsrecent-gui" "${BUILD}/usr/bin/lsrecent-gui"
install -m 644 "${HERE}/packaging/lsrecent.desktop" \
               "${BUILD}/usr/share/applications/lsrecent.desktop"
install -m 644 "${HERE}/README.md" "${BUILD}/usr/share/doc/lsrecent/README.md"
install -m 644 "${HERE}/packaging/copyright" "${BUILD}/usr/share/doc/lsrecent/copyright"
gzip -9nc "${HERE}/packaging/changelog" \
    > "${BUILD}/usr/share/doc/lsrecent/changelog.gz"
chmod 644 "${BUILD}/usr/share/doc/lsrecent/changelog.gz"

# --- man pages, generated from `--help` ---
#
# The help text is itself generated, from the binary's header comment, so this is
# the third view of one source and cannot drift from the other two. Dumped inside
# .nf because the header is already laid out in columns that roff would otherwise
# reflow into paragraphs; the sed escapes a leading dot or apostrophe, which roff
# would read as a request rather than text.
mkdir -p "${BUILD}/usr/share/man/man1"
gen_man() {
    local name=$1 summary=$2 seealso=$3
    {
        printf '.TH %s 1 "%s" "lsrecent %s" "User Commands"\n' \
            "${name^^}" "$(date -u +%Y-%m-%d)" "${VERSION}"
        printf '.SH NAME\n%s \\- %s\n' "$name" "$summary"
        printf '.SH SYNOPSIS\n.B %s\n[\\fICOMMAND\\fR] [\\fIARGUMENTS\\fR]\n' "$name"
        printf '.SH DESCRIPTION\n.nf\n'
        "${HERE}/lsrecent" --help | sed -e 's/\\/\\\\/g' -e "s/^[.']/\\\\&&/"
        printf '.fi\n.SH SEE ALSO\n.BR %s (1)\n' "$seealso"
        printf '.SH AUTHOR\nDaniel Rosehill <daniel@danielrosehill.co.il>\n'
    } | gzip -9nc > "${BUILD}/usr/share/man/man1/${name}.1.gz"
    chmod 644 "${BUILD}/usr/share/man/man1/${name}.1.gz"
}
gen_man lsrecent \
    "recency-grouped ls, with cd-by-number for repositories" lsrecent-gui
gen_man lsrecent-gui \
    "choose which directories the lsrecent ls override applies in" lsrecent

cat > "${BUILD}/DEBIAN/control" <<EOF
Package: lsrecent
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: bash (>= 4.4)
Recommends: python3, python3-pyqt6
Suggests: fzf
Maintainer: Daniel Rosehill <daniel@danielrosehill.co.il>
Homepage: https://github.com/danielrosehill/lsrecent
Description: Recency-grouped ls, with cd-by-number for repositories
 Replaces plain \`ls\` in directories you nominate with a listing grouped by how
 recently things were touched — today, this week, earlier — instead of one flat
 alphabetical block. In a directory of git repositories the entries are numbered
 in recency order and the listing ends by asking for a number, so choosing where
 to work is a listing and a keystroke rather than a path you have to remember.
 .
 Everywhere else \`ls\` is untouched, and piped or redirected output is unchanged,
 so scripts are unaffected.
 .
 Ships lsrecent-gui, a small window for choosing which directories the override
 applies in, also reachable as \`lsrecent gui\`.
EOF

# Rebuilding the desktop database is what makes the launcher entry appear without
# a logout. Both are absent on a server install, hence the guards.
cat > "${BUILD}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ]; then
    command -v update-desktop-database >/dev/null 2>&1 \
        && update-desktop-database -q /usr/share/applications || true
    cat <<'MSG'
>> lsrecent installed.

   Shell integration is per-user and is not added for you. Run once, as
   yourself:

       lsrecent shell-install     # appends the eval to ~/.bashrc

   then open a new terminal (or re-source ~/.bashrc).

   Then, in any directory where you want the grouped listing:

       lsrecent add               # or: lsrecent gui
MSG
fi
exit 0
EOF
chmod 755 "${BUILD}/DEBIAN/postinst"

cat > "${BUILD}/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = remove ]; then
    command -v update-desktop-database >/dev/null 2>&1 \
        && update-desktop-database -q /usr/share/applications || true
fi
exit 0
EOF
chmod 755 "${BUILD}/DEBIAN/postrm"

mkdir -p "${HERE}/dist"
dpkg-deb --root-owner-group --build "${BUILD}" "${HERE}/dist/${PKG}.deb"
echo ">> Built: dist/${PKG}.deb"
