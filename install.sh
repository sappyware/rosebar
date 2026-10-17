
#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="rosebar"
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$CONFIG_HOME/quickshell/$APP_NAME"

if [[ ! -f "$SOURCE_DIR/shell.qml" || ! -f "$SOURCE_DIR/qmldir" ]]; then
    echo "error: shell.qml or qmldir is missing."
    exit 1
fi

if ! command -v qs >/dev/null 2>&1; then
    echo "error: quickshell is not installed."
    exit 1
fi

if [[ "$(realpath "$SOURCE_DIR")" == "$(realpath -m "$TARGET_DIR")" ]]; then
    echo "rosebar is already installed in this directory."
    exit 0
fi

mkdir -p "$TARGET_DIR"

BACKUP_DIR=""

for file in "$SOURCE_DIR"/*.qml "$SOURCE_DIR/qmldir"; do
    [[ -f "$file" ]] || continue
    name="$(basename "$file")"

    if [[ -f "$TARGET_DIR/$name" ]]; then
        if [[ -z "$BACKUP_DIR" ]]; then
            BACKUP_DIR="$TARGET_DIR.backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$BACKUP_DIR"
        fi

        cp -p "$TARGET_DIR/$name" "$BACKUP_DIR/"
    fi
done

cp -p "$SOURCE_DIR"/*.qml "$TARGET_DIR/"
cp -p "$SOURCE_DIR/qmldir" "$TARGET_DIR/"

echo "rosebar installed to $TARGET_DIR"

if [[ -n "$BACKUP_DIR" ]]; then
    echo "backup created at $BACKUP_DIR"
fi

echo
echo "launch with: qs -c rosebar"