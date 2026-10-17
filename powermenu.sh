#!/usr/bin/env bash
# rose-powermenu.sh — install a Quickshell power menu styled like rosebar.
set -euo pipefail

TARGET="${POWERMENU_DIR:-$HOME/.config/quickshell/rose-powermenu}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rose-powermenu"
CONFIG="$CONFIG_DIR/config.toml"
FORCE=0
LAUNCH=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)    TARGET="$2"; shift 2 ;;
    --force)  FORCE=1; shift ;;
    --launch) LAUNCH=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: rose-powermenu.sh [options]
  --dir PATH    Install dir (default: ~/.config/quickshell/rose-powermenu)
  --force       Overwrite existing files
  --launch      Start it after install
EOF
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if [ -e "$TARGET" ] && [ "$FORCE" -eq 0 ] && [ -n "$(ls -A "$TARGET" 2>/dev/null || true)" ]; then
  read -rp "$TARGET is not empty. Overwrite? [y/N] " a
  [[ "$a" =~ ^[yY] ]] || { echo aborted; exit 1; }
fi

mkdir -p "$TARGET" "$CONFIG_DIR"
say "QML : $TARGET"
say "Conf: $CONFIG"

# ---------------------------------------------------------------- qmldir
cat > "$TARGET/qmldir" <<'EOF'
singleton Config  1.0 Config.qml
singleton Theme   1.0 Theme.qml

PowerMenu   1.0 PowerMenu.qml
PowerButton 1.0 PowerButton.qml
EOF

# ---------------------------------------------------------------- shell.qml
cat > "$TARGET/shell.qml" <<'EOF'
//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "."

ShellRoot {
    id: root

    // Global state the IPC handler flips.
    QtObject {
        id: state
        property bool opened: false
        property int  focusIndex: 0
    }

    // The actual menu window.
    PowerMenu {
        id: menu
        state: state
    }

    // IPC:  qs -c rose-powermenu ipc call power toggle
    IpcHandler {
        target: "power"

        function toggle(): void {
            state.opened = !state.opened;
            if (state.opened) state.focusIndex = 0;
        }
        function open(): void {
            state.opened = true;
            state.focusIndex = 0;
        }
        function close(): void {
            state.opened = false;
        }
    }
}
EOF

# ---------------------------------------------------------------- Config.qml
cat > "$TARGET/Config.qml" <<'EOF'
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: cfg

    readonly property var defaults: ({
        theme: "catppuccin-mocha",
        font: {
            family: "IosevkaTerm Nerd Font Mono",
            fallback: ["Symbols Nerd Font Mono", "monospace"],
            size: 22, weight: "normal", italic: false
        },
        layout: {
            buttons: ["lock", "logout", "suspend", "reboot", "shutdown"]
        },
        // Overlay + card
        overlay: {
            dim: 0.55,          // 0.0 → 1.0 opacity of the black backdrop
            radius: 16,
            paddingX: 24,
            paddingY: 20,
            gap: 14
        },
        // Each pill
        button: {
            width: 100,
            height: 110,
            radius: 14,
            iconSize: 36,
            labelSize: 13,
            paddingY: 14,
            confirmDangerous: true
        },
        // Every action is a shell command — swap for your tools.
        actions: {
            lock:     "swaylock -f",
            logout:   "mmsg dispatch quit",
            suspend:  "systemctl suspend",
            reboot:   "systemctl reboot",
            shutdown: "systemctl poweroff"
        },
        labels: {
            lock: "Lock", logout: "Logout", suspend: "Sleep",
            reboot: "Reboot", shutdown: "Off"
        },
        icons: {
            lock:     "\uf023",
            logout:   "\uf2f5",
            suspend:  "\uf186",
            reboot:   "\uf01e",
            shutdown: "\uf011"
        },
        colors: {},
        // Per-button accent overrides, e.g.
        // [button_colors.reboot] fg = "#fab387"
        button_colors: {}
    })

    property var data: defaults
    property string configPath: ""
    property string lastError: ""

    // snake_case → camelCase for TOML keys
    function _toCamel(s) {
        return s.replace(/_([a-z])/g, function(_, c) { return c.toUpperCase(); });
    }
    function camelizeKeys(o) {
        if (Array.isArray(o)) return o.map(camelizeKeys);
        if (o !== null && typeof o === "object") {
            var r = {};
            for (var k in o) r[_toCamel(k)] = camelizeKeys(o[k]);
            return r;
        }
        return o;
    }
    function deepMerge(base, over) {
        var out = {};
        for (var k in base) out[k] = base[k];
        for (var k in over) {
            var b = out[k], o = over[k];
            if (b && typeof b === "object" && !Array.isArray(b) &&
                o && typeof o === "object" && !Array.isArray(o))
                out[k] = deepMerge(b, o);
            else
                out[k] = o;
        }
        return out;
    }
    function get(path, fallback) {
        var parts = path.split("."), v = data;
        for (var i = 0; i < parts.length; i++) {
            if (v === undefined || v === null) return fallback;
            v = v[parts[i]];
        }
        return v === undefined ? fallback : v;
    }

    property Process finder: Process {
        id: finder
        running: true
        command: ["sh", "-c",
            'for p in "$ROSE_POWERMENU_CONFIG" ' +
            '"${XDG_CONFIG_HOME:-$HOME/.config}/rose-powermenu/config.toml" ' +
            '"${XDG_CONFIG_HOME:-$HOME/.config}/rose-powermenu/config.json" ' +
            '"$HOME/.rose-powermenu.toml" "$HOME/.rose-powermenu.json" ' +
            '"$0/config.toml" "$0/config.json"; do ' +
            '[ -n "$p" ] && [ -f "$p" ] && { printf "%s" "$p"; exit 0; }; done; exit 1',
            Quickshell.shellDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim();
                if (p) cfg.configPath = p;
            }
        }
    }

    property Process loader: Process {
        id: loader
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    cfg.data = cfg.deepMerge(cfg.defaults,
                                             cfg.camelizeKeys(JSON.parse(text)));
                    cfg.lastError = "";
                } catch (e) {
                    cfg.lastError = String(e);
                    console.warn("[powermenu] config error:", e);
                }
            }
        }
    }

    function reload() {
        if (!configPath) return;
        if (configPath.endsWith(".toml")) {
            loader.command = ["python3", "-c",
                "import tomllib,json,sys;print(json.dumps(tomllib.load(open(sys.argv[1],'rb'))))",
                configPath];
        } else {
            loader.command = ["cat", configPath];
        }
        loader.running = true;
    }

    property FileView watcher: FileView {
        path: cfg.configPath
        watchChanges: true
        onFileChanged: cfg.reload()
    }

    property Timer poller: Timer {
        interval: 1500; running: true; repeat: true
        onTriggered: cfg.reload()
    }

    onConfigPathChanged: reload()
}
EOF

# ---------------------------------------------------------------- Theme.qml
cat > "$TARGET/Theme.qml" <<'EOF'
pragma Singleton
import QtQuick
import "."

QtObject {
    readonly property var keys: ["bg","fg","border","muted","accent","accentFg",
                                 "urgent","cpu","memory","network","volume","battery"]

    readonly property var palettes: ({
        "catppuccin-mocha": ["#1e1e2e","#cdd6f4","#313244","#9399b2","#f5c2e7","#1e1e2e","#f38ba8","#a6e3a1","#f9e2af","#89dceb","#cba6f7","#fab387"],
        "catppuccin-latte": ["#eff1f5","#4c4f69","#ccd0da","#8c8fa1","#ea76cb","#eff1f5","#d20f39","#40a02b","#df8e1d","#04a5e5","#8839ef","#fe640b"],
        "nord":             ["#2e3440","#d8dee9","#3b4252","#7b88a1","#88c0d0","#2e3440","#bf616a","#a3be8c","#ebcb8b","#8fbcbb","#b48ead","#d08770"],
        "gruvbox":          ["#282828","#ebdbb2","#3c3836","#928374","#d79921","#282828","#cc241d","#b8bb26","#fabd2f","#83a598","#d3869b","#fe8019"],
        "tokyonight":       ["#1a1b26","#c0caf5","#292e42","#565f89","#7aa2f7","#1a1b26","#f7768e","#9ece6a","#e0af68","#7dcfff","#bb9af7","#ff9e64"],
        "rose-pine":        ["#191724","#e0def4","#26233a","#6e6a86","#ebbcba","#191724","#eb6f92","#9ccfd8","#f6c177","#31748f","#c4a7e7","#f6c177"],
        "dracula":          ["#282a36","#f8f8f2","#44475a","#6272a4","#bd93f9","#282a36","#ff5555","#50fa7b","#f1fa8c","#8be9fd","#ff79c6","#ffb86c"]
    })

    readonly property var raw: {
        var arr = palettes[Config.data.theme] || palettes["catppuccin-mocha"];
        var o = {};
        for (var i = 0; i < keys.length; i++) o[keys[i]] = arr[i];
        var uc = Config.data.colors || {};
        for (var k in uc) if (keys.indexOf(k) >= 0) o[k] = uc[k];
        return o;
    }

    readonly property color bg:       raw.bg
    readonly property color fg:       raw.fg
    readonly property color border:   raw.border
    readonly property color muted:    raw.muted
    readonly property color accent:   raw.accent
    readonly property color accentFg: raw.accentFg
    readonly property color urgent:   raw.urgent
    readonly property color danger:   raw.urgent

    readonly property string fontFamily: Config.data.font.family
    readonly property int  fontSize:     Config.data.font.size
    readonly property int  fontWeight: {
        var w = Config.data.font.weight;
        if (w === "bold") return Font.Bold;
        if (w === "normal") return Font.Normal;
        return parseInt(w) || Font.Normal;
    }
    readonly property bool fontItalic: Config.data.font.italic

    function buttonColor(name) {
        var bc = (Config.data.button_colors || {})[name];
        if (bc && bc.fg) return bc.fg;
        if (name === "shutdown") return danger;
        if (name === "reboot")   return danger;
        if (name === "lock")     return accent;
        return fg;
    }
}
EOF

# ---------------------------------------------------------------- PowerButton.qml
cat > "$TARGET/PowerButton.qml" <<'EOF'
import QtQuick
import "."

Rectangle {
    id: btn

    required property string actionKey       // e.g. "lock", "reboot"
    required property bool   focused
    signal activated()

    readonly property var b: Config.data.button

    width:  b.width
    height: b.height
    radius: b.radius

    color: hover.hovered ? Theme.border
         : focused        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
         :                  "transparent"
    border.width: focused ? 2 : 1
    border.color: focused ? Theme.accent : Theme.border

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.width { NumberAnimation { duration: 120 } }

    HoverHandler { id: hover }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Config.data.icons[btn.actionKey] || "?"
            color: Theme.buttonColor(btn.actionKey)
            font.family: Theme.fontFamily
            font.pixelSize: Config.data.button.iconSize
            font.weight: Font.Normal
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Config.data.labels[btn.actionKey] || btn.actionKey
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Config.data.button.labelSize
            font.weight: btn.focused ? Font.Bold : Theme.fontWeight
            font.italic: Theme.fontItalic
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: btn.activated()
    }
}
EOF

# ---------------------------------------------------------------- PowerMenu.qml
cat > "$TARGET/PowerMenu.qml" <<'EOF'
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    id: root

    required property var state

    readonly property var buttons: {
        var list = Config.data.layout.buttons || [];
        return list.filter(function(k) { return Config.data.actions[k] !== undefined; });
    }

    // ---- layer shell: full-screen overlay, grabs keyboard -----------------
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rose-powermenu"
    WlrLayershell.keyboardFocus: root.state.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
    exclusiveZone: 0
    color: "transparent"
    visible: root.state.opened

    // ---- dim backdrop ------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Config.data.overlay.dim)

        MouseArea {
            anchors.fill: parent
            onClicked: root.state.opened = false
        }
    }

    // ---- center card -------------------------------------------------------
    Rectangle {
        id: card
        anchors.centerIn: parent
        width:  row.implicitWidth  + Config.data.overlay.paddingX * 2
        height: row.implicitHeight + Config.data.overlay.paddingY * 2
        radius: Config.data.overlay.radius
        color:  Theme.bg
        border.width: 1
        border.color: Theme.border

        // Stop click-through from hitting the backdrop
        MouseArea { anchors.fill: parent }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Config.data.overlay.gap

            Repeater {
                model: root.buttons
                delegate: PowerButton {
                    required property int index
                    required property var modelData
                    actionKey: modelData
                    focused:   root.state.focusIndex === index
                    onActivated: root.runAction(modelData)
                }
            }
        }

        // ---- keyboard handling ------------------------------------------
        focus: true
        Keys.onEscapePressed: root.state.opened = false
        Keys.onLeftPressed: {
            var n = root.buttons.length;
            if (n > 0) root.state.focusIndex = (root.state.focusIndex - 1 + n) % n;
        }
        Keys.onRightPressed: {
            var n = root.buttons.length;
            if (n > 0) root.state.focusIndex = (root.state.focusIndex + 1) % n;
        }
        Keys.onReturnPressed: root.runAction(root.buttons[root.state.focusIndex])
        Keys.onEnterPressed:  root.runAction(root.buttons[root.state.focusIndex])
        Keys.onSpacePressed:  root.runAction(root.buttons[root.state.focusIndex])
    }

    // ---- action runner -----------------------------------------------------
    function runAction(key) {
        if (!key) return;
        var dangerous = (key === "reboot" || key === "shutdown" || key === "logout");
        if (Config.data.button.confirmDangerous && dangerous &&
            !root.confirmPending) {
            root.confirmPending = key;
            confirmTimer.restart();
            return;
        }
        var cmd = Config.data.actions[key];
        if (cmd) {
            console.log("[powermenu] running:", cmd);
            Quickshell.execDetached(["sh", "-c", cmd]);
        }
        root.state.opened = false;
        root.confirmPending = "";
    }

    property string confirmPending: ""

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: root.confirmPending = ""
    }
}
EOF

# ---------------------------------------------------------------- config.toml
if [ ! -f "$CONFIG" ] || [ "$FORCE" -eq 1 ]; then
cat > "$CONFIG" <<'EOF'
# rose-powermenu — config
theme = "catppuccin-mocha"   # same palette list as rosebar

[font]
family   = "IosevkaTerm Nerd Font Mono"
fallback = ["Symbols Nerd Font Mono", "monospace"]
size     = 22
weight   = "normal"
italic   = false

[layout]
buttons = ["lock", "logout", "suspend", "reboot", "shutdown"]

[overlay]
dim      = 0.55    # 0.0 → 1.0 backdrop opacity
radius   = 16
padding_x = 24
padding_y = 20
gap       = 14

[button]
width             = 100
height            = 110
radius            = 14
icon_size         = 36
label_size        = 13
confirm_dangerous = true   # two-step for logout / reboot / shutdown

# Change these to whatever tools you use.
[actions]
lock     = "swaylock -f"
logout   = "mmsg dispatch quit"
suspend  = "systemctl suspend"
reboot   = "systemctl reboot"
shutdown = "systemctl poweroff"

[labels]
lock     = "Lock"
logout   = "Logout"
suspend  = "Sleep"
reboot   = "Reboot"
shutdown = "Off"

[icons]
lock     = "\uf023"
logout   = "\uf2f5"
suspend  = "\uf186"
reboot   = "\uf01e"
shutdown = "\uf011"

[colors]
# accent = "#f5c2e7"

# Override individual button colors:
# [button_colors.shutdown]
# fg = "#f38ba8"
EOF
  say "wrote starter config: $CONFIG"
else
  say "config exists, leaving alone: $CONFIG"
fi

say "Done."
cat <<EOF

  QML    : $TARGET
  Config : $CONFIG

  Start (runs persistently, hidden until triggered):
    qs -c rose-powermenu &

  Trigger from a keybind:
    qs -c rose-powermenu ipc call power toggle

  In MangoWM, add a bind like:
    mmsg dispatch spawn, qs -c rose-powermenu ipc call power toggle
EOF

if [ "$LAUNCH" -eq 1 ]; then
  pkill -f "qs -c rose-powermenu" 2>/dev/null || true
  sleep 0.4
  exec qs -c rose-powermenu
fi