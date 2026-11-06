import "."
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: md

    readonly property var cfg: Config.data.md3
    readonly property bool active: Config.data.design === "md3e"
    property bool systemDark: true
    property string wallKey: ""
    property string wallSeed: ""
    readonly property bool dark: cfg.mode === "dark" ? true : cfg.mode === "light" ? false : systemDark
    readonly property string seed: (cfg.source === "wallpaper" && wallSeed !== "") ? wallSeed : cfg.seed
    readonly property var roles: active ? scheme(seed, dark, cfg.variant, cfg.tint) : ({
    })
    property string pendingKey: ""
    property string pendingSeed: ""
    property Process wallProc
    property Timer confirmTimer
    property Timer wallTimer
    property Process schemeProc
    property Timer schemeTimer

    function _lin(c) {
        return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    }

    function _gam(c) {
        c = Math.max(0, Math.min(1, c));
        return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
    }

    function hexToLch(hex) {
        function f(t) {
            return t > 0.008856 ? Math.pow(t, 1 / 3) : (7.787 * t + 16 / 116);
        }

        if (!/^#?[0-9a-fA-F]{6}$/.test(hex || ""))
            hex = "#6750A4";

        var n = parseInt(hex.replace("#", ""), 16);
        var r = _lin(((n >> 16) & 255) / 255), g = _lin(((n >> 8) & 255) / 255), b = _lin((n & 255) / 255);
        var X = (0.412456 * r + 0.357576 * g + 0.180438 * b) / 0.95047;
        var Y = 0.212673 * r + 0.715152 * g + 0.072175 * b;
        var Z = (0.0193339 * r + 0.119192 * g + 0.950304 * b) / 1.08883;
        var fx = f(X), fy = f(Y), fz = f(Z);
        var a = 500 * (fx - fy), bb = 200 * (fy - fz);
        return {
            "L": 116 * fy - 16,
            "C": Math.sqrt(a * a + bb * bb),
            "h": Math.atan2(bb, a) * 180 / Math.PI
        };
    }

    function _rgbLin(L, C, h) {
        function fi(t) {
            var t3 = t * t * t;
            return t3 > 0.008856 ? t3 : (t - 16 / 116) / 7.787;
        }

        var hr = h * Math.PI / 180, a = C * Math.cos(hr), b = C * Math.sin(hr);
        var fy = (L + 16) / 116, fx = fy + a / 500, fz = fy - b / 200;
        var X = 0.95047 * fi(fx), Y = fi(fy), Z = 1.08883 * fi(fz);
        return [3.24045 * X - 1.53714 * Y - 0.498531 * Z, -0.969266 * X + 1.87601 * Y + 0.041556 * Z, 0.0556434 * X - 0.204026 * Y + 1.05723 * Z];
    }

    function _inGamut(v) {
        for (var i = 0; i < 3; i++) if (v[i] < -0.0005 || v[i] > 1.0005) {
            return false;
        }
        return true;
    }

    function tone(h, C, L) {
        if (L >= 100)
            return "#ffffff";

        if (L <= 0)
            return "#000000";

        var v = _rgbLin(L, C, h);
        if (!_inGamut(v)) {
            var lo = 0, hi = C;
            for (var i = 0; i < 22; i++) {
                var m = (lo + hi) / 2;
                if (_inGamut(_rgbLin(L, m, h)))
                    lo = m;
                else
                    hi = m;
            }
            v = _rgbLin(L, lo, h);
        }
        var n = (Math.round(_gam(v[0]) * 255) << 16) | (Math.round(_gam(v[1]) * 255) << 8) | Math.round(_gam(v[2]) * 255);
        return "#" + ("000000" + n.toString(16)).slice(-6);
    }

    function scheme(seedHex, dark, variant, tint) {
        function P(i) {
            return {
                "h": spec[i][0],
                "c": spec[i][1] * K * (i >= 3 ? tint : 1)
            };
        }

        function q(x, dk, lt) {
            return tone(x.h, x.c, dark ? dk : lt);
        }

        var s = hexToLch(seedHex), H = s.h, K = 1.3;
        if (tint === undefined || tint === null)
            tint = 1;

        var spec;
        switch (variant) {
        case "analogous":
            spec = [[H, 40], [H + 10, 24], [H - 25, 32], [H, 6], [H, 8]];
            break;
        case "vibrant":
            spec = [[H, 200], [H + 15, 24], [H + 60, 32], [H, 10], [H, 12]];
            break;
        case "expressive":
            spec = [[H + 240, 40], [H + 15, 24], [H + 120, 32], [H + 15, 8], [H + 15, 12]];
            break;
        case "neutral":
            spec = [[H, 12], [H, 8], [H + 60, 16], [H, 2], [H, 2]];
            break;
        case "monochrome":
            spec = [[H, 0], [H, 0], [H, 0], [H, 0], [H, 0]];
            break;
        default:
            spec = [[H, 36], [H, 16], [H + 60, 24], [H, 6], [H, 8]];
        }
        var p = P(0), sc = P(1), t = P(2), n = P(3), nv = P(4), e = {
            "h": 32,
            "c": 110
        };
        return {
            "primary": q(p, 80, 40),
            "onPrimary": q(p, 20, 100),
            "primaryContainer": q(p, 30, 90),
            "onPrimaryContainer": q(p, 90, 10),
            "secondary": q(sc, 80, 40),
            "onSecondary": q(sc, 20, 100),
            "secondaryContainer": q(sc, 30, 90),
            "onSecondaryContainer": q(sc, 90, 10),
            "tertiary": q(t, 80, 40),
            "onTertiary": q(t, 20, 100),
            "tertiaryContainer": q(t, 30, 90),
            "onTertiaryContainer": q(t, 90, 10),
            "error": q(e, 80, 40),
            "onError": q(e, 20, 100),
            "errorContainer": q(e, 30, 90),
            "onErrorContainer": q(e, 90, 10),
            "surface": q(n, 6, 98),
            "onSurface": q(n, 90, 10),
            "surfaceDim": q(n, 6, 87),
            "surfaceBright": q(n, 24, 98),
            "surfaceContainerLowest": q(n, 4, 100),
            "surfaceContainerLow": q(n, 10, 96),
            "surfaceContainer": q(n, 12, 94),
            "surfaceContainerHigh": q(n, 17, 92),
            "surfaceContainerHighest": q(n, 22, 90),
            "surfaceVariant": q(nv, 30, 90),
            "onSurfaceVariant": q(nv, 80, 30),
            "outline": q(nv, 60, 50),
            "outlineVariant": q(nv, 30, 80),
            "inverseSurface": q(n, 90, 20),
            "inverseOnSurface": q(n, 20, 95),
            "inversePrimary": q(p, 40, 80)
        };
    }

    wallProc: Process {
        id: wallProc

        command: ["python3", Quickshell.shellDir + "/wallpaper_seed.py", md.cfg.wallpaper || "", md.cfg.wallpaperCmd || "", md.wallKey]

        stdout: StdioCollector {
            onStreamFinished: {
                var l = text.split("\n");
                var key = (l[0] || "").trim(), s = (l[1] || "").trim();
                if (key === "" || key === md.wallKey) {
                    md.pendingKey = "";
                    return ;
                }
                if (s === "") {
                    md.wallKey = key;
                    return ;
                }
                if (key === md.pendingKey) {
                    console.log("rosebar: wallpaper seed " + s + " <- " + key);
                    md.wallKey = key;
                    md.wallSeed = s;
                    md.pendingKey = "";
                } else {
                    md.pendingKey = key;
                    md.pendingSeed = s;
                    confirmTimer.restart();
                }
            }
        }

    }

    confirmTimer: Timer {
        id: confirmTimer

        interval: 1500
        onTriggered: {
            if (!wallProc.running)
                wallProc.running = true;

        }
    }

    wallTimer: Timer {
        running: md.active && md.cfg.source === "wallpaper"
        repeat: md.cfg.wallpaperPollMs > 0
        interval: Math.max(50, md.cfg.wallpaperPollMs)
        triggeredOnStart: true
        onTriggered: {
            if (!wallProc.running)
                wallProc.running = true;

        }
    }

    schemeProc: Process {
        id: schemeProc

        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim();
                md.systemDark = (t === "" || t.indexOf("prefer-dark") >= 0);
            }
        }

    }

    schemeTimer: Timer {
        running: md.active && md.cfg.mode === "auto"
        repeat: true
        interval: 4000
        triggeredOnStart: true
        onTriggered: {
            if (!schemeProc.running)
                schemeProc.running = true;

        }
    }

}
