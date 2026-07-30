#!/usr/bin/env python3
"""Regenerate docs/screenshot-gui.png from the real window. Run after any UI change:

    QT_QPA_PLATFORM=offscreen python3 scripts/screenshot.py

Renders offscreen and grabs the actual widget, so the README image cannot become a
picture of a version of the UI that no longer exists. Two details are deliberate:

  * Breeze is named explicitly. The offscreen platform inherits no icon theme, and
    this is a KDE app by default, so that is the closest thing to a real session.
  * A missing directory is added and its target removed, then taken out of the
    include-list again in a finally block. Flagging stale entries is one of the two
    things the window does that the CLI cannot show, so the screenshot should
    demonstrate it — but not at the cost of leaving junk in anyone's config.

The path is under /tmp rather than a scratch directory because it appears in the
image: a short, plausible name is the whole point of choosing it.
"""

import importlib.machinery
import importlib.util
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "docs", "screenshot-gui.png")
DEMO = "/tmp/Archived-Client-Work"

sys.argv = ["lsrecent-gui"]
loader = importlib.machinery.SourceFileLoader(
    "lsgui", os.path.join(REPO, "lsrecent-gui")
)
spec = importlib.util.spec_from_loader("lsgui", loader)
lsgui = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lsgui)

from PyQt6.QtGui import QIcon  # noqa: E402  (must follow the module load)
from PyQt6.QtWidgets import QApplication  # noqa: E402

app = QApplication(sys.argv)
QIcon.setThemeName("breeze")

os.makedirs(DEMO, exist_ok=True)
subprocess.run(["lsrecent", "add", DEMO], capture_output=True)
os.rmdir(DEMO)
try:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    w = lsgui.Window()
    w.resize(660, 300)
    w.show()
    app.processEvents()
    w.grab().save(OUT)
    print(f"wrote {OUT}")
finally:
    subprocess.run(["lsrecent", "remove", DEMO], capture_output=True)
    print(
        "include-list:",
        subprocess.run(
            ["lsrecent", "list"], capture_output=True, text=True
        ).stdout.strip(),
    )
