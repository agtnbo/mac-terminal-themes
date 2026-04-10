#!/usr/bin/env bash
set -e

REPO="agtnbo/mac-terminal-themes"
BRANCH="master"
THEMES=(Lavender Lemon Moss Rose Sky Slate Teal Wheat)
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

echo "Installing mac-terminal-themes..."

# Download all .terminal files to a temp directory
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for name in "${THEMES[@]}"; do
    curl -fsSL "${BASE_URL}/${name}.terminal" -o "${TMP}/${name}.terminal"
    echo "  Downloaded ${name}.terminal"
done

# Import all profiles into Terminal.app preferences via Python
python3 - "$TMP" "${THEMES[@]}" <<'PYEOF'
import sys, os, plistlib

tmp_dir = sys.argv[1]
themes = sys.argv[2:]
plist_path = os.path.expanduser("~/Library/Preferences/com.apple.Terminal.plist")

with open(plist_path, "rb") as f:
    prefs = plistlib.load(f)

prefs.setdefault("Window Settings", {})

for name in themes:
    path = os.path.join(tmp_dir, f"{name}.terminal")
    with open(path, "rb") as f:
        profile = plistlib.load(f)
    prefs["Window Settings"][name] = profile
    print(f"  Imported {name}")

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f, fmt=plistlib.FMT_BINARY)

print("Done.")
PYEOF

# Flush preferences cache
killall cfprefsd 2>/dev/null || true

echo ""
echo "All ${#THEMES[@]} themes installed."
echo "Reopen Terminal.app to apply: Preferences → Profiles → select a theme."
