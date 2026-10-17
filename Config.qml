pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: cfg

    readonly property var defaults: ({
        theme: "catppuccin-mocha",
        style: "islands",
        position: "top",
        layer: "top",
        exclusiveZone: -1,
        tags: 9,
        pollMs: 1000,
        volumeStep: 5,
        clockFormat: "ddd dd  HH:mm",
        titleMaxChars: 45,
        font: {
            family: "IosevkaTerm Nerd Font Mono",
            fallback: ["Iosevka NF", "monospace"],
            size: 20, weight: "normal", italic: false, letterSpacing: 0
        },
        bar: {
            marginTop: 6, marginBottom: 0, marginLeft: 12, marginRight: 12,
            height: 0, paddingX: 0, paddingY: 0,
            moduleGap: 6, workspaceGap: 6,
            radius: 10, borderWidth: 1
        },
        island: { radius: 10, paddingX: 10, paddingY: 6, borderWidth: 1 },
        workspaces: { labels: [], count: 0, radius: 10, paddingX: 10, paddingY: 6 },
        layout: {
            left:   ["brand", "workspaces"],
            center: ["title"],
            right:  ["cpu", "memory", "network", "volume", "battery", "clock"]
        },
        tray: {
            enabled: true, iconSize: 18,
            paddingX: 8, paddingY: 4, gap: 4
        },
        media: {
            artSize: 28, bars: 12, barWidth: 2, barGap: 2,
            maxTitleLen: 40, visualizer: true, coverArt: true, enabled: true
        },
        colors: {},
        module: {},
        icons: {
            brand: "\ue732 Arch Btw",
            cpu: "\u{F2DB}", memory: "\u{EFC5}", network: "\u{F05A9}",
            volume: "\u{F028}", volumeMuted: "\u{F026}",
            battery: "\u{F0079}", clock: "\u{F017}"
        }
    })

    property var data: defaults
    property string configPath: ""
    property string lastError: ""

    function _toCamel(s) {
        return s.replace(/_([a-z])/g, function(_, c) { return c.toUpperCase(); });
    }

    function camelizeKeys(obj) {
        if (Array.isArray(obj)) return obj.map(camelizeKeys);
        if (obj !== null && typeof obj === "object") {
            var out = {};
            for (var k in obj) out[_toCamel(k)] = camelizeKeys(obj[k]);
            return out;
        }
        return obj;
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
            'for p in "$ROSEBAR_CONFIG" ' +
            '"${XDG_CONFIG_HOME:-$HOME/.config}/rosebar/config.toml" ' +
            '"${XDG_CONFIG_HOME:-$HOME/.config}/rosebar/config.json" ' +
            '"$HOME/.rosebar.toml" "$HOME/.rosebar.json" ' +
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
                    cfg.data = cfg.deepMerge(cfg.defaults, cfg.camelizeKeys(JSON.parse(text)));
                    cfg.lastError = "";
                } catch (e) {
                    cfg.lastError = String(e);
                    console.warn("[rosebar] config parse error:", e);
                }
            }
        }
    }

    property Timer reloadPoller: Timer {
        id: reloadPoller
        interval: 1500
        running: true
        repeat: true
        onTriggered: cfg.reloadConfig()
    }

    property FileView configWatcher: FileView {
        id: configWatcher
        path: cfg.configPath
        watchChanges: true
        onFileChanged: cfg.reloadConfig()
    }

    function reloadConfig() {
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

    onConfigPathChanged: reloadConfig()
}
