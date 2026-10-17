#!/usr/bin/env bash
# add-tray-module.sh — add a system tray module to the rosebar Quickshell config.
set -euo pipefail

T="${ROSEBAR_DIR:-$HOME/.config/quickshell/rosebar}"
C="${XDG_CONFIG_HOME:-$HOME/.config}/rosebar/config.toml"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }

[ -d "$T" ] || { warn "no such directory: $T"; exit 1; }

# ---------------------------------------------------------------------------
# 1. Create ModTray.qml
# ---------------------------------------------------------------------------
say "writing ModTray.qml"
cat > "$T/ModTray.qml" <<'QML'
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "."

Item {
    id: trayRoot

    // Read tray config from the [module.tray] block, with safe defaults.
    readonly property var mcfg: (Config.data.module || {})["tray"] || {}
    readonly property bool enabled:   mcfg.enabled   !== false
    readonly property int  iconSize:  typeof mcfg.iconSize === "number" ? mcfg.iconSize : 18
    readonly property int  padX:      typeof mcfg.paddingX === "number" ? mcfg.paddingX : 8
    readonly property int  padY:      typeof mcfg.paddingY === "number" ? mcfg.paddingY : 4
    readonly property int  gap:       typeof mcfg.gap      === "number" ? mcfg.gap      : 4

    visible: enabled && trayRepeater.count > 0
    implicitWidth:  row.implicitWidth
    implicitHeight: Theme.rowHeight

    // One pill per tray item, laid out in a row.
    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: trayRoot.gap

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Rectangle {
                id: pill
                required property SystemTrayItem modelData

                width:  trayRoot.iconSize + trayRoot.padX * 2
                height: Theme.rowHeight
                radius: Config.data.island.radius
                color:  hover.hovered ? Theme.border
                     : (Config.data.style === "bar" ? "transparent" : Theme.bg)
                border.width: Config.data.style === "bar" ? 0 : Config.data.island.borderWidth
                border.color: Theme.border

                HoverHandler { id: hover }

                // Icon — handles the `?path=` suffix that some SNI
                // implementations (e.g. nm-applet) append to the icon name.
                Image {
                    id: icon
                    anchors.centerIn: parent
                    width:  trayRoot.iconSize
                    height: trayRoot.iconSize
                    source: {
                        var raw = pill.modelData.icon || "";
                        if (raw.indexOf("?path=") !== -1) {
                            var parts = raw.split("?path=");
                            var name = parts[0];
                            var path = parts[1];
                            var file = name.slice(name.lastIndexOf("/") + 1);
                            return "file://" + path + "/" + file;
                        }
                        return raw;
                    }
                    sourceSize.width:  trayRoot.iconSize
                    sourceSize.height: trayRoot.iconSize
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    visible: status === Image.Ready
                }

                // Fallback glyph when the icon can't be loaded.
                Text {
                    anchors.centerIn: parent
                    text: "?"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: trayRoot.iconSize
                    visible: icon.status !== Image.Ready
                }

                // Tooltip with title / description.
                ToolTip {
                    visible: hover.hovered && (pill.modelData.title !== "" || pill.modelData.tooltipTitle !== "")
                    text: {
                        var t = pill.modelData.tooltipTitle || pill.modelData.title || "";
                        var d = pill.modelData.tooltipDescription || "";
                        return d ? (t + "\n" + d) : t;
                    }
                    delay: 400
                }

                // ---- interaction ----------------------------------------
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        var item = pill.modelData;
                        if (mouse.button === Qt.LeftButton) {
                            if (item.hasMenu && item.onlyMenu)
                                item.display(trayRoot, 0, trayRoot.height);
                            else
                                item.activate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            item.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (item.hasMenu)
                                item.display(trayRoot, 0, trayRoot.height);
                        }
                    }

                    onWheel: wheel => {
                        var item = pill.modelData;
                        item.scroll(wheel.angleDelta.y, false);
                    }
                }
            }
        }
    }
}
QML

# ---------------------------------------------------------------------------
# 2. Register ModTray in qmldir
# ---------------------------------------------------------------------------
say "registering ModTray in qmldir"
if ! grep -q '^ModTray ' "$T/qmldir"; then
  sed -i 's|^ModMedia  *1\.0 ModMedia\.qml|ModMedia      1.0 ModMedia.qml\nModTray       1.0 ModTray.qml|' "$T/qmldir"
fi

# ---------------------------------------------------------------------------
# 3. Patch Bar.qml — add trayComp and the pick() case
# ---------------------------------------------------------------------------
say "patching Bar.qml"
python3 - "$T/Bar.qml" <<'PY'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1])
src = p.read_text()
changed = False

# Add pick() case
if 'case "tray"' not in src:
    anchor = '            case "media":      return mediaComp;'
    if anchor in src:
        src = src.replace(
            anchor,
            anchor + '\n            case "tray":       return trayComp;',
            1)
        changed = True
        print("  pick(): added 'tray' case")

# Add Component
if 'id: trayComp' not in src:
    anchor = '    Component { id: mediaComp; ModMedia {} }'
    if anchor in src:
        src = src.replace(
            anchor,
            anchor + '\n    Component { id: trayComp; ModTray {} }',
            1)
        changed = True
        print("  components: added trayComp")

if changed:
    p.write_text(src)
else:
    print("  already patched or anchor not found")
PY

# ---------------------------------------------------------------------------
# 4. Patch Config.qml — add tray defaults
# ---------------------------------------------------------------------------
say "patching Config.qml"
python3 - "$T/Config.qml" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
src = p.read_text()
if 'tray:' not in src:
    anchor = '        media: {'
    if anchor in src:
        block = '''        tray: {
            enabled: true, iconSize: 18,
            paddingX: 8, paddingY: 4, gap: 4
        },
'''
        src = src.replace(anchor, block + anchor, 1)
        p.write_text(src)
        print("  added tray defaults")
    else:
        print("  WARNING: media: anchor not found; add tray defaults manually")
else:
    print("  already present")
PY

# ---------------------------------------------------------------------------
# 5. Patch config.toml — add tray to layout and a [module.tray] block
# ---------------------------------------------------------------------------
if [ -f "$C" ]; then
  say "patching config.toml"
  python3 - "$C" <<'PY'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1])
src = p.read_text()

# Add "tray" to the right-hand side of [layout] if not present
if '"tray"' not in src:
    # right = [ ... ] — append tray before the closing ]
    src = re.sub(
        r'(?m)^(\s*right\s*=\s*\[)([^\]]*)\]',
        lambda m: m.group(1) + m.group(2).rstrip().rstrip(',') + (', ' if m.group(2).strip() else '') + '"tray"]',
        src, count=1)

# Add [module.tray] block if not present
if '[module.tray]' not in src:
    src += '''
[module.tray]
# enabled   = true    # set to false to hide the tray entirely
# iconSize  = 18
# paddingX  = 8
# paddingY  = 4
# gap       = 4
'''

p.write_text(src)
print("  patched")
PY
fi

say "Done."
echo
echo "Restart Quickshell:"
echo "  pkill -f 'qs -c rosebar'; sleep 1; qs -c rosebar &"